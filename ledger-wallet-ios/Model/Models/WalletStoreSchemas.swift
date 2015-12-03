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
        return schemaWithVersion(currentSchemaVersion)
    }
    
    static var currentSchemaVersion: Int {
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
        let accountsTable = AccountEntity.eponymTable
        accountsTable.addField(SQLiteTableField(name: AccountEntity.indexKey, type: .Integer, notNull: true, unique: true))
        accountsTable.addField(SQLiteTableField(name: AccountEntity.nameKey, type: .Text, notNull: false, unique: false))
        accountsTable.addField(SQLiteTableField(name: AccountEntity.nextExternalIndexKey, type: .Integer, notNull: true, unique: false, defaultValue: 0))
        accountsTable.addField(SQLiteTableField(name: AccountEntity.nextInternalIndexKey, type: .Integer, notNull: true, unique: false, defaultValue: 0))
        accountsTable.addField(SQLiteTableField(name: AccountEntity.extendedPublicKeyKey, type: .Text, notNull: false, unique: true))
        schema.addTable(accountsTable)
        
        let operationsTable = OperationEntity.eponymTable
        operationsTable.addField(SQLiteTableField(name: OperationEntity.accountIndexKey, type: .Integer, notNull: true, unique: false))
        schema.addTable(operationsTable)
        
        let addressesTable = AddressEntity.eponymTable
        addressesTable.addField(SQLiteTableField(name: AddressEntity.addressKey, type: .Text, notNull: true, unique: true))
        addressesTable.addField(SQLiteTableField(name: AddressEntity.chainIndexKey, type: .Integer, notNull: true, unique: false))
        addressesTable.addField(SQLiteTableField(name: AddressEntity.keyIndexKey, type: .Integer, notNull: true, unique: false))
        addressesTable.addField(SQLiteTableField(name: AddressEntity.accountIndexKey, type: .Integer, notNull: true, unique: false))
        schema.addTable(addressesTable)
        
        let metadataTable = MetadataEntity.eponymTable
        metadataTable.addField(SQLiteTableField(name: MetadataEntity.schemaVersionKey, type: .Integer, notNull: true, unique: true))
        metadataTable.addField(SQLiteTableField(name: MetadataEntity.uniqueIdentifierKey, type: .Text, notNull: true, unique: true))
        schema.addTable(metadataTable)
        
        // foreign keys
        let operationAccountForeignKey = SQLiteForeignKey(
            parentField: accountsTable.fieldWithName(AccountEntity.indexKey)!,
            childField: operationsTable.fieldWithName(OperationEntity.accountIndexKey)!,
            updateAction: .Cascade, deleteAction: .Cascade)
        operationsTable.addForeignKey(operationAccountForeignKey)
        
        let addressAccountForeignKey = SQLiteForeignKey(
            parentField: accountsTable.fieldWithName(AccountEntity.indexKey)!,
            childField: addressesTable.fieldWithName(AddressEntity.accountIndexKey)!,
            updateAction: .Cascade, deleteAction: .Cascade)
        addressesTable.addForeignKey(addressAccountForeignKey)
        
        return schema
    }
    
}