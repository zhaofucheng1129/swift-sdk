//
//  LCCloudTestCase.swift
//  LeanCloudTests
//
//  Created by zapcannon87 on 2019/7/4.
//  Copyright © 2019 LeanCloud. All rights reserved.
//

import XCTest
@testable import LeanCloud

class LCCloudTestCase: BaseTestCase {
    
    func testCloudRun() {
        XCTAssertEqual(LCCloud.run("test").value as? String, "test")
    }
    
    func testCloudRPC() {
        XCTAssertTrue(LCCloud.rpc("test").isSuccess)
    }

}
