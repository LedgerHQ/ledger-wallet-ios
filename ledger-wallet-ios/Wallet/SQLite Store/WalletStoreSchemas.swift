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
        let accountsTable = WalletAccountEntity.eponymTable
        accountsTable.addField(SQLiteTableField(name: WalletAccountEntity.indexKey, type: .Integer, notNull: true, unique: true))
        accountsTable.addField(SQLiteTableField(name: WalletAccountEntity.nameKey, type: .Text, notNull: false, unique: false))
        accountsTable.addField(SQLiteTableField(name: WalletAccountEntity.nextExternalIndexKey, type: .Integer, notNull: true, unique: false))
        accountsTable.addField(SQLiteTableField(name: WalletAccountEntity.nextInternalIndexKey, type: .Integer, notNull: true, unique: false))
        accountsTable.addField(SQLiteTableField(name: WalletAccountEntity.extendedPublicKeyKey, type: .Text, notNull: true, unique: true))
        accountsTable.addField(SQLiteTableField(name: WalletAccountEntity.hiddenKey, type: .Integer, notNull: true, unique: false))
        accountsTable.addField(SQLiteTableField(name: WalletAccountEntity.balanceKey, type: .Integer, notNull: true, unique: false))
        schema.addTable(accountsTable)
        
        let addressesTable = WalletAddressEntity.eponymTable
        addressesTable.addField(SQLiteTableField(name: WalletAddressEntity.addressKey, type: .Text, notNull: true, unique: true))
        addressesTable.addField(SQLiteTableField(name: WalletAddressEntity.chainIndexKey, type: .Integer, notNull: true, unique: false))
        addressesTable.addField(SQLiteTableField(name: WalletAddressEntity.keyIndexKey, type: .Integer, notNull: true, unique: false))
        addressesTable.addField(SQLiteTableField(name: WalletAddressEntity.accountIndexKey, type: .Integer, notNull: true, unique: false))
        schema.addTable(addressesTable)
        
        let metadataTable = WalletMetadataEntity.eponymTable
        metadataTable.addField(SQLiteTableField(name: WalletMetadataEntity.schemaVersionKey, type: .Integer, notNull: true, unique: true))
        metadataTable.addField(SQLiteTableField(name: WalletMetadataEntity.uniqueIdentifierKey, type: .Text, notNull: true, unique: true))
        schema.addTable(metadataTable)
        
        let transactionsTable = WalletTransactionEntity.eponymTable
        transactionsTable.addField(SQLiteTableField(name: WalletTransactionEntity.hashKey, type: .Text, notNull: true, unique: true))
        transactionsTable.addField(SQLiteTableField(name: WalletTransactionEntity.receptionDateKey, type: .Text, notNull: true, unique: false))
        transactionsTable.addField(SQLiteTableField(name: WalletTransactionEntity.lockTimeKey, type: .Integer, notNull: true, unique: false))
        transactionsTable.addField(SQLiteTableField(name: WalletTransactionEntity.feesKey, type: .Integer, notNull: true, unique: false))
        transactionsTable.addField(SQLiteTableField(name: WalletTransactionEntity.blockHashKey, type: .Text, notNull: false, unique: false))
        schema.addTable(transactionsTable)

        let transactionInputsTable = WalletTransactionInputEntity.eponymTable
        transactionInputsTable.addField(SQLiteTableField(name: WalletTransactionInputEntity.outputHashKey, type: .Text, notNull: false, unique: false))
        transactionInputsTable.addField(SQLiteTableField(name: WalletTransactionInputEntity.outputIndexKey, type: .Integer, notNull: false, unique: false))
        transactionInputsTable.addField(SQLiteTableField(name: WalletTransactionInputEntity.valueKey, type: .Text, notNull: false, unique: false))
        transactionInputsTable.addField(SQLiteTableField(name: WalletTransactionInputEntity.scriptSignature, type: .Text, notNull: false, unique: false))
        transactionInputsTable.addField(SQLiteTableField(name: WalletTransactionInputEntity.addressKey, type: .Text, notNull: false, unique: false))
        transactionInputsTable.addField(SQLiteTableField(name: WalletTransactionInputEntity.coinbaseKey, type: .Integer, notNull: true, unique: false))
        transactionInputsTable.addField(SQLiteTableField(name: WalletTransactionInputEntity.transactionHashKey, type: .Text, notNull: true, unique: false))
        schema.addTable(transactionInputsTable)

        let transactionOutputsTable = WalletTransactionOutputEntity.eponymTable
        transactionOutputsTable.addField(SQLiteTableField(name: WalletTransactionOutputEntity.scriptHexKey, type: .Text, notNull: true, unique: false))
        transactionOutputsTable.addField(SQLiteTableField(name: WalletTransactionOutputEntity.valueKey, type: .Integer, notNull: true, unique: false))
        transactionOutputsTable.addField(SQLiteTableField(name: WalletTransactionOutputEntity.addressKey, type: .Text, notNull: false, unique: false))
        transactionOutputsTable.addField(SQLiteTableField(name: WalletTransactionOutputEntity.indexKey, type: .Integer, notNull: true, unique: false))
        transactionOutputsTable.addField(SQLiteTableField(name: WalletTransactionOutputEntity.transactionHashKey, type: .Text, notNull: true, unique: false))
        schema.addTable(transactionOutputsTable)
        
        let operationsTable = WalletOperationEntity.eponymTable
        operationsTable.addField(SQLiteTableField(name: WalletOperationEntity.uidKey, type: .Text, notNull: true, unique: true))
        operationsTable.addField(SQLiteTableField(name: WalletOperationEntity.kindKey, type: .Text, notNull: true, unique: false))
        operationsTable.addField(SQLiteTableField(name: WalletOperationEntity.amountKey, type: .Integer, notNull: true, unique: false))
        operationsTable.addField(SQLiteTableField(name: WalletOperationEntity.transactionHashKey, type: .Text, notNull: true, unique: false))
        operationsTable.addField(SQLiteTableField(name: WalletOperationEntity.accountIndexKey, type: .Integer, notNull: true, unique: false))
        schema.addTable(operationsTable)
        
        let doubleSpendConflictsTable = WalletDoubleSpendConflictEntity.eponymTable
        doubleSpendConflictsTable.addField(SQLiteTableField(name: WalletDoubleSpendConflictEntity.leftTransactionHashKey, type: .Text, notNull: true, unique: false))
        doubleSpendConflictsTable.addField(SQLiteTableField(name: WalletDoubleSpendConflictEntity.rightTransactionHashKey, type: .Text, notNull: true, unique: false))
        schema.addTable(doubleSpendConflictsTable)
        
        let blocksTable = WalletBlockEntity.eponymTable
        blocksTable.addField(SQLiteTableField(name: WalletBlockEntity.hashKey, type: .Text, notNull: true, unique: true))
        blocksTable.addField(SQLiteTableField(name: WalletBlockEntity.timeKey, type: .Text, notNull: true, unique: false))
        blocksTable.addField(SQLiteTableField(name: WalletBlockEntity.heightKey, type: .Integer, notNull: true, unique: false))
        schema.addTable(blocksTable)

        // foreign keys
        let addressAccountForeignKey = SQLiteForeignKey(
            parentField: accountsTable.fieldWithName(WalletAccountEntity.indexKey)!,
            childField: addressesTable.fieldWithName(WalletAddressEntity.accountIndexKey)!,
            updateAction: .Cascade, deleteAction: .Cascade)
        addressesTable.addForeignKey(addressAccountForeignKey)
        
        let inputTransactionForeignKey = SQLiteForeignKey(
            parentField: transactionsTable.fieldWithName(WalletTransactionEntity.hashKey)!,
            childField: transactionInputsTable.fieldWithName(WalletTransactionInputEntity.transactionHashKey)!,
            updateAction: .Cascade, deleteAction: .Cascade)
        transactionInputsTable.addForeignKey(inputTransactionForeignKey)
        
        let outputTransactionForeignKey = SQLiteForeignKey(
            parentField: transactionsTable.fieldWithName(WalletTransactionEntity.hashKey)!,
            childField: transactionOutputsTable.fieldWithName(WalletTransactionOutputEntity.transactionHashKey)!,
            updateAction: .Cascade, deleteAction: .Cascade)
        transactionOutputsTable.addForeignKey(outputTransactionForeignKey)
        
        let operationAccountForeignKey = SQLiteForeignKey(
            parentField: accountsTable.fieldWithName(WalletAccountEntity.indexKey)!,
            childField: operationsTable.fieldWithName(WalletOperationEntity.accountIndexKey)!,
            updateAction: .Cascade, deleteAction: .Cascade)
        operationsTable.addForeignKey(operationAccountForeignKey)
        
        let operationTransactionForeignKey = SQLiteForeignKey(
            parentField: transactionsTable.fieldWithName(WalletTransactionEntity.hashKey)!,
            childField: operationsTable.fieldWithName(WalletOperationEntity.transactionHashKey)!,
            updateAction: .Cascade, deleteAction: .Cascade)
        operationsTable.addForeignKey(operationTransactionForeignKey)
        
        let doubleSpendConflictLeftTransactionForeignKey = SQLiteForeignKey(
            parentField: transactionsTable.fieldWithName(WalletTransactionEntity.hashKey)!,
            childField: doubleSpendConflictsTable.fieldWithName(WalletDoubleSpendConflictEntity.leftTransactionHashKey)!,
            updateAction: .Cascade, deleteAction: .Cascade)
        doubleSpendConflictsTable.addForeignKey(doubleSpendConflictLeftTransactionForeignKey)
        
        let doubleSpendConflictRightTransactionForeignKey = SQLiteForeignKey(
            parentField: transactionsTable.fieldWithName(WalletTransactionEntity.hashKey)!,
            childField: doubleSpendConflictsTable.fieldWithName(WalletDoubleSpendConflictEntity.rightTransactionHashKey)!,
            updateAction: .Cascade, deleteAction: .Cascade)
        doubleSpendConflictsTable.addForeignKey(doubleSpendConflictRightTransactionForeignKey)
        
        let transactionBlockForeignKey = SQLiteForeignKey(
            parentField: blocksTable.fieldWithName(WalletBlockEntity.hashKey)!,
            childField: transactionsTable.fieldWithName(WalletTransactionEntity.blockHashKey)!,
            updateAction: .Cascade, deleteAction: .Cascade)
        transactionsTable.addForeignKey(transactionBlockForeignKey)

        return schema
    }
    
}