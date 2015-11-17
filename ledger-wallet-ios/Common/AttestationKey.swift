//
//  AttestationKey.swift
//  ledger-wallet-ios
//
//  Created by Nicolas Bigot on 16/11/2015.
//  Copyright © 2015 Ledger. All rights reserved.
//

import Foundation

private let LedgerDeviceAttestationKeys = [
    AttestationKey(batchID: 0x00, derivationID: 0x01, publicKey: "04e69fd3c044865200e66f124b5ea237c918503931bee070edfcab79a00a25d6b5a09afbee902b4b763ecf1f9c25f82d6b0cf72bce3faf98523a1066948f1a395f"),     // beta
    AttestationKey(batchID: 0x01, derivationID: 0x01, publicKey: "04223314cdffec8740150afe46db3575fae840362b137316c0d222a071607d61b2fd40abb2652a7fea20e3bb3e64dc6d495d59823d143c53c4fe4059c5ff16e406"),     // production (pre 1.4.11)
    AttestationKey(batchID: 0x02, derivationID: 0x01, publicKey: "04c370d4013107a98dfef01d6db5bb3419deb9299535f0be47f05939a78b314a3c29b51fcaa9b3d46fa382c995456af50cd57fb017c0ce05e4a31864a79b8fbfd6")      // production (post 1.4.11)
]

struct AttestationKey {
    
    let batchID: UInt32
    let derivationID: UInt32
    let publicKey: NSData
    
    static func fetchFromIDs(batchID batchID: UInt32, derivationID: UInt32) -> AttestationKey? {
        for attestationKey in LedgerDeviceAttestationKeys {
            if attestationKey.batchID == batchID && attestationKey.derivationID == derivationID {
                return attestationKey
            }
        }
        return nil
    }
    
    // MARK: Initialization
    
    private init(batchID: UInt32, derivationID: UInt32, publicKey: String) {
        self.batchID = batchID
        self.derivationID = derivationID
        self.publicKey = BTCDataFromHex(publicKey)
    }
    
}

extension AttestationKey: Equatable { }

func ==(lhs: AttestationKey, rhs: AttestationKey) -> Bool {
    return lhs.batchID == rhs.batchID && lhs.derivationID == rhs.derivationID && lhs.publicKey.isEqualToData(rhs.publicKey)
}