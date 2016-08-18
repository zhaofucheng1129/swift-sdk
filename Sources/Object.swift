//
//  Object.swift
//  LeanCloud
//
//  Created by Tang Tianyong on 2/23/16.
//  Copyright © 2016 LeanCloud. All rights reserved.
//

import Foundation

/**
 LeanCloud object type.

 It's a compound type used to unite other types.
 It can be extended into subclass while adding some other properties to form a new type.
 Each object is correspond to a record in data storage.
 */
public class LCObject: NSObject, LCType, LCTypeExtension, Sequence {
    /// Access control lists.
    public dynamic var ACL: LCACL?

    /// Object identifier.
    public private(set) dynamic var objectId: LCString?

    public private(set) dynamic var createdAt: LCDate?
    public private(set) dynamic var updatedAt: LCDate?

    /**
     The table of all properties.
     */
    var propertyTable: LCDictionary = [:]

    var hasObjectId: Bool {
        return objectId != nil
    }

    var actualClassName: String {
        let className = self["className"] as? LCString
        return (className?.value) ?? self.dynamicType.objectClassName()
    }

    /// The temp in-memory object identifier.
    var internalId = Utility.uuid()

    /// Operation hub.
    /// Used to manage update operations.
    var operationHub: OperationHub!

    /// Whether object has data to upload or not.
    var hasDataToUpload: Bool {
        return hasObjectId ? (!operationHub.isEmpty) : true
    }

    public override required init() {
        super.init()
        operationHub = OperationHub(self)
    }

    public convenience init(objectId: String) {
        self.init()
        propertyTable["objectId"] = LCString(objectId)
    }

    public convenience init(className: String) {
        self.init()
        propertyTable["className"] = LCString(className)
    }

    public convenience init(className: String, objectId: String) {
        self.init()
        propertyTable["className"] = LCString(className)
        propertyTable["objectId"]  = LCString(objectId)
    }

    convenience init(dictionary: LCDictionary) {
        self.init()
        self.propertyTable = dictionary
    }

    public required init?(coder aDecoder: NSCoder) {
        propertyTable = (aDecoder.decodeObject(forKey: "propertyTable") as? LCDictionary) ?? [:]
    }

    public func encode(with aCoder: NSCoder) {
        aCoder.encode(propertyTable, forKey: "propertyTable")
    }

    public func copy(with zone: NSZone?) -> AnyObject {
        return self
    }

    public override func isEqual(_ another: AnyObject?) -> Bool {
        if another === self {
            return true
        } else if another?.objectId != nil && objectId != nil {
            return another?.objectId == objectId
        } else {
            return false
        }
    }

    public override func value(forKey key: String) -> AnyObject? {
        guard let value = get(key) else {
            return super.value(forKey: key)
        }

        return value
    }

    public func makeIterator() -> DictionaryIterator<String, LCType> {
        return propertyTable.makeIterator()
    }

    public var JSONValue: AnyObject {
        var result = propertyTable.JSONValue as! [String: AnyObject]

        result["__type"]    = "Object"
        result["className"] = actualClassName

        return result
    }

    public var JSONString: String {
        return ObjectProfiler.getJSONString(self)
    }

    var LCONValue: AnyObject? {
        guard let objectId = objectId else {
            return nil
        }

        return [
            "__type"    : "Pointer",
            "className" : actualClassName,
            "objectId"  : objectId.value
        ]
    }

    static func instance() -> LCType {
        return self.init()
    }

    func forEachChild(_ body: @noescape (child: LCType) -> Void) {
        propertyTable.forEachChild(body)
    }

    func add(_ other: LCType) throws -> LCType {
        throw LCError(code: .invalidType, reason: "Object cannot be added.")
    }

    func concatenate(_ other: LCType, unique: Bool) throws -> LCType {
        throw LCError(code: .invalidType, reason: "Object cannot be concatenated.")
    }

    func differ(_ other: LCType) throws -> LCType {
        throw LCError(code: .invalidType, reason: "Object cannot be differed.")
    }

    /**
     Set class name of current type.

     The default implementation returns the class name without root module.

     - returns: The class name of current type.
     */
    public class func objectClassName() -> String {
        let className = String(validatingUTF8: class_getName(self))!

        /* Strip root namespace to cope with application package name's change. */
        if let index = className.characters.index(of: ".") {
            return className.substring(from: className.index(after: index))
        } else {
            return className
        }
    }

    /**
     Register current object class manually.
     */
    public static func register() {
        ObjectProfiler.registerClass(self)
    }

