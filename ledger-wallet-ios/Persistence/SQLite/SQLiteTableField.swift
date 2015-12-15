//
//  SQLiteTableField.swift
//  ledger-wallet-ios
//
//  Created by Nicolas Bigot on 30/11/2015.
//  Copyright © 2015 Ledger. All rights reserved.
//

import Foundation

enum SQLiteTableFieldType: String {
    
    case Integer = "INTEGER"
    case Text = "TEXT"
    case Real = "REAL"
    case Blob = "BLOB"
    case Null = "NULL"
    
}

final class SQLiteTableField {
    
    let name: String
    let type: SQLiteTableFieldType
    let notNull: Bool
    let unique: Bool
    let primaryKey: Bool
    let defaultValue: AnyObject?
    weak var table: SQLiteTable?
        
    // MARK: Initialization
    
    init(name: String, type: SQLiteTableFieldType, notNull: Bool, unique: Bool, defaultValue: AnyObject? = nil, primaryKey: Bool = false) {
        self.name = name
        self.type = type
        self.primaryKey = primaryKey
        self.notNull = notNull
        self.unique = unique
        self.defaultValue = defaultValue
    }

}

// MARK: - SQLiteRepresentable

extension SQLiteTableField: SQLiteRepresentable {
        
    var representativeStatement: String {
        var statement = "\"\(name)\" \(type.rawValue)"
        if primaryKey { statement = statement + " PRIMARY KEY AUTOINCREMENT" }
        if unique { statement = statement + " UNIQUE" }
        if notNull { statement = statement + " NOT NULL" }
        switch defaultValue {
        case is Int: statement = statement + " DEFAULT \(defaultValue as! Int)"
        case is String: statement = statement + " DEFAULT '\(defaultValue as! String)'"
        default: break
        }
        return statement
    }
    
}