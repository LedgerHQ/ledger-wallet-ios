//
//  WalletStoreSchemas.swift
//  ledger-wallet-ios
//
//  Created by Nicolas Bigot on 01/12/2015.
//  Copyright © 2015 Ledger. All rights reserved.
//

import Foundation

final class WalletStoreSchemas {
    
    static var currentSchema: SQLiteSchema {
        return schemaWithVersion(currentVersion)!
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
        
        let transactionsTable = WalletTransactionTableEntity.eponymTable
        transactionsTable.addField(SQLiteTableField(name: WalletTransactionTableEntity.hashKey, type: .Text, notNull: true, unique: true))
        transactionsTable.addField(SQLiteTableField(name: WalletTransactionTableEntity.receptionDateKey, type: .Text, notNull: true, unique: false))
        transactionsTable.addField(SQLiteTableField(name: WalletTransactionTableEntity.lockTimeKey, type: .Integer, notNull: true, unique: false))
        transactionsTable.addField(SQLiteTableField(name: WalletTransactionTableEntity.feesKey, type: .Integer, notNull: true, unique: false))
        transactionsTable.addField(SQLiteTableField(name: WalletTransactionTableEntity.blockHashKey, type: .Text, notNull: false, unique: false))
        transactionsTable.addField(SQLiteTableField(name: WalletTransactionTableEntity.blockHeightKey, type: .Integer, notNull: false, unique: false))
        transactionsTable.addField(SQLiteTableField(name: WalletTransactionTableEntity.blockTimeKey, type: .Text, notNull: false, unique: false))
        schema.addTable(transactionsTable)

        let transactionInputsTable = WalletTransactionInputTableEntity.eponymTable
        transactionInputsTable.addField(SQLiteTableField(name: WalletTransactionInputTableEntity.outputHashKey, type: .Text, notNull: false, unique: false))
        transactionInputsTable.addField(SQLiteTableField(name: WalletTransactionInputTableEntity.outputIndexKey, type: .Integer, notNull: false, unique: false))
        transactionInputsTable.addField(SQLiteTableField(name: WalletTransactionInputTableEntity.valueKey, type: .Text, notNull: false, unique: false))
        transactionInputsTable.addField(SQLiteTableField(name: WalletTransactionInputTableEntity.scriptSignature, type: .Text, notNull: false, unique: false))
        transactionInputsTable.addField(SQLiteTableField(name: WalletTransactionInputTableEntity.addressKey, type: .Text, notNull: false, unique: false))
        transactionInputsTable.addField(SQLiteTableField(name: WalletTransactionInputTableEntity.coinbaseKey, type: .Integer, notNull: true, unique: false))
        transactionInputsTable.addField(SQLiteTableField(name: WalletTransactionInputTableEntity.transactionHashKey, type: .Text, notNull: true, unique: false))
        schema.addTable(transactionInputsTable)

        let transactionOutputsTable = WalletTransactionOutputTableEntity.eponymTable
        transactionOutputsTable.addField(SQLiteTableField(name: WalletTransactionOutputTableEntity.scriptHexKey, type: .Text, notNull: true, unique: false))
        transactionOutputsTable.addField(SQLiteTableField(name: WalletTransactionOutputTableEntity.valueKey, type: .Integer, notNull: true, unique: false))
        transactionOutputsTable.addField(SQLiteTableField(name: WalletTransactionOutputTableEntity.addressKey, type: .Text, notNull: false, unique: false))
        transactionOutputsTable.addField(SQLiteTableField(name: WalletTransactionOutputTableEntity.indexKey, type: .Integer, notNull: true, unique: false))
        transactionOutputsTable.addField(SQLiteTableField(name: WalletTransactionOutputTableEntity.transactionHashKey, type: .Text, notNull: true, unique: false))
        schema.addTable(transactionOutputsTable)

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
        
        let inputTransactionForeignKey = SQLiteForeignKey(
            parentField: transactionsTable.fieldWithName(WalletTransactionTableEntity.hashKey)!,
            childField: transactionInputsTable.fieldWithName(WalletTransactionInputTableEntity.transactionHashKey)!,
            updateAction: .Cascade, deleteAction: .Cascade)
        transactionInputsTable.addForeignKey(inputTransactionForeignKey)
        
        let outputTransactionForeignKey = SQLiteForeignKey(
            parentField: transactionsTable.fieldWithName(WalletTransactionTableEntity.hashKey)!,
            childField: transactionOutputsTable.fieldWithName(WalletTransactionOutputTableEntity.transactionHashKey)!,
            updateAction: .Cascade, deleteAction: .Cascade)
        transactionOutputsTable.addForeignKey(outputTransactionForeignKey)
        
        return schema
    }
    
}