//
//  SQLiteStorableEntity.swift
//  ledger-wallet-ios
//
//  Created by Nicolas Bigot on 30/11/2015.
//  Copyright © 2015 Ledger. All rights reserved.
//

import Foundation

protocol SQLiteStorableEntity {
    
    static var tableName: String { get }
    static var eponymTable: SQLiteTable { get }
    
}

extension SQLiteStorableEntity {
    
    static var eponymTable: SQLiteTable {
        return SQLiteTable(name: tableName)
    }
    
}