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
        let orderStatement = "\"\(WalletAccountEntity.indexKey)\" ASC"
        return fetchAccounts(orderStatement: orderStatement, context: context)
    }
    
    class func fetchAccountAtIndex(index: Int, context: SQLiteStoreContext) -> WalletAccount? {
        guard let accounts = fetchAccountsAtIndexes([index], context: context) where accounts.count > 0 else { return nil }
        return accounts[0]
    }
    
    class func fetchAccountsAtIndexes(indexes: [Int], context: SQLiteStoreContext) -> [WalletAccount]? {
        guard indexes.count > 0 else { return [] }
        
        let inStatement = indexes.map({ return "\($0)" }).joinWithSeparator(", ")
        let whereStatement = "\"\(WalletAccountEntity.indexKey)\" IN (\(inStatement))"
        return fetchAccounts(whereStatement: whereStatement, context: context)
    }
    
    class func fetchAllVisibleAccountsFrom(from: Int, size: Int, order: WalletFetchRequestOrder, context: SQLiteStoreContext) -> [WalletAccount]? {
        let whereStatement = "(\"\(WalletAccountEntity.nextInternalIndexKey)\" > 0 OR \"\(WalletAccountEntity.nextExternalIndexKey)\" > 0) AND \"\(WalletAccountEntity.hiddenKey)\" = 0"
        let orderStatement = "\"\(WalletAccountEntity.indexKey)\" " + order.representativeStatement
        return fetchAccounts(whereStatement: whereStatement, orderStatement: orderStatement, context: context)
    }
    
    class func countAllVisibleAccounts(context: SQLiteStoreContext) -> Int? {
        let whereStatement = "(\"\(WalletAccountEntity.nextInternalIndexKey)\" > 0 OR \"\(WalletAccountEntity.nextExternalIndexKey)\" > 0) AND \"\(WalletAccountEntity.hiddenKey)\" = 0"
        return countAccounts(whereStatement: whereStatement, context: context)
    }
    
    private class func fetchAccounts(whereStatement whereStatement: String? = nil, orderStatement: String? = nil, context: SQLiteStoreContext) -> [WalletAccount]? {
        let fieldsStatement = "\"\(WalletAccountEntity.indexKey)\", \"\(WalletAccountEntity.nameKey)\", \"\(WalletAccountEntity.extendedPublicKeyKey)\", \"\(WalletAccountEntity.nextInternalIndexKey)\", \"\(WalletAccountEntity.nextExternalIndexKey)\", \"\(WalletAccountEntity.hiddenKey)\", \"\(WalletAccountEntity.balanceKey)\""
        var statement = "SELECT \(fieldsStatement) FROM \"\(WalletAccountEntity.tableName)\""
        if let whereStatement = whereStatement { statement += " WHERE \(whereStatement)" }
        if let orderStatement = orderStatement { statement += " ORDER BY \(orderStatement)" }
        return fetchModelCollection(statement, context: context)
    }
    
    private class func countAccounts(whereStatement whereStatement: String? = nil, context: SQLiteStoreContext) -> Int? {
        var statement = "SELECT COUNT(*) FROM \"\(WalletAccountEntity.tableName)\""
        if let whereStatement = whereStatement { statement += " WHERE \(whereStatement)" }
        return countModelCollection(statement, context: context)
    }

    class func addAccount(account: WalletAccount, context: SQLiteStoreContext) -> Bool {
        let fieldsStatement = "(\"\(WalletAccountEntity.indexKey)\", \"\(WalletAccountEntity.nameKey)\", \"\(WalletAccountEntity.extendedPublicKeyKey)\", \"\(WalletAccountEntity.nextExternalIndexKey)\", \"\(WalletAccountEntity.nextInternalIndexKey)\", \"\(WalletAccountEntity.hiddenKey)\", \"\(WalletAccountEntity.balanceKey)\")"
        let statement = "INSERT INTO \"\(WalletAccountEntity.tableName)\" \(fieldsStatement) VALUES (?, ?, ?, ?, ?, ?, ?)"
        let values = [
            account.index,
            account.name ?? NSNull(),
            account.extendedPublicKey,
            account.nextExternalIndex,
            account.nextInternalIndex,
            account.hidden,
            NSNumber(longLong: account.balance)
        ]
        guard context.executeUpdate(statement, withArgumentsInArray: values) else {
            logger.error("Unable to insert account: \(context.lastErrorMessage())")
            return false
        }
        return true
    }
    
    // MARK: Layout management
    
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
    
    // MARK: Balances management

    class func updateBalanceOfAccounts(accounts: [WalletAccount], context: SQLiteStoreContext) -> Bool {
        guard accounts.count > 0 else { return true }
        
        return accounts.reduce(true) { current, account in
            guard let receivedAmount = fetchTotalReceivedAmountOfAccountAtIndex(account.index, context: context) else { return false }
            guard let sentAmount = fetchTotalSentAmountOfAccountAtIndex(account.index, context: context) else { return false }
            return current && setBalance(receivedAmount - sentAmount, ofAccountAtIndex: account.index, context: context)
        }
    }
    
    private class func setBalance(balance: Int64, ofAccountAtIndex index: Int, context: SQLiteStoreContext) -> Bool {
        let statement = "UPDATE \"\(WalletAccountEntity.tableName)\" SET \"\(WalletAccountEntity.balanceKey)\" = ? WHERE \"\(WalletAccountEntity.indexKey)\" = ?"
        guard context.executeUpdate(statement, withArgumentsInArray: [NSNumber(longLong: balance), index]) else {
            logger.error("Unable to set balance for account at index \(index): \(context.lastErrorMessage())")
            return false
        }
        return true
    }
    
    private class func fetchTotalReceivedAmountOfAccountAtIndex(index: Int, context: SQLiteStoreContext) -> Int64? {
        let statement = "SELECT IFNULL((SELECT SUM(\"to\".\"\(WalletTransactionOutputEntity.valueKey)\") FROM \"\(WalletTransactionOutputEntity.tableName)\" AS \"to\" INNER JOIN \"\(WalletAddressEntity.tableName)\" AS a ON \"to\".\"\(WalletTransactionOutputEntity.addressKey)\" = a.\"\(WalletAddressEntity.addressKey)\" WHERE a.\"\(WalletAddressEntity.accountIndexKey)\" = ? AND \"to\".\"\(WalletTransactionOutputEntity.transactionHashKey)\" NOT IN (SELECT DISTINCT \"\(WalletDoubleSpendConflictEntity.leftTransactionHashKey)\" FROM \"\(WalletDoubleSpendConflictEntity.tableName)\")), 0) AS \"\(WalletAccountEntity.balanceKey)\""
        guard let results = context.executeQuery(statement, withArgumentsInArray: [index]) where results.next() && !results.columnIsNull(WalletAccountEntity.balanceKey) else {
            logger.error("Unable to compute total received amount of account at index \(index): \(context.lastErrorMessage())")
            return nil
        }
        return results.longLongIntForColumn(WalletAccountEntity.balanceKey)
    }

    private class func fetchTotalSentAmountOfAccountAtIndex(index: Int, context: SQLiteStoreContext) -> Int64? {
        let statement = "SELECT IFNULL((SELECT SUM(\"ti\".\"\(WalletTransactionInputEntity.valueKey)\") FROM \"\(WalletTransactionInputEntity.tableName)\" AS \"ti\" INNER JOIN \"\(WalletAddressEntity.tableName)\" AS a ON \"ti\".\"\(WalletTransactionInputEntity.addressKey)\" = a.\"\(WalletAddressEntity.addressKey)\" WHERE a.\"\(WalletAddressEntity.accountIndexKey)\" = ? AND \"ti\".\"\(WalletTransactionInputEntity.transactionHashKey)\" NOT IN (SELECT DISTINCT \"\(WalletDoubleSpendConflictEntity.leftTransactionHashKey)\" FROM \"\(WalletDoubleSpendConflictEntity.tableName)\")), 0) AS \"\(WalletAccountEntity.balanceKey)\""
        guard let results = context.executeQuery(statement, withArgumentsInArray: [index]) where results.next() && !results.columnIsNull(WalletAccountEntity.balanceKey) else {
            logger.error("Unable to compute total sent amount of account at index \(index): \(context.lastErrorMessage())")
            return nil
        }
        return results.longLongIntForColumn(WalletAccountEntity.balanceKey)
    }

    // MARK: Addresses management
    
    class func fetchAddressesAtPaths(paths: [WalletAddressPath], context: SQLiteStoreContext) -> [WalletAddress]? {
        guard paths.count > 0 else { return [] }
        
        let inStatement = paths.map({ return "\"\($0.relativePath)\"" }).joinWithSeparator(", ")
        let concatStatement = "('/' || \"\(WalletAddressEntity.accountIndexKey)\" || '''/' || \"\(WalletAddressEntity.chainIndexKey)\" || '/' || \"\(WalletAddressEntity.keyIndexKey)\")"
        let whereStatement = "\(concatStatement) IN (\(inStatement))"
        return fetchAddresses(whereStatement: whereStatement, context: context)
    }
    
    class func fetchAddressesWithAddresses(addresses: [String], context: SQLiteStoreContext) -> [WalletAddress]? {
        guard addresses.count > 0 else { return [] }

        let inStatement = addresses.map({ return "\"\($0)\"" }).joinWithSeparator(", ")
        let whereStatement = "\"\(WalletAddressEntity.addressKey)\" IN (\(inStatement))"
        return fetchAddresses(whereStatement: whereStatement, context: context)
    }
    
    private class func fetchAddresses(whereStatement whereStatement: String? = nil, context: SQLiteStoreContext) -> [WalletAddress]? {
        let fieldsStatement = "\"\(WalletAddressEntity.addressKey)\", \"\(WalletAddressEntity.accountIndexKey)\", \"\(WalletAddressEntity.chainIndexKey)\", \"\(WalletAddressEntity.keyIndexKey)\""
        var statement = "SELECT \(fieldsStatement) FROM \"\(WalletAddressEntity.tableName)\""
        if let whereStatement = whereStatement { statement += " WHERE \(whereStatement)" }
        return fetchModelCollection(statement, context: context)
    }
    
    class func addAddresses(addresses: [WalletAddress], context: SQLiteStoreContext) -> Bool {
        guard addresses.count > 0 else { return true }
        return addresses.reduce(true) { $0 && addAddress($1, context: context) }
    }
    
    private class func addAddress(address: WalletAddress, context: SQLiteStoreContext) -> Bool {
        guard fetchAddressWithAddress(address.address, context: context) == nil else { return true }
        guard fetchAddressAtPath(address.path, context: context) == nil else { return true }
        
        let fieldsStatement = "(\"\(WalletAddressEntity.accountIndexKey)\", \"\(WalletAddressEntity.chainIndexKey)\", \"\(WalletAddressEntity.keyIndexKey)\", \"\(WalletAddressEntity.addressKey)\")"
        let statement = "INSERT INTO \"\(WalletAddressEntity.tableName)\" \(fieldsStatement) VALUES (?, ?, ?, ?)"
        let values: [AnyObject] = [
            address.path.accountIndex,
            address.path.chainIndex,
            address.path.keyIndex,
            address.address
        ]
        guard context.executeUpdate(statement, withArgumentsInArray: values) else {
            logger.error("Unable to insert address: \(context.lastErrorMessage())")
            return false
        }
        return true
    }
    
    private class func fetchAddressAtPath(path: WalletAddressPath, context: SQLiteStoreContext) -> WalletAddress? {
        guard let results = fetchAddressesAtPaths([path], context: context) where results.count >= 1 else { return nil }
        return results[0]
    }
    
    private class func fetchAddressWithAddress(address: String, context: SQLiteStoreContext) -> WalletAddress? {
        guard let results = fetchAddressesWithAddresses([address], context: context) where results.count >= 1 else { return nil }
        return results[0]
    }
    
    // MARK: Blocks management
    
    class func addBlocks(blocks: [WalletBlock], context: SQLiteStoreContext) -> Bool {
        guard blocks.count > 0 else { return true }
        return blocks.reduce(true) { $0 && addBlock($1, context: context) }
    }
    
    private class func addBlock(block: WalletBlock, context: SQLiteStoreContext) -> Bool {
        guard fetchBlockWithHash(block.hash, context: context) == nil else { return true }
        
        let fieldsStatement = "\"\(WalletBlockEntity.hashKey)\", \"\(WalletBlockEntity.heightKey)\", \"\(WalletBlockEntity.timeKey)\""
        let insertValues: [AnyObject] = [
            block.hash,
            block.height,
            block.time
        ]
        let insertStatement = "INSERT INTO \"\(WalletBlockEntity.tableName)\" (\(fieldsStatement)) VALUES (?, ?, ?)"
        guard context.executeUpdate(insertStatement, withArgumentsInArray: insertValues) else {
            logger.error("Unable to insert block \(block.hash): \(context.lastErrorMessage())")
            return false
        }
        return true
    }
    
    private class func fetchBlockWithHash(hash: String, context: SQLiteStoreContext) -> WalletBlock? {
        guard let results = fetchBlocksWithHashes([hash], context: context) where results.count > 0 else {
            return nil
        }
        return results[0]
    }
    
    private class func fetchBlocksWithHashes(hashes: [String], context: SQLiteStoreContext) -> [WalletBlock]? {
        let inStatement = hashes.map({ return "\"" + $0 + "\"" }).joinWithSeparator(", ")
        let whereStatement = "\"\(WalletBlockEntity.hashKey)\" IN (\(inStatement))"
        return fetchBlocks(whereStatement, values: hashes, context: context)
    }
    
    private class func fetchBlocks(whereStatement: String? = nil, values: [AnyObject]? = nil, context: SQLiteStoreContext) -> [WalletBlock]? {
        let fieldsStatement = "\"\(WalletBlockEntity.hashKey)\", \"\(WalletBlockEntity.heightKey)\", \"\(WalletBlockEntity.timeKey)\""
        var statement = "SELECT \(fieldsStatement) FROM \"\(WalletBlockEntity.tableName)\""
        if let whereStatement = whereStatement { statement += " WHERE \(whereStatement)" }
        return fetchModelCollection(statement, values: values, context: context)
    }
    
    // MARK: Transactions management
    
    class func storeTransactions(transactions: [WalletTransactionContainer], context: SQLiteStoreContext) -> Bool {
        guard transactions.count > 0 else { return true }
        return transactions.reduce(true) { $0 && storeTransaction($1, context: context) }
    }
    
    private class func storeTransaction(transaction: WalletTransactionContainer, context: SQLiteStoreContext) -> Bool {
        if let block = transaction.block {
            guard addBlock(block, context: context) else { return false }
        }
        
        let updateFieldsStatement = "\"\(WalletTransactionEntity.blockHashKey)\" = ?"
        let updateStatement = "UPDATE \"\(WalletTransactionEntity.tableName)\" SET \(updateFieldsStatement) WHERE \"\(WalletTransactionEntity.hashKey)\" = ?"
        let updateValues = [
            transaction.block?.hash ?? NSNull(),
            transaction.transaction.hash
        ]
        guard context.executeUpdate(updateStatement, withArgumentsInArray: updateValues) else {
            logger.error("Unable to update transaction \(transaction.transaction.hash): \(context.lastErrorMessage())")
            return false
        }
        if context.changes() == 0 {
            let insertFieldsStatement = "(\"\(WalletTransactionEntity.hashKey)\", \"\(WalletTransactionEntity.receptionDateKey)\", \"\(WalletTransactionEntity.lockTimeKey)\", \"\(WalletTransactionEntity.feesKey)\", \"\(WalletTransactionEntity.blockHashKey)\")"
            let insertStatement = "INSERT INTO \"\(WalletTransactionEntity.tableName)\" \(insertFieldsStatement) VALUES (?, ?, ?, ?, ?)"
            let insertValues = [
                transaction.transaction.hash,
                transaction.transaction.receiveAt,
                transaction.transaction.lockTime,
                NSNumber(longLong: transaction.transaction.fees),
                transaction.block?.hash ?? NSNull()
            ]
            guard context.executeUpdate(insertStatement, withArgumentsInArray: insertValues) else {
                logger.error("Unable to insert transaction \(transaction.transaction.hash): \(context.lastErrorMessage())")
                return false
            }
            guard addTransactionInputs(transaction.inputs, context: context) else { return false }
            guard addTransactionOutputs(transaction.outputs, context: context) else { return false }
        }
        return true
    }
    
    private class func addTransactionInputs(inputs: [WalletTransactionInputType], context: SQLiteStoreContext) -> Bool {
        guard inputs.count > 0 else { return true }
        
        for input in inputs {
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
                    input.transactionHash
                ]
            }
            else if let input = input as? WalletTransactionCoinbaseInput {
                insertValues = [
                    NSNull(),
                    NSNull(),
                    NSNull(),
                    NSNull(),
                    NSNull(),
                    true,
                    input.transactionHash
                ]
            }
            else {
                insertValues = []
            }
            
            guard insertValues.count > 0 else {
                logger.error("Unable to insert transaction input because input type is unknown")
                return false
            }
            
            let insertStatement = "INSERT INTO \"\(WalletTransactionInputEntity.tableName)\" \(insertFieldsStatement) VALUES (?, ?, ?, ?, ?, ?, ?)"
            guard context.executeUpdate(insertStatement, withArgumentsInArray: insertValues) else {
                logger.error("Unable to insert input for transaction \(insertValues.last!): \(context.lastErrorMessage())")
                return false
            }
        }
        return true
    }
    
    private class func addTransactionOutputs(outputs: [WalletTransactionOutput], context: SQLiteStoreContext) -> Bool {
        guard outputs.count > 0 else { return true }

        for output in outputs {
            let insertFieldsStatement = "(\"\(WalletTransactionOutputEntity.addressKey)\", \"\(WalletTransactionOutputEntity.scriptHexKey)\", \"\(WalletTransactionOutputEntity.valueKey)\", \"\(WalletTransactionOutputEntity.indexKey)\", \"\(WalletTransactionOutputEntity.transactionHashKey)\")"
            let insertValues = [
                output.address ?? NSNull(),
                output.scriptHex,
                NSNumber(longLong: output.value),
                output.index,
                output.transactionHash
            ]
            let insertStatement = "INSERT INTO \"\(WalletTransactionOutputEntity.tableName)\" \(insertFieldsStatement) VALUES (?, ?, ?, ?, ?)"
            guard context.executeUpdate(insertStatement, withArgumentsInArray: insertValues) else {
                logger.error("Unable to insert output for transaction \(output.transactionHash): \(context.lastErrorMessage())")
                return false
            }
        }
        return true
    }
    
    class func fetchTransactionsDoubleSpendingWithTransaction(transaction: WalletTransactionContainer, context: SQLiteStoreContext) -> [WalletTransaction]? {
        guard transaction.regularInputs.count > 0 else { return [] }
        
        let inStatement = transaction.regularInputs.map({ "\"\($0.uid)\"" }).joinWithSeparator(", ")
        let statement = "SELECT DISTINCT t.* FROM \"\(WalletTransactionInputEntity.tableName)\" AS ti INNER JOIN \"\(WalletTransactionEntity.tableName)\" AS t ON ti.\"\(WalletTransactionInputEntity.transactionHashKey)\" = t.\"\(WalletTransactionEntity.hashKey)\" WHERE ti.\"\(WalletTransactionInputEntity.outputHashKey)\" || '-' || ti.\"\(WalletTransactionInputEntity.outputIndexKey)\" IN (\(inStatement)) AND t.\"\(WalletTransactionEntity.hashKey)\" IS NOT ?"
        return fetchModelCollection(statement, values: [transaction.transaction.hash], context: context)
    }

    class func fetchTransactionsToResolveFromConflictsOfTransaction(transaction: WalletTransaction, context: SQLiteStoreContext) -> [WalletTransaction]? {
        let statement = "SELECT t.* FROM \"\(WalletDoubleSpendConflictEntity.tableName)\" AS dsc INNER JOIN \"\(WalletTransactionEntity.tableName)\" AS t ON dsc.\"\(WalletDoubleSpendConflictEntity.rightTransactionHashKey)\" = t.\"\(WalletTransactionEntity.hashKey)\" WHERE dsc.\"\(WalletDoubleSpendConflictEntity.leftTransactionHashKey)\" = ?"
        return fetchModelCollection(statement, values: [transaction.hash], context: context)
    }
    
    class func removeTransactions(transactions: [WalletTransaction], context: SQLiteStoreContext) -> Bool {
        let inStatement = transactions.map({ return "\"\($0.hash)\"" }).joinWithSeparator(", ")
        let statement = "DELETE FROM \"\(WalletTransactionEntity.tableName)\" WHERE \"\(WalletTransactionEntity.hashKey)\" IN (\(inStatement))"
        guard context.executeUpdate(statement, withArgumentsInArray: nil) else {
            logger.error("Unable to remove transactions: \(context.lastErrorMessage())")
            return false
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

    // MARK: Double spend conflicts management
    
    class func addDoubleSpendConflicts(conflicts: [WalletDoubleSpendConflict], context: SQLiteStoreContext) -> Bool {
        guard conflicts.count > 0 else { return true }
        return conflicts.reduce(true, combine: { $0 && addDoubleSpendConflict($1, context: context) })
    }
    
    private class func addDoubleSpendConflict(conflict: WalletDoubleSpendConflict, context: SQLiteStoreContext) -> Bool {
        guard fetchDoubleSpendConflict(conflict, context: context) == nil else { return true }
        
        let fieldsStatement = "\"\(WalletDoubleSpendConflictEntity.leftTransactionHashKey)\", \"\(WalletDoubleSpendConflictEntity.rightTransactionHashKey)\""
        let statement = "INSERT INTO \"\(WalletDoubleSpendConflictEntity.tableName)\" (\(fieldsStatement)) VALUES (?, ?)"
        let values = [conflict.leftTransactionHash, conflict.rightTransactionHash]
        guard context.executeUpdate(statement, withArgumentsInArray: values) else {
            logger.error("Unable to insert double spend conflict \(conflict.leftTransactionHash) <-> \(conflict.rightTransactionHash): \(context.lastErrorMessage())")
            return false
        }
        return true
    }
    
    private class func fetchDoubleSpendConflict(conflict: WalletDoubleSpendConflict, context: SQLiteStoreContext) -> WalletDoubleSpendConflict? {
        let whereStatement = "\"\(WalletDoubleSpendConflictEntity.leftTransactionHashKey)\" = ? AND \"\(WalletDoubleSpendConflictEntity.rightTransactionHashKey)\" = ?"
        guard let results = fetchDoubleSpendConflicts(whereStatement, values: [conflict.leftTransactionHash, conflict.rightTransactionHash], context: context) where results.count > 0 else {
            return nil
        }
        return results[0]
    }
    
    private class func fetchDoubleSpendConflicts(whereStatement: String? = nil, values: [AnyObject]? = nil, context: SQLiteStoreContext) -> [WalletDoubleSpendConflict]? {
        let fieldsStatement = "\"\(WalletDoubleSpendConflictEntity.leftTransactionHashKey)\", \"\(WalletDoubleSpendConflictEntity.rightTransactionHashKey)\""
        var statement = "SELECT \(fieldsStatement) FROM \"\(WalletDoubleSpendConflictEntity.tableName)\""
        if let whereStatement = whereStatement { statement += " WHERE \(whereStatement)" }
        return fetchModelCollection(statement, values: values, context: context)
    }
    
    // MARK: Schema management
    
    class func schemaVersion(context: SQLiteStoreContext) -> Int? {
        guard let results = context.executeQuery("SELECT \(WalletMetadataEntity.schemaVersionKey) FROM \(WalletMetadataEntity.tableName)", withArgumentsInArray: nil) else {
            logger.warn("Unable to fetch schema version: \(context.lastErrorMessage())")
            return nil
        }
        guard results.next() && !results.columnIsNull(WalletMetadataEntity.schemaVersionKey) else {
            logger.error("Unable to fetch schema version: no row")
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
    
    private class func countModelCollection(statement: String, values: [AnyObject]? = nil, context: SQLiteStoreContext) -> Int? {
        guard let results = context.executeQuery(statement, withArgumentsInArray: values) else {
            logger.error("Unable to count model collection: \(context.lastErrorMessage())")
            return nil
        }
        guard results.next() else {
            return nil
        }
        guard let count = results.objectForColumnIndex(0) where count is NSNumber else {
            logger.error("Unable to count model collection: column 0 is not a number")
            return nil
        }
        let number = count as! NSNumber
        return number.integerValue
    }

}