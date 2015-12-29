//
//  WalletStoreExecutor.swift
//  ledger-wallet-ios
//
//  Created by Nicolas Bigot on 07/12/2015.
//  Copyright © 2015 Ledger. All rights reserved.
//

import Foundation

final class WalletStoreExecutor {
    
    private static let logger = Logger.sharedInstance(name: "WalletStoreExecutor")

    // MARK: Accounts management

    class func fetchAllAccounts(context: SQLiteStoreContext) -> [WalletAccountModel]? {
        let fieldsStatement = "\"\(WalletAccountTableEntity.indexKey)\", \"\(WalletAccountTableEntity.nameKey)\", \"\(WalletAccountTableEntity.extendedPublicKeyKey)\", \"\(WalletAccountTableEntity.nextInternalIndexKey)\", \"\(WalletAccountTableEntity.nextExternalIndexKey)\""
        let statement = "SELECT \(fieldsStatement) FROM \"\(WalletAccountTableEntity.tableName)\" ORDER BY \"\(WalletAccountTableEntity.indexKey)\" ASC"
        return fetchModelCollection(statement, context: context)
    }
    
    class func fetchAccountAtIndex(index: Int, context: SQLiteStoreContext) -> WalletAccountModel? {
        guard let accounts = fetchAccountsAtIndexes([index], context: context) where accounts.count > 0 else { return nil }
        return accounts[0]
    }
    
    class func fetchAccountsAtIndexes(indexes: [Int], context: SQLiteStoreContext) -> [WalletAccountModel]? {
        guard indexes.count > 0 else { return [] }
        
        let inStatement = indexes.map({ return "\($0)" }).joinWithSeparator(", ")
        let fieldsStatement = "\"\(WalletAccountTableEntity.indexKey)\", \"\(WalletAccountTableEntity.nameKey)\", \"\(WalletAccountTableEntity.extendedPublicKeyKey)\", \"\(WalletAccountTableEntity.nextInternalIndexKey)\", \"\(WalletAccountTableEntity.nextExternalIndexKey)\""
        let statement = "SELECT \(fieldsStatement) FROM \"\(WalletAccountTableEntity.tableName)\" WHERE \"\(WalletAccountTableEntity.indexKey)\" IN (\(inStatement))"
        return fetchModelCollection(statement, context: context)
    }

    class func addAccount(account: WalletAccountModel, context: SQLiteStoreContext) -> Bool {
        let fieldsStatement = "(\"\(WalletAccountTableEntity.indexKey)\", \"\(WalletAccountTableEntity.nameKey)\", \"\(WalletAccountTableEntity.extendedPublicKeyKey)\", \"\(WalletAccountTableEntity.nextExternalIndexKey)\", \"\(WalletAccountTableEntity.nextInternalIndexKey)\")"
        let statement = "INSERT INTO \"\(WalletAccountTableEntity.tableName)\" \(fieldsStatement) VALUES (?, ?, ?, ?, ?)"
        let values = [account.index, account.name ?? NSNull(), account.extendedPublicKey, account.nextExternalIndex, account.nextInternalIndex]
        guard context.executeUpdate(statement, withArgumentsInArray: values) else {
            logger.error("Unable to insert account: \(context.lastErrorMessage())")
            return false
        }
        return true
    }
    
    class func setNextIndex(index: Int, forAccountAtIndex accountIndex: Int, external: Bool, context: SQLiteStoreContext) -> Bool {
        guard let currentIndex = fetchNextIndexForAccountAtIndex(accountIndex, external: external, context: context) else { return false }
        guard index > currentIndex else { return true }
        
        let fieldName = external ? WalletAccountTableEntity.nextExternalIndexKey : WalletAccountTableEntity.nextInternalIndexKey
        let statement = "UPDATE \"\(WalletAccountTableEntity.tableName)\" SET \"\(fieldName)\" = ? WHERE \"\(WalletAccountTableEntity.indexKey)\" = ?"
        guard context.executeUpdate(statement, withArgumentsInArray: [index, accountIndex]) else {
            logger.error("Unable to set \(fieldName) for account at index \(accountIndex): \(context.lastErrorMessage())")
            return false
        }
        return true
    }
    
