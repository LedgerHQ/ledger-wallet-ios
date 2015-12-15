//
//  SQLiteForeignKey.swift
//  ledger-wallet-ios
//
//  Created by Nicolas Bigot on 30/11/2015.
//  Copyright © 2015 Ledger. All rights reserved.
//

import Foundation

enum SQLiteForeignKeyAction: String {
    
    case NoAction = "NO ACTION"
    case Restrict = "RESTRICT"
    case SetNull = "SET NULL"
    case setDefault = "SET DEFAULT"
    case Cascade = "CASCADE"
    
}

final class SQLiteForeignKey {
    
    let childField: SQLiteTableField
    let parentField: SQLiteTableField
    let updateAction: SQLiteForeignKeyAction
    let deleteAction: SQLiteForeignKeyAction
    
    // MARK: Initialization
    
    init(parentField: SQLiteTableField, childField: SQLiteTableField, updateAction: SQLiteForeignKeyAction = .NoAction, deleteAction: SQLiteForeignKeyAction = .NoAction) {
        self.parentField = parentField
        self.childField = childField
        self.updateAction = updateAction
        self.deleteAction = deleteAction
    }

}

// MARK: - SQLiteRepresentable

extension SQLiteForeignKey: SQLiteRepresentable {
    
    var representativeStatement: String {
        guard let table = parentField.table else { return "" }
        var statement = "FOREIGN KEY (\"\(childField.name)\") REFERENCES \"\(table.name)\"(\"\(parentField.name)\")"
        statement += " ON UPDATE \(updateAction.rawValue)"
        statement += " ON DELETE \(deleteAction.rawValue)"
        return statement
    }
    
}