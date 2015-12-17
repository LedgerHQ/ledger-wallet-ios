//
//  SQLiteStorableEntity.swift
//  ledger-wallet-ios
//
//  Created by Nicolas Bigot on 30/11/2015.
//  Copyright © 2015 Ledger. All rights reserved.
//

import Foundation

protocol SQLiteTableEntityType {
    
    static var tableName: String { get }
    static var eponymTable: SQLiteTable { get }
    
}

extension SQLiteTableEntityType {
    
    static var eponymTable: SQLiteTable { return SQLiteTable(name: tableName) }

}