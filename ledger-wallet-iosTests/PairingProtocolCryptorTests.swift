//
//  PairingProtocolCryptorTests.swift
//  ledger-wallet-ios
//
//  Created by Nicolas Bigot on 06/02/2015.
//  Copyright (c) 2015 Ledger. All rights reserved.
//

import Foundation
import XCTest

class PairingProtocolCryptorTests: XCTestCase {
    
    func testPairingCrypto1() {
        let privateKey = BTCDataFromHex("dbd39adafe3a007706e61a17e0c56849146cfe95849afef7ede15a43a1984491")!
        let attestationKey = BTCDataFromHex("04e69fd3c044865200e66f124b5ea237c918503931bee070edfcab79a00a25d6b5a09afbee902b4b763ecf1f9c25f82d6b0cf72bce3faf98523a1066948f1a395f")!
        let cryptor = PairingProtocolCryptor()
        
        // test session key
        let sessionKey = cryptor.sessionKeyForKeys(internalKey: BTCKey(privateKey: privateKey), attestationKey: BTCKey(publicKey: attestationKey))
        let expectedSessionKey = BTCDataFromHex("75b8ada16eb5f8ea253a1b793a04e03c")!
        XCTAssertEqual(sessionKey, expectedSessionKey, "session keys should be equal")
        
        // test nonce
        let challenge = BTCDataFromHex("f07cc439461ec133ab6996f17e5d2afa3de0a4639fdec1609978a1fd1648b6cc")!
        let nonce = cryptor.nonceFromBlob(challenge)
        let expectedNonce = BTCDataFromHex("f07cc439461ec133")!
        XCTAssertEqual(nonce, expectedNonce, "nonces should be equal")
        
        // test encrypted blob
        let encryptedData = cryptor.encryptedDataFromBlob(challenge)
        let expectedEncryptedData = BTCDataFromHex("ab6996f17e5d2afa3de0a4639fdec1609978a1fd1648b6cc")!
        XCTAssertEqual(encryptedData, expectedEncryptedData, "encrypted data should be equal")
        
        // test decrypted blob
        let decryptedData = cryptor.decryptData(encryptedData, sessionKey: sessionKey)
        let expectedDecryptedData = BTCDataFromHex("3b313f0873a521e635b622506a67ea3dd8ec8c3d4ccddb8f")!
        XCTAssertEqual(decryptedData, expectedDecryptedData, "decrypted data should be equal")
        
        // test challenge
        let challengeData = cryptor.challengeDataFromDecryptedData(decryptedData)
        let expectedchallengeData = BTCDataFromHex("3b313f08")!
        XCTAssertEqual(challengeData, expectedchallengeData, "challenge data should be equal")
        
        // test pairing key
        let pairingKey = cryptor.pairingKeyFromDecryptedData(decryptedData)
        let expectedPairingKey = BTCDataFromHex("73a521e635b622506a67ea3dd8ec8c3d")!
        XCTAssertEqual(pairingKey, expectedPairingKey, "pairing keys should be equal")
        
        // test challenge response
        let challengeResponseData = cryptor.encryptedChallengeResponseDataFromChallengeString("e9dc", nonce: nonce, sessionKey: sessionKey)
        let expectedChallengeResponseData = BTCDataFromHex("339d0c2221379963741fd9d33e5b7ba3")!
        XCTAssertEqual(challengeResponseData, expectedChallengeResponseData, "challenge responses data should be equal")
    }
    
    func testPairingCrypto2() {
        let privateKey = BTCDataFromHex("dbd39adafe3a007706e61a17e0c56849146cfe95849afef7ede15a43a1984491")!
        let attestationKey = BTCDataFromHex("04e69fd3c044865200e66f124b5ea237c918503931bee070edfcab79a00a25d6b5a09afbee902b4b763ecf1f9c25f82d6b0cf72bce3faf98523a1066948f1a395f")!
        let cryptor = PairingProtocolCryptor()
        
        // test session key
        let sessionKey = cryptor.sessionKeyForKeys(internalKey: BTCKey(privateKey: privateKey), attestationKey: BTCKey(publicKey: attestationKey))
        let expectedSessionKey = BTCDataFromHex("75b8ada16eb5f8ea253a1b793a04e03c")!
        XCTAssertEqual(sessionKey, expectedSessionKey, "session keys should be equal")
        
        // test nonce
        let challenge = BTCDataFromHex("ab5a56a93c1ea8647f8a6982869b2d8a914538525d716b0443248e1cc51c3976")!
        let nonce = cryptor.nonceFromBlob(challenge)
        let expectedNonce = BTCDataFromHex("ab5a56a93c1ea864")!
        XCTAssertEqual(nonce, expectedNonce, "nonces should be equal")
        
        // test encrypted blob
        let encryptedData = cryptor.encryptedDataFromBlob(challenge)
        let expectedEncryptedData = BTCDataFromHex("7f8a6982869b2d8a914538525d716b0443248e1cc51c3976")!
        XCTAssertEqual(encryptedData, expectedEncryptedData, "encrypted data should be equal")
        
        // test decrypted blob
        let decryptedData = cryptor.decryptData(encryptedData, sessionKey: sessionKey)
        let expectedDecryptedData = BTCDataFromHex("164913146032d5032c905f39447bc3f28a043a994ccddb8f")!
        XCTAssertEqual(decryptedData, expectedDecryptedData, "decrypted data should be equal")
        
        // test challenge
        let challengeData = cryptor.challengeDataFromDecryptedData(decryptedData)
        let expectedchallengeData = BTCDataFromHex("16491314")!
        XCTAssertEqual(challengeData, expectedchallengeData, "challenge data should be equal")
        
        // test pairing key
        let pairingKey = cryptor.pairingKeyFromDecryptedData(decryptedData)
        let expectedPairingKey = BTCDataFromHex("6032d5032c905f39447bc3f28a043a99")!
        XCTAssertEqual(pairingKey, expectedPairingKey, "pairing keys should be equal")
        
        // test challenge response
        let challengeResponseData = cryptor.encryptedChallengeResponseDataFromChallengeString("2c05", nonce: nonce, sessionKey: sessionKey)
        let expectedChallengeResponseData = BTCDataFromHex("844f0cf804cc7a3b8ac235e0872a2779")!
        XCTAssertEqual(challengeResponseData, expectedChallengeResponseData, "challenge responses data should be equal")
    }
    
}