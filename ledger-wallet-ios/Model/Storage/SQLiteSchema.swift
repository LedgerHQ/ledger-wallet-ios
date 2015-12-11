//
//  SQLiteSchema.swift
//  ledger-wallet-ios
//
//  Created by Nicolas Bigot on 27/11/2015.
//  Copyright © 2015 Ledger. All rights reserved.
//

import Foundation

final class SQLiteSchema {
    
    let version: Int
    
    var executableStatements: [String] {
        return representativeStatement.componentsSeparatedByString(";").filter({ !$0.isEmpty })
    }
    
    var executablePragmaCommands: [String] {
        return pragmaCommands.map({ $0.representativeStatement.stringByReplacingOccurrencesOfString(";", withString: "") })
    }
    
    private(set) var pragmaCommands: [SQLitePragmaCommand] = []
    private(set) var tables: [SQLiteTable] = []

    func addTable(table: SQLiteTable) {
        tables.append(table)
        table.schema = self
    }
    
    func addPragmaCommand(command: SQLitePragmaCommand) {
        pragmaCommands.append(command)
    }

    // MARK: Initialization
    
    init(version: Int) {
        self.version = version
    }
    
}

// MARK: - SQLiteRepresentable

extension SQLiteSchema: SQLiteRepresentable {
    
    var representativeStatement: String {
        return tables.reduce("") { $0 + $1.representativeStatement }
    }
    
}