import XCTest
@testable import LeanCloud

class LeanCloudTests: XCTestCase {
    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
        LeanCloud.initialize(
            applicationID:  "nq0awk3lh1dpmbkziz54377mryii8ny4xvp6njoygle5nlyg",
            applicationKey: "6vdnmdkdi4fva9i06lt50s4mcsfhppjpzm3zf5zjc9ty4pdz"
        )
        let object = LCObject()
        XCTAssertTrue(object.save().isSuccess)
        XCTAssertNotNil(object.objectId)
    }


    static var allTests : [(String, (LeanCloudTests) -> () throws -> Void)] {
        return [
            ("testExample", testExample),
        ]
    }
}
