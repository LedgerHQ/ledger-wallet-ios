//
//  CryptoHashTests.swift
//  ledger-wallet-ios
//
//  Created by Nicolas Bigot on 05/02/2015.
//  Copyright (c) 2015 Ledger. All rights reserved.
//

import Foundation
import XCTest

class CryptoHashTests: XCTestCase {
    
    func testSHA256() {
        let inputData = NSData(bytes: "hello there", length: 11)
        let expectedData = Crypto.Encode.dataFromBase16String("12998c017066eb0d2a70b94e6ed3192985855ce390f321bbdb832022888bd251")
        XCTAssertEqual(Crypto.Hash.SHA256FromData(inputData), expectedData, "SHA256 should be equal")
    }

    func testSHA512() {
        let inputData = NSData(bytes: "hello there", length: 11)
        let expectedData = Crypto.Encode.dataFromBase16String("b7e98c78c24fb4c2c7b175e90474b21eae0ccf1b5ea4708b4e0f2d2940004419edc7161c18a1e71b2565df099ba017bcaa67a248e2989b6268ce078b88f2e210")
        XCTAssertEqual(Crypto.Hash.SHA512FromData(inputData), expectedData, "SHA256 should be equal")
    }
    
    func testXORZero() {
        let firstData = NSData(bytes: "hello there", length: 11)
        let secondData = NSData(bytes: "hello there", length: 11)
        XCTAssertEqual(Crypto.Hash.XORFromDataPair(firstData, secondData), NSMutableData(length: 11)!, "XOR data should be 0")
    }
    
    func testXOREmpty() {
        let firstData = NSData(bytes: "hello there", length: 11)
        let secondData = NSData(bytes: "", length: 0)
        XCTAssertEqual(Crypto.Hash.XORFromDataPair(firstData, secondData), NSData(), "XOR data should be empty")
    }
    
    func testXORData() {
        let firstData = NSData(bytes: "hello there", length: 11)
        let secondData = NSData(bytes: "how are you", length: 11)
        let expectedData = Crypto.Encode.dataFromBase16String("000a1b4c0e5211481c1d10")
        XCTAssertEqual(Crypto.Hash.XORFromDataPair(firstData, secondData), expectedData, "XOR data should be equal")
    }

}