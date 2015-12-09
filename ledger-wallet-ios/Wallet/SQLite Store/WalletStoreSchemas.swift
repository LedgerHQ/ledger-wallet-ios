//
//  WalletStoreSchemas.swift
//  ledger-wallet-ios
//
//  Created by Nicolas Bigot on 01/12/2015.
//  Copyright © 2015 Ledger. All rights reserved.
//

import Foundation

final class WalletStoreSchemas {
    
    static var currentSchema: SQLiteSchema? {
        return schemaWithVersion(currentVersion)
    }
    
    static var currentVersion: Int {
        return 1
    }
    
    static func schemaWithVersion(version: Int) -> SQLiteSchema? {
        guard let schema = schemas[version] else {
            return nil
        }
        return schema()
    }
    
    private static let schemas: [Int: Void -> SQLiteSchema] = [
        1: WalletStoreSchemas.version1
    ]

    private class func version1() -> SQLiteSchema {
        // schema
        let schema = SQLiteSchema(version: 1)
        schema.addPragmaCommand(SQLitePragmaCommand(name: "journal_mode", value: "WAL"))
        schema.addPragmaCommand(SQLitePragmaCommand(name: "foreign_keys", value: "ON"))
        
        // tables
        let accountsTable = WalletAccountTableEntity.eponymTable
        accountsTable.addField(SQLiteTableField(name: WalletAccountTableEntity.indexKey, type: .Integer, notNull: true, unique: true))
        accountsTable.addField(SQLiteTableField(name: WalletAccountTableEntity.nameKey, type: .Text, notNull: false, unique: false))
        accountsTable.addField(SQLiteTableField(name: WalletAccountTableEntity.nextExternalIndexKey, type: .Integer, notNull: true, unique: false))
        accountsTable.addField(SQLiteTableField(name: WalletAccountTableEntity.nextInternalIndexKey, type: .Integer, notNull: true, unique: false))
        accountsTable.addField(SQLiteTableField(name: WalletAccountTableEntity.extendedPublicKeyKey, type: .Text, notNull: true, unique: true))
        schema.addTable(accountsTable)
        
        let operationsTable = WalletOperationTableEntity.eponymTable
        operationsTable.addField(SQLiteTableField(name: WalletOperationTableEntity.accountIndexKey, type: .Integer, notNull: true, unique: false))
        schema.addTable(operationsTable)
        
        let addressesTable = WalletAddressTableEntity.eponymTable
        addressesTable.addField(SQLiteTableField(name: WalletAddressTableEntity.addressKey, type: .Text, notNull: true, unique: true))
        addressesTable.addField(SQLiteTableField(name: WalletAddressTableEntity.chainIndexKey, type: .Integer, notNull: true, unique: false))
        addressesTable.addField(SQLiteTableField(name: WalletAddressTableEntity.keyIndexKey, type: .Integer, notNull: true, unique: false))
        addressesTable.addField(SQLiteTableField(name: WalletAddressTableEntity.accountIndexKey, type: .Integer, notNull: true, unique: false))
        schema.addTable(addressesTable)
        
        let metadataTable = WalletMetadataTableEntity.eponymTable
        metadataTable.addField(SQLiteTableField(name: WalletMetadataTableEntity.schemaVersionKey, type: .Integer, notNull: true, unique: true))
        metadataTable.addField(SQLiteTableField(name: WalletMetadataTableEntity.uniqueIdentifierKey, type: .Text, notNull: true, unique: true))
        schema.addTable(metadataTable)
        
        // foreign keys
        let operationAccountForeignKey = SQLiteForeignKey(
            parentField: accountsTable.fieldWithName(WalletAccountTableEntity.indexKey)!,
            childField: operationsTable.fieldWithName(WalletOperationTableEntity.accountIndexKey)!,
            updateAction: .Cascade, deleteAction: .Cascade)
        operationsTable.addForeignKey(operationAccountForeignKey)
        
        let addressAccountForeignKey = SQLiteForeignKey(
            parentField: accountsTable.fieldWithName(WalletAccountTableEntity.indexKey)!,
            childField: addressesTable.fieldWithName(WalletAddressTableEntity.accountIndexKey)!,
            updateAction: .Cascade, deleteAction: .Cascade)
        addressesTable.addForeignKey(addressAccountForeignKey)
        
        return schema
    }
    
}