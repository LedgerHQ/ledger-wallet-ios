//
//  WalletBlockEntity.swift
//  ledger-wallet-ios
//
//  Created by Nicolas Bigot on 12/01/2016.
//  Copyright © 2016 Ledger. All rights reserved.
//

import Foundation

struct WalletBlockEntity: SQLiteEntityType {
    
    static let tableName = "block"
    
    static let hashKey = "hash"
    static let heightKey = "height"
    static let timeKey = "time"
    
}