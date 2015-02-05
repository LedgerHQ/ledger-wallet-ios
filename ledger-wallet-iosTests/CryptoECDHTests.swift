//
//  CryptoECDHTests.swift
//  ledger-wallet-ios
//
//  Created by Nicolas Bigot on 05/02/2015.
//  Copyright (c) 2015 Ledger. All rights reserved.
//

import Foundation
import XCTest

class CryptoECDHTests: XCTestCase {
    
    let privateKey = Crypto.Encode.dataFromBase16String("b208b83b23edfff327bb6e0098eeaa0a5c87a599d5d8b24ff2734d2aac8bbdde")
    let publicKey = Crypto.Encode.dataFromBase16String("04ae218d8080c7b9cd141b06f6b9f63ef3adf7aecdf49bb3916ac7f5d887fc4027bea6fd187b9fa810b6d251e1430f6555edd2d5b19828d51908917c03e3f7c436")
    let otherPrivateKey = Crypto.Encode.dataFromBase16String("2107cb67d49337fb9cf5e1585a308a72ba5aa17c6255010a01354f526b4e81cd")
    let otherPublicKey = Crypto.Encode.dataFromBase16String("040d1f94315fd489bbc233b75c69496d8f4aebcedfabb1937c312389750c9f096cd7a8bf42345800beeeb719bfb1c4b96ad57cd20aa22d33dfa59d3b4578aa9da2")
    
    let remotePublicKey = Crypto.Encode.dataFromBase16String("0478c0837ded209265ea8131283585f71c5bddf7ffafe04ccddb8fe10b3edc7833d6dee70c3b9040e1a1a01c5cc04fcbf9b4de612e688d09245ef5f9135413cc1d")
    let expectedSecret = Crypto.Encode.dataFromBase16String("ee0eb1f6dc57e36f95a3bc750d3b798c61c79870eefd7989dc27ec5f3f77d2ec")
    
    func testECDHAgreement() {
        let iKey1 = Crypto.Key(privateKey: privateKey)
        let pKey1 = Crypto.Key(publicKey: otherPublicKey)
        let iKey2 = Crypto.Key(privateKey: otherPrivateKey)
        let pKey2 = Crypto.Key(publicKey: publicKey)
        let secret1 = Crypto.ECDH.performAgreement(internalKey: iKey1, peerKey: pKey1).symmetricKey
        let secret2 = Crypto.ECDH.performAgreement(internalKey: iKey2, peerKey: pKey2).symmetricKey
        XCTAssertEqual(secret1.length, 32, "secret1 size should be 32")
        XCTAssertEqual(secret2.length, 32, "secret2 size should be 32")
        XCTAssertEqual(secret1, secret2, "secrets should be equal")
    }
    
    func testECDHRemoteAgreement() {
        let iKey = Crypto.Key(privateKey: privateKey)
        let pKey = Crypto.Key(publicKey: remotePublicKey)
        let secret = Crypto.ECDH.performAgreement(internalKey: iKey, peerKey: pKey).symmetricKey
        XCTAssertEqual(secret.length, 32, "secret1 size should be 32")
        XCTAssertEqual(secret, expectedSecret, "secrets aren't equal")
    }
    
}