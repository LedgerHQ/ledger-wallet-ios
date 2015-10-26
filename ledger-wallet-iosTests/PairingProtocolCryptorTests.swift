//
//  PairingProtocolCryptorTests.swift
//  ledger-wallet-ios
//
//  Created by Nicolas Bigot on 06/02/2015.
//  Copyright (c) 2015 Ledger. All rights reserved.
//

import Foundation
import XCTest
@testable import ledger_wallet_ios

class PairingProtocolCryptorTests: XCTestCase {
    
    let cryptor = PairingProtocolCryptor()
    let privateKey = BTCDataFromHex("dbd39adafe3a007706e61a17e0c56849146cfe95849afef7ede15a43a1984491")!
    let attestationKey = BTCDataFromHex("04e69fd3c044865200e66f124b5ea237c918503931bee070edfcab79a00a25d6b5a09afbee902b4b763ecf1f9c25f82d6b0cf72bce3faf98523a1066948f1a395f")!
    let challenge = BTCDataFromHex("f07cc439461ec133ab6996f17e5d2afa3de0a4639fdec1609978a1fd1648b6cc")!

    func testSessionKey() {
        let sessionKey = cryptor.sessionKeyForKeys(internalKey: BTCKey(privateKey: privateKey), externalKey: BTCKey(publicKey: attestationKey))
        let expectedSessionKey = BTCDataFromHex("75b8ada16eb5f8ea253a1b793a04e03c")!
        XCTAssertEqual(sessionKey, expectedSessionKey, "session keys should be equal")
    }
    
    func testNonce() {
        let nonce = cryptor.nonceFromBlob(challenge)
        let expectedNonce = BTCDataFromHex("f07cc439461ec133")!
        XCTAssertEqual(nonce, expectedNonce, "nonces should be equal")
    }
    
    func testEncryptedBlob() {
        let encryptedData = cryptor.encryptedDataFromBlob(challenge)
        let expectedEncryptedData = BTCDataFromHex("ab6996f17e5d2afa3de0a4639fdec1609978a1fd1648b6cc")!
        XCTAssertEqual(encryptedData, expectedEncryptedData, "encrypted data should be equal")
    }
    
    func testDecryptedBlob() {
        let sessionKey = cryptor.sessionKeyForKeys(internalKey: BTCKey(privateKey: privateKey), externalKey: BTCKey(publicKey: attestationKey))
        let encryptedData = cryptor.encryptedDataFromBlob(challenge)
        let decryptedData = cryptor.decryptData(encryptedData, sessionKey: sessionKey)
        let expectedDecryptedData = BTCDataFromHex("3b313f0873a521e635b622506a67ea3dd8ec8c3d4ccddb8f")!
        XCTAssertEqual(decryptedData, expectedDecryptedData, "decrypted data should be equal")
    }
    
    func testChallengeData() {
        let sessionKey = cryptor.sessionKeyForKeys(internalKey: BTCKey(privateKey: privateKey), externalKey: BTCKey(publicKey: attestationKey))
        let encryptedData = cryptor.encryptedDataFromBlob(challenge)
        let decryptedData = cryptor.decryptData(encryptedData, sessionKey: sessionKey)
        let challengeData = cryptor.challengeDataFromDecryptedData(decryptedData)
        let expectedchallengeData = BTCDataFromHex("3b313f08")!
        XCTAssertEqual(challengeData, expectedchallengeData, "challenge data should be equal")
    }
    
    func testChallengeString() {
        let sessionKey = cryptor.sessionKeyForKeys(internalKey: BTCKey(privateKey: privateKey), externalKey: BTCKey(publicKey: attestationKey))
        let encryptedData = cryptor.encryptedDataFromBlob(challenge)
        let decryptedData = cryptor.decryptData(encryptedData, sessionKey: sessionKey)
        let challengeData = cryptor.challengeDataFromDecryptedData(decryptedData)
        let challengeString = cryptor.challengeStringFromChallengeData(challengeData)
        XCTAssertEqual(challengeString, "kao8", "challenge strings should be equal")

    }
    
    func testPairingKey() {
        let sessionKey = cryptor.sessionKeyForKeys(internalKey: BTCKey(privateKey: privateKey), externalKey: BTCKey(publicKey: attestationKey))
        let encryptedData = cryptor.encryptedDataFromBlob(challenge)
        let decryptedData = cryptor.decryptData(encryptedData, sessionKey: sessionKey)
        let pairingKey = cryptor.pairingKeyFromDecryptedData(decryptedData)
        let expectedPairingKey = BTCDataFromHex("73a521e635b622506a67ea3dd8ec8c3d")!
        XCTAssertEqual(pairingKey, expectedPairingKey, "pairing keys should be equal")
    }
    
    func testChallengeResponse() {
        let nonce = cryptor.nonceFromBlob(challenge)
        let sessionKey = cryptor.sessionKeyForKeys(internalKey: BTCKey(privateKey: privateKey), externalKey: BTCKey(publicKey: attestationKey))
        let challengeResponseData = cryptor.encryptedChallengeResponseDataFromChallengeString("e9dc", nonce: nonce, sessionKey: sessionKey)
        let expectedChallengeResponseData = BTCDataFromHex("339d0c2221379963741fd9d33e5b7ba3")!
        XCTAssertEqual(challengeResponseData, expectedChallengeResponseData, "challenge responses data should be equal")
    }

}