    /**
     Load a property for key.

     If the property value for key is already existed and type is mismatched, it will throw an exception.

     - parameter key: The key to load.

     - returns: The property value.
     */
    func getProperty<Value: LCType>(_ key: String) -> Value? {
        let value = propertyTable[key]

        if let value = value {
            guard value is Value else {
                Exception.raise(.invalidType, reason: String(format: "No such a property with name \"%@\" and type \"%s\".", key, class_getName(Value.self)))
                return nil
            }
        }

        return value as? Value
    }

    /**
     Load a property for key.

     If the property value for key is not existed, it will initialize the property.
     If the property value for key is already existed and type is mismatched, it will throw an exception.

     - parameter key: The key to load.

     - returns: The property value.
     */
    func loadProperty<Value: LCType>(_ key: String) -> Value {
        if let value: Value = getProperty(key) {
            return value
        }

        let value = (Value.self as AnyClass).instance() as! Value
        propertyTable[key] = value

        return value
    }

    /**
     Update property with operation.

     - parameter operation: The operation used to update property.
     */
    func updateProperty(_ operation: Operation) {
        let key   = operation.key
        let name  = operation.name
        let value = operation.value

        self.willChangeValue(forKey: key)

        switch name {
        case .set:
            propertyTable[key] = value
        case .delete:
            propertyTable[key] = nil
        case .increment:
            let amount   = (value as! LCNumber).value
            let property = loadProperty(key) as LCNumber

            property.addInPlace(amount)
        case .add:
            let elements = (value as! LCArray).value
            let property = loadProperty(key) as LCArray

            property.concatenateInPlace(elements, unique: false)
        case .addUnique:
            let elements = (value as! LCArray).value
            let property = loadProperty(key) as LCArray

            property.concatenateInPlace(elements, unique: true)
        case .remove:
            let elements = (value as! LCArray).value
            let property = getProperty(key) as LCArray?

            property?.differInPlace(elements)
        case .addRelation:
            let elements = (value as! LCArray).value as! [LCRelation.Element]
            let relation = loadProperty(key) as LCRelation

            relation.appendElements(elements)
        case .removeRelation:
            let relation: LCRelation? = getProperty(key)
            let elements = (value as! LCArray).value as! [LCRelation.Element]

            relation?.removeElements(elements)
        }

        self.didChangeValue(forKey: key)
    }

    /**
     Add an operation.

     - parameter name:  The operation name.
     - parameter key:   The operation key.
     - parameter value: The operation value.
     */
    func addOperation(_ name: Operation.Name, _ key: String, _ value: LCType? = nil) {
        let operation = Operation(name: name, key: key, value: value)

        updateProperty(operation)
        operationHub.reduce(operation)
    }

    /**
     Transform value for key.

     - parameter key:   The key for which the value should be transformed.
     - parameter value: The value to be transformed.

     - returns: The transformed value for key.
     */
    func transformValue(_ key: String, _ value: LCType?) -> LCType? {
        guard let value = value else {
            return nil
        }

        switch key {
        case "ACL":
            return LCACL(JSONValue: value.JSONValue)
        case "createdAt", "updatedAt":
            return LCDate(JSONValue: value.JSONValue)
        default:
            return value
        }
    }

    /**
     Update a property.

     - parameter key:   The property key to be updated.
     - parameter value: The property value.
     */
    func update(_ key: String, _ value: LCType?) {
        self.willChangeValue(forKey: key)
        propertyTable[key] = transformValue(key, value)
        self.didChangeValue(forKey: key)
    }

    /**
     Get and set value via subscript syntax.
     */
    public subscript(key: String) -> LCType? {
        get { return get(key) }
        set { set(key, value: newValue) }
    }

    /**
     Get value for key.

     - parameter key: The key for which to get the value.

     - returns: The value for key.
     */
    public func get(_ key: String) -> LCType? {
        return propertyTable[key]
    }

    /**
     Validate the column name of object.

     - parameter key: The key you want to validate.

     - throws: A MalformedData error if key is invalid.
     */
    func validateKey(_ key: String) throws {
        let options: NSString.CompareOptions = [
            .regularExpression,
            .caseInsensitive
        ]

        guard key.range(of: "^[a-z0-9][a-z0-9_]*$", options: options) != nil else {
            throw LCError(code: .malformedData, reason: "Key is not well-formatted.", userInfo: ["key": key])
        }
    }

    /**
     Set value for key.

     - parameter key:   The key for which to set the value.
     - parameter value: The new value.
     */
    public func set(_ key: String, value: LCType?) {
        try! validateKey(key)

        if let value = value {
            addOperation(.set, key, value)
        } else {
            addOperation(.delete, key)
        }
    }

    /**
     Set object for key.

     - parameter key:    The key for which to set the object.
     - parameter object: The new object.
     */
    public func set(_ key: String, object: AnyObject?) {
        if let object = object {
            set(key, value: try! ObjectProfiler.object(JSONValue: object))
        } else {
            set(key, value: nil)
        }
    }

