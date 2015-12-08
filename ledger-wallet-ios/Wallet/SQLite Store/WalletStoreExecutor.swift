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
    
    class func accountAtIndex(index: Int, context: SQLiteStoreContext) -> WalletAccount? {
        let statement = "SELECT \"\(AccountEntity.indexKey)\", \"\(AccountEntity.extendedPublicKeyKey)\" FROM \"\(AccountEntity.tableName)\" WHERE \"\(AccountEntity.indexKey)\" = ?"
        return fetchModel(statement, [index], context: context)
    }
    
    // MARK: - Addresses management
    
    class func addressesAtPath(paths: [WalletAddressPath], context: SQLiteStoreContext) -> [WalletAddress]? {
        let inStatement = paths.map({ return "\"\($0.relativePath)\"" }).joinWithSeparator(", ")
        let concatStatement = "('/' || \"\(AddressEntity.accountIndexKey)\" || '''/' || \"\(AddressEntity.chainIndexKey)\" || '/' || \"\(AddressEntity.keyIndexKey)\") AS v"
        let fieldsStatement = "\"\(AddressEntity.accountIndexKey)\", \"\(AddressEntity.chainIndexKey)\", \"\(AddressEntity.keyIndexKey)\", \"\(AddressEntity.addressKey)\""
        let statement = "SELECT \(fieldsStatement), \(concatStatement) FROM \"\(AddressEntity.tableName)\" WHERE v IN (\(inStatement))"
        return fetchModelCollection(statement, context: context)
    }
    
    class func storeAddresses(addresses: [WalletAddress], context: SQLiteStoreContext) -> Bool {
        for address in addresses {
            // check that address is missing
            let updateStatement = "SELECT COUNT(*) as v FROM \"\(AddressEntity.tableName)\" WHERE \"\(AddressEntity.addressKey)\" = ?"
            guard let results = context.executeQuery(updateStatement, withArgumentsInArray: [address.address]) where results.next() else {
                logger.error("Unable to retreive address: \(context.lastErrorMessage())")
                return false
            }
            if results.longForColumn("v") <= 0 {
                // insert it
                let insertStatement = "INSERT INTO \"\(AddressEntity.tableName)\" (\"\(AddressEntity.accountIndexKey)\", \"\(AddressEntity.chainIndexKey)\", \"\(AddressEntity.keyIndexKey)\", \"\(AddressEntity.addressKey)\") VALUES (?, ?, ?, ?)"
                let values: [AnyObject] = [address.accountIndex, address.chainIndex, address.keyIndex, address.address]
                guard context.executeUpdate(insertStatement, withArgumentsInArray: values) else {
                    logger.error("Unable to store address: \(context.lastErrorMessage())")
                    return false
                }
            }
        }
        return true
    }
    
    // MARK: - Schema management
    
    class func schemaVersion(context: SQLiteStoreContext) -> Int? {
        guard let results = context.executeQuery("SELECT \(MetadataEntity.schemaVersionKey) FROM \(MetadataEntity.tableName)", withArgumentsInArray: nil) else {
            logger.warn("Unable to fetch schema version: \(context.lastErrorMessage())")
            return nil
        }
        guard results.next() && !results.columnIsNull(MetadataEntity.schemaVersionKey) else {
            logger.warn("Unable to fetch schema version: no row")
            return nil
        }
        let version = results.longForColumn(MetadataEntity.schemaVersionKey)
        guard version > 0 else {
            logger.error("Unabel to fetch schema version: value is <= 0")
            return nil
        }
        return version
    }

    class func setMetadata(metadata: [String: AnyObject], context: SQLiteStoreContext) -> Bool {
        let updateStatement = metadata.map { return "\"\($0.0)\" = :\($0.0)" }.joinWithSeparator(", ")
        guard context.executeUpdate("UPDATE \(MetadataEntity.tableName) SET \(updateStatement)", withParameterDictionary: metadata) else {
            logger.error("Unable to set database metadata \(metadata): \(context.lastErrorMessage())")
            return false
        }
        if context.changes() == 0 {
            let insertStatement = metadata.map { "\"\($0.0)\"" }.joinWithSeparator(", ")
            let valuesStatement = metadata.map { ":\($0.0)" }.joinWithSeparator(", ")
            guard context.executeUpdate("INSERT INTO \(MetadataEntity.tableName) (\(insertStatement)) VALUES (\(valuesStatement))", withParameterDictionary: metadata) else {
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
    
    private class func fetchModel<T: SQLiteFetchableModel>(statement: String, _ values: [AnyObject]? = nil, context: SQLiteStoreContext) -> T? {
        guard let results = context.executeQuery(statement, withArgumentsInArray: values) else {
            logger.error("Unable to fetch model of type \(T.self): \(context.lastErrorMessage())")
            return nil
        }
        guard results.next() else {
            return nil
        }
        return T.init(resultSet: results)
    }
    
    private class func fetchModelCollection<T: SQLiteFetchableModel>(statement: String, _ values: [AnyObject]? = nil, context: SQLiteStoreContext) -> [T]? {
        guard let results = context.executeQuery(statement, withArgumentsInArray: values) else {
            logger.error("Unable to fetch model collection of type \(T.self): \(context.lastErrorMessage())")
            return nil
        }
        return T.collectionFromResultSet(results)
    }
}