    private class func fetchNextIndexForAccountAtIndex(index: Int, external: Bool, context: SQLiteStoreContext) -> Int? {
        let fieldName = external ? WalletAccountTableEntity.nextExternalIndexKey : WalletAccountTableEntity.nextInternalIndexKey
        guard let account = fetchAccountAtIndex(index, context: context) else {
            logger.error("Unable to fetch account at index \(index) to fetch \(fieldName): \(context.lastErrorMessage())")
            return nil
        }
        if external {
            return account.nextExternalIndex
        }
        return account.nextInternalIndex
    }
    
    // MARK: Addresses management
    
    class func fetchAddressesAtPaths(paths: [WalletAddressPath], context: SQLiteStoreContext) -> [WalletAddressModel]? {
        guard paths.count > 0 else { return [] }
        
        let inStatement = paths.map({ return "\"\($0.relativePath)\"" }).joinWithSeparator(", ")
        let concatStatement = "('/' || \"\(WalletAddressTableEntity.accountIndexKey)\" || '''/' || \"\(WalletAddressTableEntity.chainIndexKey)\" || '/' || \"\(WalletAddressTableEntity.keyIndexKey)\") AS path"
        let fieldsStatement = "\"\(WalletAddressTableEntity.addressKey)\", \"\(WalletAddressTableEntity.accountIndexKey)\", \"\(WalletAddressTableEntity.chainIndexKey)\", \"\(WalletAddressTableEntity.keyIndexKey)\""
        let statement = "SELECT \(fieldsStatement), \(concatStatement) FROM \"\(WalletAddressTableEntity.tableName)\" WHERE path IN (\(inStatement))"
        return fetchModelCollection(statement, context: context)
    }
    
    class func fetchAddressesWithAddresses(addresses: [String], context: SQLiteStoreContext) -> [WalletAddressModel]? {
        guard addresses.count > 0 else { return [] }

        let inStatement = addresses.map({ return "\"\($0)\"" }).joinWithSeparator(", ")
        let fieldsStatement = "\"\(WalletAddressTableEntity.addressKey)\", \"\(WalletAddressTableEntity.accountIndexKey)\", \"\(WalletAddressTableEntity.chainIndexKey)\", \"\(WalletAddressTableEntity.keyIndexKey)\""
        let statement = "SELECT \(fieldsStatement) FROM \"\(WalletAddressTableEntity.tableName)\" WHERE \"\(WalletAddressTableEntity.addressKey)\" IN (\(inStatement))"
        return fetchModelCollection(statement, context: context)
    }
    
    class func storeAddress(address: WalletAddressModel, context: SQLiteStoreContext) -> Bool {
        guard fetchAddressWithAddress(address.address, context: context) == nil else { return true }
        guard fetchAddressAtPath(address.path, context: context) == nil else { return true }
        
        let fieldsStatement = "(\"\(WalletAddressTableEntity.accountIndexKey)\", \"\(WalletAddressTableEntity.chainIndexKey)\", \"\(WalletAddressTableEntity.keyIndexKey)\", \"\(WalletAddressTableEntity.addressKey)\")"
        let statement = "INSERT INTO \"\(WalletAddressTableEntity.tableName)\" \(fieldsStatement) VALUES (?, ?, ?, ?)"
        let values: [AnyObject] = [address.path.accountIndex, address.path.chainIndex, address.path.keyIndex, address.address]
        guard context.executeUpdate(statement, withArgumentsInArray: values) else {
            logger.error("Unable to insert address: \(context.lastErrorMessage())")
            return false
        }
        return true
    }
    
