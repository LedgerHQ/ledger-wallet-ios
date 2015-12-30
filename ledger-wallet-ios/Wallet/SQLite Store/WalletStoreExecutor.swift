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

    class func fetchAllAccounts(context: SQLiteStoreContext) -> [WalletAccount]? {
        let fieldsStatement = "\"\(WalletAccountEntity.indexKey)\", \"\(WalletAccountEntity.nameKey)\", \"\(WalletAccountEntity.extendedPublicKeyKey)\", \"\(WalletAccountEntity.nextInternalIndexKey)\", \"\(WalletAccountEntity.nextExternalIndexKey)\""
        let statement = "SELECT \(fieldsStatement) FROM \"\(WalletAccountEntity.tableName)\" ORDER BY \"\(WalletAccountEntity.indexKey)\" ASC"
        return fetchModelCollection(statement, context: context)
    }
    
    class func fetchAccountAtIndex(index: Int, context: SQLiteStoreContext) -> WalletAccount? {
        guard let accounts = fetchAccountsAtIndexes([index], context: context) where accounts.count > 0 else { return nil }
        return accounts[0]
    }
    
    class func fetchAccountsAtIndexes(indexes: [Int], context: SQLiteStoreContext) -> [WalletAccount]? {
        guard indexes.count > 0 else { return [] }
        
        let inStatement = indexes.map({ return "\($0)" }).joinWithSeparator(", ")
        let fieldsStatement = "\"\(WalletAccountEntity.indexKey)\", \"\(WalletAccountEntity.nameKey)\", \"\(WalletAccountEntity.extendedPublicKeyKey)\", \"\(WalletAccountEntity.nextInternalIndexKey)\", \"\(WalletAccountEntity.nextExternalIndexKey)\""
        let statement = "SELECT \(fieldsStatement) FROM \"\(WalletAccountEntity.tableName)\" WHERE \"\(WalletAccountEntity.indexKey)\" IN (\(inStatement))"
        return fetchModelCollection(statement, context: context)
    }

    class func addAccount(account: WalletAccount, context: SQLiteStoreContext) -> Bool {
        let fieldsStatement = "(\"\(WalletAccountEntity.indexKey)\", \"\(WalletAccountEntity.nameKey)\", \"\(WalletAccountEntity.extendedPublicKeyKey)\", \"\(WalletAccountEntity.nextExternalIndexKey)\", \"\(WalletAccountEntity.nextInternalIndexKey)\")"
        let statement = "INSERT INTO \"\(WalletAccountEntity.tableName)\" \(fieldsStatement) VALUES (?, ?, ?, ?, ?)"
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
        
        let fieldName = external ? WalletAccountEntity.nextExternalIndexKey : WalletAccountEntity.nextInternalIndexKey
        let statement = "UPDATE \"\(WalletAccountEntity.tableName)\" SET \"\(fieldName)\" = ? WHERE \"\(WalletAccountEntity.indexKey)\" = ?"
        guard context.executeUpdate(statement, withArgumentsInArray: [index, accountIndex]) else {
            logger.error("Unable to set \(fieldName) for account at index \(accountIndex): \(context.lastErrorMessage())")
            return false
        }
        return true
    }
    
    private class func fetchNextIndexForAccountAtIndex(index: Int, external: Bool, context: SQLiteStoreContext) -> Int? {
        let fieldName = external ? WalletAccountEntity.nextExternalIndexKey : WalletAccountEntity.nextInternalIndexKey
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
    
    class func fetchAddressesAtPaths(paths: [WalletAddressPath], context: SQLiteStoreContext) -> [WalletAddress]? {
        guard paths.count > 0 else { return [] }
        
        let inStatement = paths.map({ return "\"\($0.relativePath)\"" }).joinWithSeparator(", ")
        let concatStatement = "('/' || \"\(WalletAddressEntity.accountIndexKey)\" || '''/' || \"\(WalletAddressEntity.chainIndexKey)\" || '/' || \"\(WalletAddressEntity.keyIndexKey)\") AS path"
        let fieldsStatement = "\"\(WalletAddressEntity.addressKey)\", \"\(WalletAddressEntity.accountIndexKey)\", \"\(WalletAddressEntity.chainIndexKey)\", \"\(WalletAddressEntity.keyIndexKey)\""
        let statement = "SELECT \(fieldsStatement), \(concatStatement) FROM \"\(WalletAddressEntity.tableName)\" WHERE path IN (\(inStatement))"
        return fetchModelCollection(statement, context: context)
    }
    
    class func fetchAddressesWithAddresses(addresses: [String], context: SQLiteStoreContext) -> [WalletAddress]? {
        guard addresses.count > 0 else { return [] }

        let inStatement = addresses.map({ return "\"\($0)\"" }).joinWithSeparator(", ")
        let fieldsStatement = "\"\(WalletAddressEntity.addressKey)\", \"\(WalletAddressEntity.accountIndexKey)\", \"\(WalletAddressEntity.chainIndexKey)\", \"\(WalletAddressEntity.keyIndexKey)\""
        let statement = "SELECT \(fieldsStatement) FROM \"\(WalletAddressEntity.tableName)\" WHERE \"\(WalletAddressEntity.addressKey)\" IN (\(inStatement))"
        return fetchModelCollection(statement, context: context)
    }
    
    class func addAddress(address: WalletAddress, context: SQLiteStoreContext) -> Bool {
        guard fetchAddressWithAddress(address.address, context: context) == nil else { return true }
        guard fetchAddressAtPath(address.path, context: context) == nil else { return true }
        
        let fieldsStatement = "(\"\(WalletAddressEntity.accountIndexKey)\", \"\(WalletAddressEntity.chainIndexKey)\", \"\(WalletAddressEntity.keyIndexKey)\", \"\(WalletAddressEntity.addressKey)\")"
        let statement = "INSERT INTO \"\(WalletAddressEntity.tableName)\" \(fieldsStatement) VALUES (?, ?, ?, ?)"
        let values: [AnyObject] = [address.path.accountIndex, address.path.chainIndex, address.path.keyIndex, address.address]
        guard context.executeUpdate(statement, withArgumentsInArray: values) else {
            logger.error("Unable to insert address: \(context.lastErrorMessage())")
            return false
        }
        return true
    }
    
    class func addAddresses(addresses: [WalletAddress], context: SQLiteStoreContext) -> Bool {
        guard addresses.count > 0 else { return true }
        return addresses.reduce(true) { $0 && addAddress($1, context: context) }
    }
    
    private class func fetchAddressAtPath(path: WalletAddressPath, context: SQLiteStoreContext) -> WalletAddress? {
        guard let results = fetchAddressesAtPaths([path], context: context) where results.count >= 1 else { return nil }
        return results[0]
    }
    
    private class func fetchAddressWithAddress(address: String, context: SQLiteStoreContext) -> WalletAddress? {
        guard let results = fetchAddressesWithAddresses([address], context: context) where results.count >= 1 else { return nil }
        return results[0]
    }
    
    // MARK: Transactions management
    
    class func storeTransactions(transactions: [WalletRemoteTransaction], context: SQLiteStoreContext) -> Bool {
        guard transactions.count > 0 else { return true }
        return transactions.reduce(true) { $0 && storeTransaction($1, context: context) }
    }
    
    class func storeTransaction(transaction: WalletRemoteTransaction, context: SQLiteStoreContext) -> Bool {
        let updateFieldsStatement = "\"\(WalletTransactionEntity.blockHashKey)\" = ?, \"\(WalletTransactionEntity.blockHeightKey)\" = ?, \"\(WalletTransactionEntity.blockTimeKey)\" = ?"
        let updateStatement = "UPDATE \"\(WalletTransactionEntity.tableName)\" SET \(updateFieldsStatement) WHERE \"\(WalletTransactionEntity.hashKey)\" = ?"
        let updateValues = [
            transaction.transaction.blockHash ?? NSNull(),
            transaction.transaction.blockHeight ?? NSNull(),
            transaction.transaction.blockTime ?? NSNull(),
            transaction.transaction.hash
        ]
        guard context.executeUpdate(updateStatement, withArgumentsInArray: updateValues) else {
            logger.error("Unable to update transaction \(transaction.transaction.hash): \(context.lastErrorMessage())")
            return false
        }
        if context.changes() == 0 {
            let insertFieldsStatement = "(\"\(WalletTransactionEntity.hashKey)\", \"\(WalletTransactionEntity.receptionDateKey)\", \"\(WalletTransactionEntity.lockTimeKey)\", \"\(WalletTransactionEntity.feesKey)\", \"\(WalletTransactionEntity.blockHashKey)\", \"\(WalletTransactionEntity.blockHeightKey)\", \"\(WalletTransactionEntity.blockTimeKey)\")"
            let insertStatement = "INSERT INTO \"\(WalletTransactionEntity.tableName)\" \(insertFieldsStatement) VALUES (?, ?, ?, ?, ?, ?, ?)"
            let insertValues = [
                transaction.transaction.hash,
                transaction.transaction.receiveAt,
                transaction.transaction.lockTime,
                NSNumber(longLong: transaction.transaction.fees),
                transaction.transaction.blockHash ?? NSNull(),
                transaction.transaction.blockHeight ?? NSNull(),
                transaction.transaction.blockTime ?? NSNull()
            ]
            guard context.executeUpdate(insertStatement, withArgumentsInArray: insertValues) else {
                logger.error("Unable to insert transaction \(transaction.transaction.hash): \(context.lastErrorMessage())")
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
            let insertFieldsStatement = "(\"\(WalletTransactionInputEntity.addressKey)\", \"\(WalletTransactionInputEntity.outputHashKey)\", \"\(WalletTransactionInputEntity.outputIndexKey)\", \"\(WalletTransactionInputEntity.valueKey)\", \"\(WalletTransactionInputEntity.scriptSignature)\", \"\(WalletTransactionInputEntity.coinbaseKey)\", \"\(WalletTransactionInputEntity.transactionHashKey)\")"
            let insertValues: [AnyObject]
            if let input = input as? WalletTransactionRegularInput {
                insertValues = [
                    input.address ?? NSNull(),
                    input.outputHash,
                    input.outputIndex,
                    NSNumber(longLong: input.value),
                    input.scriptSignature,
                    false,
                    transaction.transaction.hash
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
                    transaction.transaction.hash
                ]
            }
            let insertStatement = "INSERT INTO \"\(WalletTransactionInputEntity.tableName)\" \(insertFieldsStatement) VALUES (?, ?, ?, ?, ?, ?, ?)"
            guard context.executeUpdate(insertStatement, withArgumentsInArray: insertValues) else {
                logger.error("Unable to insert input for transaction \(transaction.transaction.hash): \(context.lastErrorMessage())")
                return false
            }
        }
        return true
    }
    
    private class func addTransactionOutputs(transaction: WalletRemoteTransaction, context: SQLiteStoreContext) -> Bool {
        guard transaction.outputs.count > 0 else { return true }

        for output in transaction.outputs {
            let insertFieldsStatement = "(\"\(WalletTransactionOutputEntity.addressKey)\", \"\(WalletTransactionOutputEntity.scriptHexKey)\", \"\(WalletTransactionOutputEntity.valueKey)\", \"\(WalletTransactionOutputEntity.indexKey)\", \"\(WalletTransactionOutputEntity.transactionHashKey)\")"
            let insertValues = [
                output.address ?? NSNull(),
                output.scriptHex,
                NSNumber(longLong: output.value),
                output.index,
                transaction.transaction.hash
            ]
            let insertStatement = "INSERT INTO \"\(WalletTransactionOutputEntity.tableName)\" \(insertFieldsStatement) VALUES (?, ?, ?, ?, ?)"
            guard context.executeUpdate(insertStatement, withArgumentsInArray: insertValues) else {
                logger.error("Unable to insert output for transaction \(transaction.transaction.hash): \(context.lastErrorMessage())")
                return false
            }
        }
        return true
    }
    
    // MARK: Operations management
    
    class func storeOperations(operations: [WalletOperation], context: SQLiteStoreContext) -> Bool {
        guard operations.count > 0 else { return true }
        return operations.reduce(true) { $0 && storeOperation($1, context: context) }
    }
    
    private class func storeOperation(operation: WalletOperation, context: SQLiteStoreContext) -> Bool {
        let updateFieldsStatement = "\"\(WalletOperationEntity.amountKey)\" = ?"
        let updateStatement = "UPDATE \"\(WalletOperationEntity.tableName)\" SET \(updateFieldsStatement) WHERE \"\(WalletOperationEntity.uidKey)\" = ?"
        let updateValues = [NSNumber(longLong: operation.amount), operation.uid]
        guard context.executeUpdate(updateStatement, withArgumentsInArray: updateValues) else {
            logger.error("Unable to update operation \(operation.uid): \(context.lastErrorMessage())")
            return false
        }
        if context.changes() == 0 {
            let insertFieldsStatement = "\"\(WalletOperationEntity.accountIndexKey)\", \"\(WalletOperationEntity.amountKey)\", \"\(WalletOperationEntity.kindKey)\", \"\(WalletOperationEntity.uidKey)\", \"\(WalletOperationEntity.transactionHashKey)\""
            let insertStatement = "INSERT INTO \"\(WalletOperationEntity.tableName)\" (\(insertFieldsStatement)) VALUES (?, ?, ?, ?, ?)"
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
        guard let results = context.executeQuery("SELECT \(WalletMetadataEntity.schemaVersionKey) FROM \(WalletMetadataEntity.tableName)", withArgumentsInArray: nil) else {
            logger.warn("Unable to fetch schema version: \(context.lastErrorMessage())")
            return nil
        }
        guard results.next() && !results.columnIsNull(WalletMetadataEntity.schemaVersionKey) else {
            logger.warn("Unable to fetch schema version: no row")
            return nil
        }
        let version = results.longForColumn(WalletMetadataEntity.schemaVersionKey)
        guard version > 0 else {
            logger.error("Unable to fetch schema version: value is <= 0")
            return nil
        }
        return version
    }

    class func updateMetadata(metadata: [String: AnyObject], context: SQLiteStoreContext) -> Bool {
        guard metadata.count > 0 else { return true }
        
        let updateStatement = metadata.map { return "\"\($0.0)\" = :\($0.0)" }.joinWithSeparator(", ")
        guard context.executeUpdate("UPDATE \"\(WalletMetadataEntity.tableName)\" SET \(updateStatement)", withParameterDictionary: metadata) else {
            logger.error("Unable to set database metadata \(metadata): \(context.lastErrorMessage())")
            return false
        }
        if context.changes() == 0 {
            let insertStatement = metadata.map { "\"\($0.0)\"" }.joinWithSeparator(", ")
            let valuesStatement = metadata.map { ":\($0.0)" }.joinWithSeparator(", ")
            guard context.executeUpdate("INSERT INTO \"\(WalletMetadataEntity.tableName)\" (\(insertStatement)) VALUES (\(valuesStatement))", withParameterDictionary: metadata) else {
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