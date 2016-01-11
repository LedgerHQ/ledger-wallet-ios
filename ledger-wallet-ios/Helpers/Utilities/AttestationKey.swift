//
//  AttestationKey.swift
//  ledger-wallet-ios
//
//  Created by Nicolas Bigot on 16/11/2015.
//  Copyright © 2015 Ledger. All rights reserved.
//

import Foundation

struct AttestationKey {
    
    let batchID: UInt32
    let derivationID: UInt32
    let publicKey: NSData
        
    // MARK: Initialization
    
    init(batchID: UInt32, derivationID: UInt32, publicKey: String) {
        self.batchID = batchID
        self.derivationID = derivationID
        self.publicKey = BTCDataFromHex(publicKey)
    }
    
}

// MARK: - Equatable

extension AttestationKey: Equatable { }

func ==(lhs: AttestationKey, rhs: AttestationKey) -> Bool {
    return lhs.batchID == rhs.batchID && lhs.derivationID == rhs.derivationID && lhs.publicKey.isEqualToData(rhs.publicKey)
}