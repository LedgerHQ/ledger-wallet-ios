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

    let baseObject: [String: NSObject] = ["title": "Drones", "artist": "Muse", "year": 2015]
    let baseData = BTCDataFromHex("7b227469746c65223a2244726f6e6573222c2279656172223a323031352c22617274697374223a224d757365227d")
    
    func testSerialization() {
        let data = JSON.dataFromJSONObject(baseObject)
        XCTAssertEqual(data, baseData, "Data should be equal")
    }
    
    func testDeserialization() {
        let object = JSON.JSONObjectFromData(baseData) as! [String: NSObject]
        XCTAssertTrue(object == baseObject, "Objects should be equal")
    }
    
}