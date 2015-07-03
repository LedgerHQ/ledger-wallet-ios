//
//  CryptoECDH.swift
//  ledger-wallet-ios
//
//  Created by Nicolas Bigot on 05/02/2015.
//  Copyright (c) 2015 Ledger. All rights reserved.
//

import Foundation

extension Crypto {
    
    final class ECDH {
        
        class func performAgreement(#internalKey: Crypto.Key, peerKey: Crypto.Key) -> Crypto.Key {
            if (!internalKey.isAsymmetric || !internalKey.hasPrivateKey || !peerKey.isAsymmetric || !peerKey.hasPublicKey) {
                return Crypto.Key(symmetricKey: NSData())
            }
            
            let iKey = internalKey.openSSLKey()
            let pPKey = peerKey.openSSLPublicKey()
            let group = EC_KEY_get0_group(iKey)
            
            // compute secret size
            let secretSize = (EC_GROUP_get_degree(group) + 7) / 8
            
            // create secret
            let secret = NSMutableData(length: Int(secretSize))!
            
            // compute secret 
            ECDH_compute_key(UnsafeMutablePointer<Void>(secret.mutableBytes), Int(secretSize), pPKey, iKey, nil)
            
            // finalize
            return Crypto.Key(symmetricKey: secret)
        }
        
    }
    
}