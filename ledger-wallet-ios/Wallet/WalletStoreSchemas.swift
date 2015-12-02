//
//  WalletStoreSchemas.swift
//  ledger-wallet-ios
//
//  Created by Nicolas Bigot on 01/12/2015.
//  Copyright © 2015 Ledger. All rights reserved.
//

import Foundation

final class WalletStoreSchemas {
    
    class func version1() -> SQLiteSchema {
        // schema
        let schema = SQLiteSchema(version: 1)
        schema.addPragmaCommand(SQLitePragmaCommand(name: "journal_mode", value: "WAL"))
        schema.addPragmaCommand(SQLitePragmaCommand(name: "foreign_keys", value: "ON"))
        
        // tables
        let accountsTable = AccountEntity.eponymTable
        accountsTable.addField(SQLiteTableField(name: AccountEntity.identifierKey, type: .Integer, notNull: true, unique: true, primaryKey: true))
        accountsTable.addField(SQLiteTableField(name: AccountEntity.nameKey, type: .Text, notNull: false, unique: false))
        accountsTable.addField(SQLiteTableField(name: AccountEntity.indexKey, type: .Integer, notNull: true, unique: true))
        accountsTable.addField(SQLiteTableField(name: AccountEntity.nextExternalIndexKey, type: .Integer, notNull: true, unique: false, defaultValue: 0))
        accountsTable.addField(SQLiteTableField(name: AccountEntity.nextInternalIndexKey, type: .Integer, notNull: true, unique: false, defaultValue: 0))
        accountsTable.addField(SQLiteTableField(name: AccountEntity.extendedPublicKeyKey, type: .Text, notNull: false, unique: true))
        schema.addTable(accountsTable)
        
        let operationsTable = OperationEntity.eponymTable
        operationsTable.addField(SQLiteTableField(name: OperationEntity.identifierKey, type: .Integer, notNull: true, unique: true, primaryKey: true))
        operationsTable.addField(SQLiteTableField(name: OperationEntity.accountIdentifierKey, type: .Integer, notNull: true, unique: false))
        schema.addTable(operationsTable)
        
        let addressesTable = AddressEntity.eponymTable
        addressesTable.addField(SQLiteTableField(name: AddressEntity.identifierKey, type: .Integer, notNull: true, unique: true, primaryKey: true))
        addressesTable.addField(SQLiteTableField(name: AddressEntity.accountIdentifierKey, type: .Integer, notNull: true, unique: false))
        schema.addTable(addressesTable)
        
        let metadataTable = MetadataEntity.eponymTable
        metadataTable.addField(SQLiteTableField(name: MetadataEntity.identifierKey, type: .Integer, notNull: true, unique: true, primaryKey: true))
        metadataTable.addField(SQLiteTableField(name: MetadataEntity.schemaVersionKey, type: .Integer, notNull: true, unique: true))
        schema.addTable(metadataTable)
        
        // foreign keys
        let operationAccountForeignKey = SQLiteForeignKey(
            parentField: accountsTable.fieldWithName(AccountEntity.identifierKey)!,
            childField: operationsTable.fieldWithName(OperationEntity.accountIdentifierKey)!,
            updateAction: .Cascade, deleteAction: .Cascade)
        operationsTable.addForeignKey(operationAccountForeignKey)
        
        let addressAccountForeignKey = SQLiteForeignKey(
            parentField: accountsTable.fieldWithName(AccountEntity.identifierKey)!,
            childField: addressesTable.fieldWithName(AddressEntity.accountIdentifierKey)!,
            updateAction: .Cascade, deleteAction: .Cascade)
        addressesTable.addForeignKey(addressAccountForeignKey)
        
        return schema
    }
    
}