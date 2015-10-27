//
//  VarIntParserTests.swift
//  ledger-wallet-ios
//
//  Created by Nicolas Bigot on 26/10/2015.
//  Copyright © 2015 Ledger. All rights reserved.
//

import Foundation
import XCTest
@testable import ledger_wallet_ios

class VarIntParserTests: XCTestCase {
    
    func testEmptyData() {
        let parser = VarIntParser(data: NSData())
        XCTAssertEqual(parser.bytesCount, 0, "Bytes count should be equal")
        XCTAssertFalse(parser.valid, "Parser should not be valid")
        XCTAssertNil(parser.representativeBytes, "Bytes should be nil")
        XCTAssertNil(parser.unsignedInt64Value, "Value should be nil")
    }
    
    func testWrongData() {
        let parser = VarIntParser(data: BTCDataFromHex("ff"))
        XCTAssertEqual(parser.bytesCount, 9, "Bytes count should be equal")
        XCTAssertFalse(parser.valid, "Parser should not be valid")
        XCTAssertNil(parser.representativeBytes, "Bytes should be nil")
        XCTAssertNil(parser.unsignedInt64Value, "Value should be nil")
    }
    
    func testOneByteData() {
        let parser = VarIntParser(data: BTCDataFromHex("89"))
        XCTAssertEqual(parser.bytesCount, 1, "Bytes count should be equal")
        XCTAssertTrue(parser.valid, "Parser should be valid")
        XCTAssertEqual(parser.representativeBytes!, BTCDataFromHex("89"), "Bytes should be equal")
        XCTAssertEqual(parser.unsignedInt64Value!, 0x89, "Values should be equal")
    }
    
    func testThreeByteData() {
        let parser = VarIntParser(data: BTCDataFromHex("fd0302"))
        XCTAssertEqual(parser.bytesCount, 3, "Bytes count should be equal")
        XCTAssertTrue(parser.valid, "Parser should be valid")
        XCTAssertEqual(parser.representativeBytes!, BTCDataFromHex("fd0302"), "Bytes should be equal")
        XCTAssertEqual(parser.unsignedInt64Value!, 0x203, "Values should be equal")
    }
    
    func testFiveByteData() {
        let parser = VarIntParser(data: BTCDataFromHex("fe78563412"))
        XCTAssertEqual(parser.bytesCount, 5, "Bytes count should be equal")
        XCTAssertTrue(parser.valid, "Parser should be valid")
        XCTAssertEqual(parser.representativeBytes!, BTCDataFromHex("fe78563412"), "Bytes should be equal")
        XCTAssertEqual(parser.unsignedInt64Value!, 0x12345678, "Values should be equal")
    }
    
    func testNineByteData() {
        let parser = VarIntParser(data: BTCDataFromHex("ffffdebc9a78563412"))
        XCTAssertEqual(parser.bytesCount, 9, "Bytes count should be equal")
        XCTAssertTrue(parser.valid, "Parser should be valid")
        XCTAssertEqual(parser.representativeBytes!, BTCDataFromHex("ffffdebc9a78563412"), "Bytes should be equal")
        XCTAssertEqual(parser.unsignedInt64Value!, 0x123456789ABCDEFF, "Values should be equal")
    }
    
    func testTooMuchData() {
        let parser = VarIntParser(data: BTCDataFromHex("fd78563412"))
        XCTAssertEqual(parser.bytesCount, 3, "Bytes count should be equal")
        XCTAssertTrue(parser.valid, "Parser should be valid")
        XCTAssertEqual(parser.representativeBytes!, BTCDataFromHex("fd7856"), "Bytes should be equal")
        XCTAssertEqual(parser.unsignedInt64Value!, 0x5678, "Values should be equal")
    }
    
}