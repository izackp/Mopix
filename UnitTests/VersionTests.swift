//
//  VersionTests.swift
//  UnitTests
//
//  Created by Isaac Paul on 4/26/22.
//

import XCTest

class VersionTests: XCTestCase {

    func testExample() throws {
        let myVersion = try Version(255, 4095, 4095)
        XCTAssert(myVersion.debugDescription == "255.4095.4095")
        XCTAssert(myVersion.getMinor() == 4095)

        let myVersion2 = try Version(1, 1)
        XCTAssert(myVersion2.debugDescription == "1.1.0")
        XCTAssert(myVersion2.getMajor() == 1)
    }

}
