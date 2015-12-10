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

    // MARK: - Accounts management
    
    class func allAccounts(context: SQLiteStoreContext) -> [WalletAccountModel]? {
        let fieldsStatement = "\"\(WalletAccountTableEntity.indexKey)\", \"\(WalletAccountTableEntity.nameKey)\", \"\(WalletAccountTableEntity.extendedPublicKeyKey)\", \"\(WalletAccountTableEntity.nextInternalIndexKey)\", \"\(WalletAccountTableEntity.nextExternalIndexKey)\""
        let statement = "SELECT \(fieldsStatement) FROM \"\(WalletAccountTableEntity.tableName)\" ORDER BY \"\(WalletAccountTableEntity.indexKey)\" ASC"
        return fetchModelCollection(statement, context: context)
    }
    
    class func accountAtIndex(index: Int, context: SQLiteStoreContext) -> WalletAccountModel? {
        let fieldsStatement = "\"\(WalletAccountTableEntity.indexKey)\", \"\(WalletAccountTableEntity.nameKey)\", \"\(WalletAccountTableEntity.extendedPublicKeyKey)\", \"\(WalletAccountTableEntity.nextInternalIndexKey)\", \"\(WalletAccountTableEntity.nextExternalIndexKey)\""
        let statement = "SELECT \(fieldsStatement) FROM \"\(WalletAccountTableEntity.tableName)\" WHERE \"\(WalletAccountTableEntity.indexKey)\" = ?"
        return fetchModel(statement, values: [index], context: context)
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
    
    // MARK: - Addresses management
    
    class func addressesAtPath(paths: [WalletAddressPath], context: SQLiteStoreContext) -> [WalletAddressModel]? {
        let inStatement = paths.map({ return "\"\($0.relativePath)\"" }).joinWithSeparator(", ")
        let concatStatement = "('/' || \"\(WalletAddressTableEntity.accountIndexKey)\" || '''/' || \"\(WalletAddressTableEntity.chainIndexKey)\" || '/' || \"\(WalletAddressTableEntity.keyIndexKey)\") AS path"
        let fieldsStatement = "\"\(WalletAddressTableEntity.addressKey)\", \"\(WalletAddressTableEntity.accountIndexKey)\", \"\(WalletAddressTableEntity.chainIndexKey)\", \"\(WalletAddressTableEntity.keyIndexKey)\""
        let statement = "SELECT \(fieldsStatement), \(concatStatement) FROM \"\(WalletAddressTableEntity.tableName)\" WHERE path IN (\(inStatement))"
        return fetchModelCollection(statement, context: context)
    }
    
    class func addressWithAddress(address: String, context: SQLiteStoreContext) -> WalletAddressModel? {
        let fieldsStatement = "\"\(WalletAddressTableEntity.addressKey)\", \"\(WalletAddressTableEntity.accountIndexKey)\", \"\(WalletAddressTableEntity.chainIndexKey)\", \"\(WalletAddressTableEntity.keyIndexKey)\""
        let statement = "SELECT \(fieldsStatement) FROM \"\(WalletAddressTableEntity.tableName)\" WHERE \"\(WalletAddressTableEntity.addressKey)\" = ?"
        return fetchModel(statement, values: [address], context: context)
    }
    
    class func addAddress(address: WalletAddressModel, context: SQLiteStoreContext) -> Bool {
        guard addressWithAddress(address.address, context: context) == nil else { return true }
        
        let fieldsStatement = "(\"\(WalletAddressTableEntity.accountIndexKey)\", \"\(WalletAddressTableEntity.chainIndexKey)\", \"\(WalletAddressTableEntity.keyIndexKey)\", \"\(WalletAddressTableEntity.addressKey)\")"
        let statement = "INSERT INTO \"\(WalletAddressTableEntity.tableName)\" \(fieldsStatement) VALUES (?, ?, ?, ?)"
        let values: [AnyObject] = [address.accountIndex, address.chainIndex, address.keyIndex, address.address]
        guard context.executeUpdate(statement, withArgumentsInArray: values) else {
            logger.error("Unable to insert address: \(context.lastErrorMessage())")
            return false
        }
        return true
    }
    
    class func addAddresses(addresses: [WalletAddressModel], context: SQLiteStoreContext) -> Bool {
        for address in addresses {
            guard addAddress(address, context: context) else {
                return false
            }
        }
        return true
    }
    
    // MARK: - Schema management
    
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
            logger.error("Unabel to fetch schema version: value is <= 0")
            return nil
        }
        return version
    }

    class func storeMetadata(metadata: [String: AnyObject], context: SQLiteStoreContext) -> Bool {
        let updateStatement = metadata.map { return "\"\($0.0)\" = :\($0.0)" }.joinWithSeparator(", ")
        guard context.executeUpdate("UPDATE \(WalletMetadataTableEntity.tableName) SET \(updateStatement)", withParameterDictionary: metadata) else {
            logger.error("Unable to set database metadata \(metadata): \(context.lastErrorMessage())")
            return false
        }
        if context.changes() == 0 {
            let insertStatement = metadata.map { "\"\($0.0)\"" }.joinWithSeparator(", ")
            let valuesStatement = metadata.map { ":\($0.0)" }.joinWithSeparator(", ")
            guard context.executeUpdate("INSERT INTO \(WalletMetadataTableEntity.tableName) (\(insertStatement)) VALUES (\(valuesStatement))", withParameterDictionary: metadata) else {
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
    
    // MARK: - Internal methods
    
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