//
//  SQLiteTable.swift
//  ledger-wallet-ios
//
//  Created by Nicolas Bigot on 30/11/2015.
//  Copyright © 2015 Ledger. All rights reserved.
//

import Foundation

final class SQLiteTable {
    
    let name: String
    weak var schema: SQLiteSchema?
    private(set) var fields: [SQLiteTableField] = []
    private(set) var foreignKeys: [SQLiteForeignKey] = []
    
    func addField(field: SQLiteTableField) {
        fields.append(field)
        field.table = self
    }
    
    func addForeignKey(foreignKey: SQLiteForeignKey) {
        foreignKeys.append(foreignKey)
    }
    
    func fieldWithName(name: String) -> SQLiteTableField? {
        return fields.filter({ $0.name == name }).first
    }
    
    // MARK: Initialization
    
    init(name: String) {
        self.name = name
    }
    
}

extension SQLiteTable: SQLiteRepresentable {
    
    // MARK: SQLite representation
    
    var representativeStatement: String {
        return "CREATE TABLE IF NOT EXISTS '\(name)' (\(fieldsStatement));"
    }
    
    private var fieldsStatement: String {
        var statement = ""
        
        for field in fields {
            if !statement.isEmpty { statement += ", " }
            statement += field.representativeStatement
        }
        for foreignKey in foreignKeys {
            if !statement.isEmpty { statement += ", " }
            statement += foreignKey.representativeStatement
        }
        return statement
    }
    
}