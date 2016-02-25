//
//  WalletUnspentTransactionOutput.swift
//  ledger-wallet-ios
//
//  Created by Nicolas Bigot on 25/02/2016.
//  Copyright © 2016 Ledger. All rights reserved.
//

import Foundation

struct WalletUnspentTransactionOutput {
    
    let output: WalletTransactionOutput
    let address: WalletAddress
    
}

// MARK: - SQLiteFetchableModel

extension WalletUnspentTransactionOutput: SQLiteFetchableModel {
    
    init?(resultSet: SQLiteStoreResultSet) {
        guard let
            output = WalletTransactionOutput(resultSet: resultSet),
            address = WalletAddress(resultSet: resultSet)
        else {
            return nil
        }
        
        self.output = output
        self.address = address
    }

}