    /**
     Unset value for key.

     - parameter key: The key for which to unset.
     */
    public func unset(_ key: String) {
        addOperation(.delete, key, nil)
    }

    /**
     Increase a number by amount.

     - parameter key:    The key of number which you want to increase.
     - parameter amount: The amount to increase.
     */
    public func increase(_ key: String, by: LCNumber) {
        addOperation(.increment, key, by)
    }

    /**
     Append an element into an array.

     - parameter key:     The key of array into which you want to append the element.
     - parameter element: The element to append.
     */
    public func append(_ key: String, element: LCType) {
        addOperation(.add, key, LCArray([element]))
    }

    /**
     Append one or more elements into an array.

     - parameter key:      The key of array into which you want to append the elements.
     - parameter elements: The array of elements to append.
     */
    public func append(_ key: String, elements: [LCType]) {
        addOperation(.add, key, LCArray(elements))
    }

    /**
     Append an element into an array with unique option.

     - parameter key:     The key of array into which you want to append the element.
     - parameter element: The element to append.
     - parameter unique:  Whether append element by unique or not.
                          If true, element will not be appended if it had already existed in array;
                          otherwise, element will always be appended.
     */
    public func append(_ key: String, element: LCType, unique: Bool) {
        addOperation(unique ? .addUnique : .add, key, LCArray([element]))
    }

    /**
     Append one or more elements into an array with unique option.

     - seealso: `append(key: String, element: LCType, unique: Bool)`

     - parameter key:      The key of array into which you want to append the element.
     - parameter elements: The array of elements to append.
     - parameter unique:   Whether append element by unique or not.
     */
    public func append(_ key: String, elements: [LCType], unique: Bool) {
        addOperation(unique ? .addUnique : .add, key, LCArray(elements))
    }

    /**
     Remove an element from an array.

     - parameter key:     The key of array from which you want to remove the element.
     - parameter element: The element to remove.
     */
    public func remove(_ key: String, element: LCType) {
        addOperation(.remove, key, LCArray([element]))
    }

    /**
     Remove one or more elements from an array.

     - parameter key:      The key of array from which you want to remove the element.
     - parameter elements: The array of elements to remove.
     */
    public func remove(_ key: String, elements: [LCType]) {
        addOperation(.remove, key, LCArray(elements))
    }

    /**
     Get relation object for key.

     - parameter key: The key where relationship based on.

     - returns: The relation for key.
     */
    public func relationForKey(_ key: String) -> LCRelation {
        return LCRelation(key: key, parent: self)
    }

    /**
     Insert an object into a relation.

     - parameter key:    The key of relation into which you want to insert the object.
     - parameter object: The object to insert.
     */
    public func insertRelation(_ key: String, object: LCObject) {
        addOperation(.addRelation, key, LCArray([object]))
    }

    /**
     Remove an object from a relation.

     - parameter key:    The key of relation from which you want to remove the object.
     - parameter object: The object to remove.
     */
    public func removeRelation(_ key: String, object: LCObject) {
        addOperation(.removeRelation, key, LCArray([object]))
    }

    /**
     Validate object before saving.

     Subclass can override this method to add custom validation logic.
     */
    func validateBeforeSaving() {
        /* Validate circular reference. */
        ObjectProfiler.validateCircularReference(self)
    }

    /**
     Reset operations, make object unmodified.
     */
    func resetOperation() {
        self.operationHub.reset()
    }

    /**
     Save object and its all descendant objects synchronously.

     - returns: The result of saving request.
     */
    public func save() -> LCBooleanResult {
        return LCBooleanResult(response: ObjectUpdater.save(self))
    }

    /**
     Delete a batch of objects in one request synchronously.

     - parameter objects: An array of objects to be deleted.

     - returns: The result of deletion request.
     */
    public static func delete(_ objects: [LCObject]) -> LCBooleanResult {
        return LCBooleanResult(response: ObjectUpdater.delete(objects))
    }

    /**
     Delete current object synchronously.

     - returns: The result of deletion request.
     */
    public func delete() -> LCBooleanResult {
        return LCBooleanResult(response: ObjectUpdater.delete(self))
    }

    /**
     Fetch a batch of objects in one request synchronously.

     - parameter objects: An array of objects to be fetched.

     - returns: The result of fetching request.
     */
    public static func fetch(_ objects: [LCObject]) -> LCBooleanResult {
        return LCBooleanResult(response: ObjectUpdater.fetch(objects))
    }

    /**
     Fetch object from server synchronously.

     - returns: The result of fetching request.
     */
    public func fetch() -> LCBooleanResult {
        return LCBooleanResult(response: ObjectUpdater.fetch(self))
    }
}