    class func storeAddresses(addresses: [WalletAddressModel], context: SQLiteStoreContext) -> Bool {
        guard addresses.count > 0 else { return true }
        return addresses.reduce(true) { $0 && storeAddress($1, context: context) }
    }
    
    private class func fetchAddressAtPath(path: WalletAddressPath, context: SQLiteStoreContext) -> WalletAddressModel? {
        guard let results = fetchAddressesAtPaths([path], context: context) where results.count >= 1 else { return nil }
        return results[0]
    }
    
    private class func fetchAddressWithAddress(address: String, context: SQLiteStoreContext) -> WalletAddressModel? {
        guard let results = fetchAddressesWithAddresses([address], context: context) where results.count >= 1 else { return nil }
        return results[0]
    }
    
    // MARK: Transactions management
    
    class func storeTransactions(transactions: [WalletRemoteTransaction], context: SQLiteStoreContext) -> Bool {
        guard transactions.count > 0 else { return true }
        return transactions.reduce(true) { $0 && storeTransaction($1, context: context) }
    }
    
    class func storeTransaction(transaction: WalletRemoteTransaction, context: SQLiteStoreContext) -> Bool {
        let updateFieldsStatement = "\"\(WalletTransactionTableEntity.blockHashKey)\" = ?, \"\(WalletTransactionTableEntity.blockHeightKey)\" = ?, \"\(WalletTransactionTableEntity.blockTimeKey)\" = ?"
        let updateStatement = "UPDATE \"\(WalletTransactionTableEntity.tableName)\" SET \(updateFieldsStatement) WHERE \"\(WalletTransactionTableEntity.hashKey)\" = ?"
        let updateValues = [
            transaction.blockHash ?? NSNull(),
            transaction.blockHeight ?? NSNull(),
            transaction.blockTime ?? NSNull(),
            transaction.hash
        ]
        guard context.executeUpdate(updateStatement, withArgumentsInArray: updateValues) else {
            logger.error("Unable to update transaction \(transaction.hash): \(context.lastErrorMessage())")
            return false
        }
        if context.changes() == 0 {
            let insertFieldsStatement = "(\"\(WalletTransactionTableEntity.hashKey)\", \"\(WalletTransactionTableEntity.receptionDateKey)\", \"\(WalletTransactionTableEntity.lockTimeKey)\", \"\(WalletTransactionTableEntity.feesKey)\", \"\(WalletTransactionTableEntity.blockHashKey)\", \"\(WalletTransactionTableEntity.blockHeightKey)\", \"\(WalletTransactionTableEntity.blockTimeKey)\")"
            let insertStatement = "INSERT INTO \"\(WalletTransactionTableEntity.tableName)\" \(insertFieldsStatement) VALUES (?, ?, ?, ?, ?, ?, ?)"
            let insertValues = [
                transaction.hash,
                transaction.receiveAt,
                transaction.lockTime,
                NSNumber(longLong: transaction.fees),
                transaction.blockHash ?? NSNull(),
                transaction.blockHeight ?? NSNull(),
                transaction.blockTime ?? NSNull()
            ]
            guard context.executeUpdate(insertStatement, withArgumentsInArray: insertValues) else {
                logger.error("Unable to insert transaction \(transaction.hash): \(context.lastErrorMessage())")
                return false
            }
            guard addTransactionInputs(transaction, context: context) else { return false }
            guard addTransactionOutputs(transaction, context: context) else { return false }
        }
        return true
    }
    
    private class func addTransactionInputs(transaction: WalletRemoteTransaction, context: SQLiteStoreContext) -> Bool {
        guard transaction.inputs.count > 0 else { return true }
        
