//
//  PairingProtocolCryptor.swift
//  ledger-wallet-ios
//
//  Created by Nicolas Bigot on 06/02/2015.
//  Copyright (c) 2015 Ledger. All rights reserved.
//

import Foundation

class PairingProtocolCryptor {
    
    let sessionKeyBytesLength = 16
    let pairingKeyBytesLength = 16
    let nonceBytesLength = 8
    let challengeBytesLength = 4
    
    // MARK: - Session key
    
    func sessionKeyForKeys(internalKey: Crypto.Key, attestationKey: Crypto.Key) -> Crypto.Key {
        // compute shared secret
        let secretKey = Crypto.ECDH.performAgreement(internalKey: internalKey, peerKey: attestationKey)
        
        // compute secret key
        let sessionFirstPart = secretKey.symmetricKey.subdataWithRange(NSMakeRange(0, sessionKeyBytesLength))
        let sessionSecondPart = secretKey.symmetricKey.subdataWithRange(NSMakeRange(sessionKeyBytesLength, sessionKeyBytesLength))
        let sessionKey = Crypto.Hash.XORFromDataPair(sessionFirstPart, sessionSecondPart)
        return Crypto.Key(symmetricKey: sessionKey)
    }
    
    func decryptData(data: NSData, sessionKey: Crypto.Key) -> NSData {
        // decrypt data
        let (key1, key2) = splitSessionKey(sessionKey)
        return Crypto.Cipher.dataFromTripleDESCBC(data, key1: key1, key2: key2, key3: key1)
    }
    
    func encryptData(data: NSData, sessionKey: Crypto.Key) -> NSData {
        // encrypt data
        let (key1, key2) = splitSessionKey(sessionKey)
        return Crypto.Cipher.tripleDESCBCFromData(data, key1: key1, key2: key2, key3: key1)
    }
    
    func splitSessionKey(sessionKey: Crypto.Key) -> (Crypto.Key, Crypto.Key) {
        // split session key
        let (data1, data2) = Crypto.Data.splitDataInTwo(sessionKey.symmetricKey)
        let key1 = Crypto.Key(symmetricKey: data1)
        let key2 = Crypto.Key(symmetricKey: data2)
        return (key1, key2)
    }
    
    // MARK: - Challenge data
    
    func nonceFromBlob(data: NSData) -> NSData {
        return data.subdataWithRange(NSMakeRange(0, nonceBytesLength))
    }
    
    func encryptedDataFromBlob(data: NSData) -> NSData {
        return data.subdataWithRange(NSMakeRange(nonceBytesLength, data.length - nonceBytesLength))
    }
    
    func challengeDataFromDecryptedData(data: NSData) -> NSData {
        return data.subdataWithRange(NSMakeRange(0, challengeBytesLength))
    }
    
    func pairingKeyFromDecryptedData(data: NSData) -> Crypto.Key {
        return Crypto.Key(symmetricKey: data.subdataWithRange(NSMakeRange(challengeBytesLength, pairingKeyBytesLength)))
    }
    
    func encryptedChallengeResponseDataFromChallengeString(challenge: String, nonce: NSData, sessionKey: Crypto.Key) -> NSData {
        // create challenge data from response
        let decryptedData = NSMutableData()
        let challengeData = challengeDataFromChallengeString(challenge)
        
        // add nonce
        decryptedData.appendData(nonce)
        
        // add challenge data
        decryptedData.appendData(challengeData)
        
        // add 0x00 * 4
        decryptedData.appendData(Crypto.Encode.dataFromBase16String("00000000"))
        
        // encrypt data
        let encryptedData = encryptData(decryptedData, sessionKey: sessionKey)
        
        return encryptedData
    }
    
    func challengeStringFromChallengeData(data: NSData) -> String {
        var dataCopy = data.mutableCopy() as NSMutableData
        var pointer = UnsafeMutablePointer<UInt8>(dataCopy.mutableBytes)
        for i in 0..<data.length {
            pointer.memory = pointer.memory + 0x30 // add '0'
            pointer = pointer.successor()
        }
        return NSString(data: dataCopy, encoding: NSUTF8StringEncoding)!
    }
    
    func challengeDataFromChallengeString(challenge: String) -> NSData {
        let string = challenge as NSString
        var computedString = ""
        for i in 0..<string.length {
            computedString = computedString + "0" + string.substringWithRange(NSMakeRange(i, 1))
        }
        return Crypto.Encode.dataFromBase16String(computedString)
    }

}