//
//  JSONTests.swift
//  ledger-wallet-ios
//
//  Created by Nicolas Bigot on 22/10/2015.
//  Copyright © 2015 Ledger. All rights reserved.
//

import Foundation
import XCTest
@testable import ledger_wallet_ios

class JSONTests: XCTestCase {

    let baseObject: [String] = ["title", "artist", "year"]
    let baseData = BTCDataFromHex("5b227469746c65222c22617274697374222c2279656172225d")
    
    func testSerialization() {
        let data = JSON.dataFromJSONObject(baseObject)
        XCTAssertEqual(data, baseData, "Data should be equal")
    }
    
    func testDeserialization() {
        let object = JSON.JSONObjectFromData(baseData) as! [String]
        XCTAssertTrue(object == baseObject, "Objects should be equal")
    }
    
}