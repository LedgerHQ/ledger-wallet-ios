//
//  SQLitePragmaCommand.swift
//  ledger-wallet-ios
//
//  Created by Nicolas Bigot on 30/11/2015.
//  Copyright © 2015 Ledger. All rights reserved.
//

import Foundation

final class SQLitePragmaCommand {
    
    let name: String
    let value: String
    
    // MARK: Initialization
    
    init(name: String, value: String) {
        self.name = name
        self.value = value
    }
    
}

extension SQLitePragmaCommand: SQLiteRepresentable {
    
    // MARK: SQLite representation
    
    var representativeStatement: String {
        return "PRAGMA \(name) = \(value);"
    }
    
}