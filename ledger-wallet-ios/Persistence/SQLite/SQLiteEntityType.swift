//
//  SQLiteTableEntity.swift
//  ledger-wallet-ios
//
//  Created by Nicolas Bigot on 30/11/2015.
//  Copyright © 2015 Ledger. All rights reserved.
//

import Foundation

protocol SQLiteEntityType {
    
    static var tableName: String { get }
    static var tableNameStatement: String { get }
    static var eponymTable: SQLiteTable { get }
    static var allFieldKeys: [String] { get }
    static var allFieldKeysStatement: String { get }
    static var allFieldKeypathsStatement: String { get }
    static var allRenamedFieldKeypathsStatement: String { get }
    static var allFieldValuesStatement: String { get }
    
    static func fieldKeypathWithKey(key: String) -> String
    static func fieldKeypathWithKeyStatement(key: String) -> String
    
}

extension SQLiteEntityType {
    
    static var eponymTable: SQLiteTable { return SQLiteTable(name: tableName) }
    
    static func fieldKeyStatement(key: String) -> String {
        return "\"\(key)\""
    }
    
    static func fieldKeypathWithKey(key: String) -> String {
        return "\(tableName).\(key)"
    }
    
    static func fieldKeypathWithKeyStatement(key: String) -> String {
        return "\"\(tableName)\".\"\(key)\""
    }
    
    static var allFieldKeysStatement: String {
        return allFieldKeys.map({ fieldKeyStatement($0) }).joinWithSeparator(", ")
    }
    
    static var allFieldKeypathsStatement: String {
        return allFieldKeys.map({ fieldKeypathWithKeyStatement($0) }).joinWithSeparator(", ")
    }
    
    static var allRenamedFieldKeypathsStatement: String {
        return allFieldKeys.map({ fieldKeypathWithKeyStatement($0) + " AS " + "\"\(fieldKeypathWithKey($0))\"" }).joinWithSeparator(", ")
    }
    
    static var tableNameStatement: String {
        return "\"\(tableName)\""
    }
    
    static var allFieldValuesStatement: String {
        return Array(count: allFieldKeys.count, repeatedValue: "?").joinWithSeparator(", ")
    }

}