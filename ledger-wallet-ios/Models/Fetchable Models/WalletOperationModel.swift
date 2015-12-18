//
//  WalletOperationModel.swift
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

struct WalletOperationModel {
    
    var uid: String { return "\(kind.rawValue)-\(transactionHash)-\(accountIndex)" }
    let accountIndex: Int
    let transactionHash: String
    let kind: WalletOperationKind
    let amount: Int64
    
}

// MARK: - SQLiteFetchableModel

extension WalletOperationModel: SQLiteFetchableModel {
    
    init?(resultSet: SQLiteStoreResultSet) {
        guard let
            accountIndex = self.dynamicType.optionalIntegerForKey(WalletOperationTableEntity.accountIndexKey, resultSet: resultSet),
            transactionHash = self.dynamicType.optionalStringForKey(WalletOperationTableEntity.transactionHashKey, resultSet: resultSet),
            kind = self.dynamicType.optionalStringForKey(WalletOperationTableEntity.kindKey, resultSet: resultSet),
            amount = self.dynamicType.optionalInteger64ForKey(WalletOperationTableEntity.amountKey, resultSet: resultSet)
            else {
                return nil
        }
        
        guard let finalKind = WalletOperationKind(rawValue: kind) else {
            return nil
        }
        
        self.accountIndex = accountIndex
        self.transactionHash = transactionHash
        self.kind = finalKind
        self.amount = amount
    }
    
}