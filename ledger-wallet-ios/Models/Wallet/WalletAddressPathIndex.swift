//
//  WalletAddressPathIndex.swift
//  ledger-wallet-ios
//
//  Created by Nicolas Bigot on 16/02/2016.
//  Copyright © 2016 Ledger. All rights reserved.
//

import Foundation

struct WalletAddressPathIndex {
    
    let index: Int
    let isHardened: Bool
    
    var derivationIndex: UInt32 {
        if isHardened {
            return UInt32(pow(2.0, 31.0)) + UInt32(index)
        }
        else {
            return UInt32(index)
        }
    }
    
    init?(index: Int, isHardened: Bool) {
        guard index >= 0 else { return nil }
        self.index = index
        self.isHardened = isHardened
    }
    
}

// MARK: - Equatable

extension WalletAddressPathIndex: Equatable { }

func ==(lhs: WalletAddressPathIndex, rhs: WalletAddressPathIndex) -> Bool {
    return lhs.index == rhs.index && lhs.isHardened == rhs.isHardened
}
