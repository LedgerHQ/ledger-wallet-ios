//
//  WalletLocalOperation.swift
//  ledger-wallet-ios
//
//  Created by Nicolas Bigot on 18/12/2015.
//  Copyright © 2015 Ledger. All rights reserved.
//

import Foundation

enum WalletOperationKind: String {
    case Send = "send"
    case Receive = "receive"
}

struct WalletLocalOperation {
    
    var uid: String { return "\(kind.rawValue)-\(transactionHash)-\(accountIndex)" }
    let accountIndex: Int
    let transactionHash: String
    let kind: WalletOperationKind
    let amount: Int64
    
    func increaseAmount(amount: Int64) -> WalletLocalOperation {
        return WalletLocalOperation(accountIndex: accountIndex, transactionHash: transactionHash, kind: kind, amount: self.amount + amount)
    }
    
    func decreaseAmount(amount: Int64) -> WalletLocalOperation {
        return WalletLocalOperation(accountIndex: accountIndex, transactionHash: transactionHash, kind: kind, amount: self.amount - amount)
    }
    
}