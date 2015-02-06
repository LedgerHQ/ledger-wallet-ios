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
        let privateKey = Crypto.Encode.dataFromBase16String("dbd39adafe3a007706e61a17e0c56849146cfe95849afef7ede15a43a1984491")
        let attestationKey = Crypto.Encode.dataFromBase16String("04e69fd3c044865200e66f124b5ea237c918503931bee070edfcab79a00a25d6b5a09afbee902b4b763ecf1f9c25f82d6b0cf72bce3faf98523a1066948f1a395f")
        let cryptor = PairingProtocolCryptor()
        
        // test session key
        let sessionKey = cryptor.sessionKeyForKeys(Crypto.Key(privateKey: privateKey), attestationKey: Crypto.Key(publicKey: attestationKey))
        let expectedSessionKey = Crypto.Encode.dataFromBase16String("75b8ada16eb5f8ea253a1b793a04e03c")
        XCTAssertEqual(sessionKey.symmetricKey, expectedSessionKey, "session keys should be equal")
        
        // test nonce
        let challenge = Crypto.Encode.dataFromBase16String("f07cc439461ec133ab6996f17e5d2afa3de0a4639fdec1609978a1fd1648b6cc")
        let nonce = cryptor.nonceFromBlob(challenge)
        let expectedNonce = Crypto.Encode.dataFromBase16String("f07cc439461ec133")
        XCTAssertEqual(nonce, expectedNonce, "nonces should be equal")
        
        // test encrypted blob
        let encryptedData = cryptor.encryptedDataFromBlob(challenge)
        let expectedEncryptedData = Crypto.Encode.dataFromBase16String("ab6996f17e5d2afa3de0a4639fdec1609978a1fd1648b6cc")
        XCTAssertEqual(encryptedData, expectedEncryptedData, "encrypted data should be equal")
        
        // test decrypted blob
        let decryptedData = cryptor.decryptData(encryptedData, sessionKey: sessionKey)
        let expectedDecryptedData = Crypto.Encode.dataFromBase16String("3b313f0873a521e635b622506a67ea3dd8ec8c3d4ccddb8f")
        XCTAssertEqual(decryptedData, expectedDecryptedData, "decrypted data should be equal")
        
        // test challenge
        let challengeData = cryptor.challengeDataFromDecryptedData(decryptedData)
        let expectedchallengeData = Crypto.Encode.dataFromBase16String("3b313f08")
        XCTAssertEqual(challengeData, expectedchallengeData, "challenge data should be equal")
        
        // test pairing key
        let pairingKey = cryptor.pairingKeyFromDecryptedData(decryptedData)
        let expectedPairingKey = Crypto.Encode.dataFromBase16String("73a521e635b622506a67ea3dd8ec8c3d4ccddb8f")
        XCTAssertEqual(pairingKey.symmetricKey, expectedPairingKey, "pairing keys should be equal")
        
        // test challenge response
        let challengeResponseData = cryptor.encryptedChallengeResponseDataFromChallengeString("e9dc", nonce: nonce, sessionKey: sessionKey)
        let expectedChallengeResponseData = Crypto.Encode.dataFromBase16String("339d0c2221379963741fd9d33e5b7ba3")
        XCTAssertEqual(challengeResponseData, expectedChallengeResponseData, "challenge responses data should be equal")
    }
    
    func testPairingCrypto2() {
        let privateKey = Crypto.Encode.dataFromBase16String("dbd39adafe3a007706e61a17e0c56849146cfe95849afef7ede15a43a1984491")
        let attestationKey = Crypto.Encode.dataFromBase16String("04e69fd3c044865200e66f124b5ea237c918503931bee070edfcab79a00a25d6b5a09afbee902b4b763ecf1f9c25f82d6b0cf72bce3faf98523a1066948f1a395f")
        let cryptor = PairingProtocolCryptor()
        
        // test session key
        let sessionKey = cryptor.sessionKeyForKeys(Crypto.Key(privateKey: privateKey), attestationKey: Crypto.Key(publicKey: attestationKey))
        let expectedSessionKey = Crypto.Encode.dataFromBase16String("75b8ada16eb5f8ea253a1b793a04e03c")
        XCTAssertEqual(sessionKey.symmetricKey, expectedSessionKey, "session keys should be equal")
        
        // test nonce
        let challenge = Crypto.Encode.dataFromBase16String("ab5a56a93c1ea8647f8a6982869b2d8a914538525d716b0443248e1cc51c3976")
        let nonce = cryptor.nonceFromBlob(challenge)
        let expectedNonce = Crypto.Encode.dataFromBase16String("ab5a56a93c1ea864")
        XCTAssertEqual(nonce, expectedNonce, "nonces should be equal")
        
        // test encrypted blob
        let encryptedData = cryptor.encryptedDataFromBlob(challenge)
        let expectedEncryptedData = Crypto.Encode.dataFromBase16String("7f8a6982869b2d8a914538525d716b0443248e1cc51c3976")
        XCTAssertEqual(encryptedData, expectedEncryptedData, "encrypted data should be equal")
        
        // test decrypted blob
        let decryptedData = cryptor.decryptData(encryptedData, sessionKey: sessionKey)
        let expectedDecryptedData = Crypto.Encode.dataFromBase16String("164913146032d5032c905f39447bc3f28a043a994ccddb8f")
        XCTAssertEqual(decryptedData, expectedDecryptedData, "decrypted data should be equal")
        
        // test challenge
        let challengeData = cryptor.challengeDataFromDecryptedData(decryptedData)
        let expectedchallengeData = Crypto.Encode.dataFromBase16String("16491314")
        XCTAssertEqual(challengeData, expectedchallengeData, "challenge data should be equal")
        
        // test pairing key
        let pairingKey = cryptor.pairingKeyFromDecryptedData(decryptedData)
        let expectedPairingKey = Crypto.Encode.dataFromBase16String("6032d5032c905f39447bc3f28a043a994ccddb8f")
        XCTAssertEqual(pairingKey.symmetricKey, expectedPairingKey, "pairing keys should be equal")
        
        // test challenge response
        let challengeResponseData = cryptor.encryptedChallengeResponseDataFromChallengeString("2c05", nonce: nonce, sessionKey: sessionKey)
        let expectedChallengeResponseData = Crypto.Encode.dataFromBase16String("844f0cf804cc7a3b8ac235e0872a2779")
        XCTAssertEqual(challengeResponseData, expectedChallengeResponseData, "challenge responses data should be equal")
    }
    
}