        for input in transaction.inputs {
            let insertFieldsStatement = "(\"\(WalletTransactionInputTableEntity.addressKey)\", \"\(WalletTransactionInputTableEntity.outputHashKey)\", \"\(WalletTransactionInputTableEntity.outputIndexKey)\", \"\(WalletTransactionInputTableEntity.valueKey)\", \"\(WalletTransactionInputTableEntity.scriptSignature)\", \"\(WalletTransactionInputTableEntity.coinbaseKey)\", \"\(WalletTransactionInputTableEntity.transactionHashKey)\")"
            let insertValues: [AnyObject]
            if let input = input as? WalletRemoteTransactionRegularInput {
                insertValues = [
                    input.address ?? NSNull(),
                    input.outputHash,
                    input.outputIndex,
                    NSNumber(longLong: input.value),
                    input.scriptSignature,
                    false,
                    transaction.hash
                ]
            }
            else {
                insertValues = [
                    NSNull(),
                    NSNull(),
                    NSNull(),
                    NSNull(),
                    NSNull(),
                    true,
                    transaction.hash
                ]
            }
            let insertStatement = "INSERT INTO \"\(WalletTransactionInputTableEntity.tableName)\" \(insertFieldsStatement) VALUES (?, ?, ?, ?, ?, ?, ?)"
            guard context.executeUpdate(insertStatement, withArgumentsInArray: insertValues) else {
                logger.error("Unable to insert input for transaction \(transaction.hash): \(context.lastErrorMessage())")
                return false
            }
        }
        return true
    }
    
    private class func addTransactionOutputs(transaction: WalletRemoteTransaction, context: SQLiteStoreContext) -> Bool {
        guard transaction.outputs.count > 0 else { return true }

        for output in transaction.outputs {
            let insertFieldsStatement = "(\"\(WalletTransactionOutputTableEntity.addressKey)\", \"\(WalletTransactionOutputTableEntity.scriptHexKey)\", \"\(WalletTransactionOutputTableEntity.valueKey)\", \"\(WalletTransactionOutputTableEntity.indexKey)\", \"\(WalletTransactionOutputTableEntity.transactionHashKey)\")"
            let insertValues = [
                output.address ?? NSNull(),
                output.scriptHex,
                NSNumber(longLong: output.value),
                output.index,
                transaction.hash
            ]
            let insertStatement = "INSERT INTO \"\(WalletTransactionOutputTableEntity.tableName)\" \(insertFieldsStatement) VALUES (?, ?, ?, ?, ?)"
            guard context.executeUpdate(insertStatement, withArgumentsInArray: insertValues) else {
                logger.error("Unable to insert output for transaction \(transaction.hash): \(context.lastErrorMessage())")
                return false
            }
        }
        return true
    }
    
    // MARK: Operations management
    
    class func storeOperations(operations: [WalletLocalOperation], context: SQLiteStoreContext) -> Bool {
        guard operations.count > 0 else { return true }
        return operations.reduce(true) { $0 && storeOperation($1, context: context) }
    }
    
    private class func storeOperation(operation: WalletLocalOperation, context: SQLiteStoreContext) -> Bool {
        let updateFieldsStatement = "\"\(WalletOperationTableEntity.amountKey)\" = ?"
        let updateStatement = "UPDATE \"\(WalletOperationTableEntity.tableName)\" SET \(updateFieldsStatement) WHERE \"\(WalletOperationTableEntity.uidKey)\" = ?"
        let updateValues = [NSNumber(longLong: operation.amount), operation.uid]
        guard context.executeUpdate(updateStatement, withArgumentsInArray: updateValues) else {
            logger.error("Unable to update operation \(operation.uid): \(context.lastErrorMessage())")
            return false
        }
        if context.changes() == 0 {
            let insertFieldsStatement = "\"\(WalletOperationTableEntity.accountIndexKey)\", \"\(WalletOperationTableEntity.amountKey)\", \"\(WalletOperationTableEntity.kindKey)\", \"\(WalletOperationTableEntity.uidKey)\", \"\(WalletOperationTableEntity.transactionHashKey)\""
            let insertStatement = "INSERT INTO \"\(WalletOperationTableEntity.tableName)\" (\(insertFieldsStatement)) VALUES (?, ?, ?, ?, ?)"
            let insertValues = [
                operation.accountIndex,
                NSNumber(longLong: operation.amount),
                operation.kind.rawValue,
                operation.uid,
                operation.transactionHash
            ]
            guard context.executeUpdate(insertStatement, withArgumentsInArray: insertValues) else {
                logger.error("Unable to insert operation \(operation.uid): \(context.lastErrorMessage())")
                return false
            }
        }
        return true
    }
    
