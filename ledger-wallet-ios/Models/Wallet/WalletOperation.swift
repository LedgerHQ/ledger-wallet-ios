//
//  WalletOperation.swift
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

struct WalletOperation {
    
    let uid: String
    let accountIndex: Int
    let transactionHash: String
    let kind: WalletOperationKind
    let amount: Int64
    
    func increaseAmount(amount: Int64) -> WalletOperation {
        return WalletOperation(uid: uid, accountIndex: accountIndex, transactionHash: transactionHash, kind: kind, amount: self.amount + amount)
    }
    
    func decreaseAmount(amount: Int64) -> WalletOperation {
        return WalletOperation(uid: uid, accountIndex: accountIndex, transactionHash: transactionHash, kind: kind, amount: self.amount - amount)
    }
    
}

// MARK: - SQLiteFetchableModel

extension WalletOperation: SQLiteFetchableModel {
    
    init?(resultSet: SQLiteStoreResultSet) {
        guard let
            uid = resultSet.stringForKey(WalletOperationEntity.fieldKeypathWithKey(WalletOperationEntity.uidKey)),
            accountIndex = resultSet.integerForKey(WalletOperationEntity.fieldKeypathWithKey(WalletOperationEntity.accountIndexKey)),
            transactionHash = resultSet.stringForKey(WalletOperationEntity.fieldKeypathWithKey(WalletOperationEntity.transactionHashKey)),
            rawKind = resultSet.stringForKey(WalletOperationEntity.fieldKeypathWithKey(WalletOperationEntity.kindKey)),
            amount = resultSet.integer64ForKey(WalletOperationEntity.fieldKeypathWithKey(WalletOperationEntity.amountKey))
        else {
            return nil
        }
        
        guard let kind = WalletOperationKind(rawValue: rawKind) else { return nil }

        self.uid = uid
        self.accountIndex = accountIndex
        self.transactionHash = transactionHash
        self.amount = amount
        self.kind = kind
    }
    
}