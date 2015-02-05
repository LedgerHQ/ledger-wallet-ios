//
//  CryptoECDH.swift
//  ledger-wallet-ios
//
//  Created by Nicolas Bigot on 05/02/2015.
//  Copyright (c) 2015 Ledger. All rights reserved.
//

import Foundation

extension Crypto {
    
    class ECDH {
        
        class func performAgreement(ourKey: Crypto.Key, peerKey: Crypto.Key) -> Crypto.Key {
            let data = NSData()
            return Crypto.Key(symmetricKey: data)
        }
        
    }
    
}