    // MARK: Schema management
    
    class func schemaVersion(context: SQLiteStoreContext) -> Int? {
        guard let results = context.executeQuery("SELECT \(WalletMetadataTableEntity.schemaVersionKey) FROM \(WalletMetadataTableEntity.tableName)", withArgumentsInArray: nil) else {
            logger.warn("Unable to fetch schema version: \(context.lastErrorMessage())")
            return nil
        }
        guard results.next() && !results.columnIsNull(WalletMetadataTableEntity.schemaVersionKey) else {
            logger.warn("Unable to fetch schema version: no row")
            return nil
        }
        let version = results.longForColumn(WalletMetadataTableEntity.schemaVersionKey)
        guard version > 0 else {
            logger.error("Unable to fetch schema version: value is <= 0")
            return nil
        }
        return version
    }

    class func updateMetadata(metadata: [String: AnyObject], context: SQLiteStoreContext) -> Bool {
        guard metadata.count > 0 else { return true }
        
        let updateStatement = metadata.map { return "\"\($0.0)\" = :\($0.0)" }.joinWithSeparator(", ")
        guard context.executeUpdate("UPDATE \"\(WalletMetadataTableEntity.tableName)\" SET \(updateStatement)", withParameterDictionary: metadata) else {
            logger.error("Unable to set database metadata \(metadata): \(context.lastErrorMessage())")
            return false
        }
        if context.changes() == 0 {
            let insertStatement = metadata.map { "\"\($0.0)\"" }.joinWithSeparator(", ")
            let valuesStatement = metadata.map { ":\($0.0)" }.joinWithSeparator(", ")
            guard context.executeUpdate("INSERT INTO \"\(WalletMetadataTableEntity.tableName)\" (\(insertStatement)) VALUES (\(valuesStatement))", withParameterDictionary: metadata) else {
                logger.error("Unable to set database metadata \(metadata): \(context.lastErrorMessage())")
                return false
            }
        }
        return true
    }
    
    class func executePragmaCommand(statement: String, context: SQLiteStoreContext) -> Bool {
        guard let _ = context.executeQuery(statement, withArgumentsInArray: nil) else {
            logger.error("Unable to execute pragma command \(statement): \(context.lastErrorMessage())")
            return false
        }
        return true
    }
    
    class func executeTableCreation(statement: String, context: SQLiteStoreContext) -> Bool {
        guard context.executeUpdate(statement, withArgumentsInArray: nil) else {
            logger.error("Unable to execute table creation \(statement): \(context.lastErrorMessage())")
            return false
        }
        return true
    }
    
    // MARK: Internal methods
    
    private class func fetchModel<T: SQLiteFetchableModel>(statement: String, values: [AnyObject]? = nil, context: SQLiteStoreContext) -> T? {
        guard let results = context.executeQuery(statement, withArgumentsInArray: values) else {
            logger.error("Unable to fetch model of type \(T.self): \(context.lastErrorMessage())")
            return nil
        }
        guard results.next() else {
            return nil
        }
        return T.init(resultSet: results)
    }
    
    private class func fetchModelCollection<T: SQLiteFetchableModel>(statement: String, values: [AnyObject]? = nil, context: SQLiteStoreContext) -> [T]? {
        guard let results = context.executeQuery(statement, withArgumentsInArray: values) else {
            logger.error("Unable to fetch model collection of type \(T.self): \(context.lastErrorMessage())")
            return nil
        }
        return T.collectionFromResultSet(results)
    }
}