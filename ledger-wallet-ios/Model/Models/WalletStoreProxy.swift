//
//  WalletStoreProxy.swift
//  ledger-wallet-ios
//
//  Created by Nicolas Bigot on 02/12/2015.
//  Copyright © 2015 Ledger. All rights reserved.
//

import Foundation

final class WalletStoreProxy {
    
    private let store: SQLiteStore
    private let logger = Logger.sharedInstance(name: "WalletStoreProxy")
    
    // MARK: Accounts management
    
    func fetchDiscoverableAccountWithIndex(index: Int, completion: (WalletDiscoverableAccount?) -> Void) {
        let statement = "SELECT \"\(AccountEntity.indexKey)\", \"\(AccountEntity.extendedPublicKeyKey)\" FROM \"\(AccountEntity.tableName)\" WHERE \"\(AccountEntity.indexKey)\" = ?"
        fetchModel(statement, index, completion: completion)
    }

    // MARK: Addresses management
    
    func fetchAddressesWithPaths(paths: [WalletAddressPath], completion: ([WalletCacheAddress]?) -> Void) {
        let inStatement = paths.map({ return "\"\($0.relativePath)\"" }).joinWithSeparator(", ")
        let concatStatement = "('/' || \"\(AddressEntity.accountIndexKey)\" || '''/' || \"\(AddressEntity.chainIndexKey)\" || '/' || \"\(AddressEntity.keyIndexKey)\") AS v"
        let fieldsStatement = "\"\(AddressEntity.accountIndexKey)\", \"\(AddressEntity.chainIndexKey)\", \"\(AddressEntity.keyIndexKey)\", \"\(AddressEntity.addressKey)\""
        let statement = "SELECT \(fieldsStatement), \(concatStatement) FROM \"\(AddressEntity.tableName)\" WHERE v IN (\(inStatement))"
        fetchCollection(statement, completion: completion)
    }
    
    func storeAddresses(addresses: [WalletCacheAddress]) {
        store.performTransaction() { [weak self] database in
            guard let strongSelf = self else { return false }

            for address in addresses {
                // check that address is missing
                guard let results = database.executeQuery("SELECT COUNT(*) as v FROM \"\(AddressEntity.tableName)\" WHERE \"\(AddressEntity.addressKey)\" = ?", withArgumentsInArray: [address.address]) where results.next() else {
                    strongSelf.logger.error("Unable to retreive address: \(database.lastErrorMessage())")
                    return false
                }
                if results.longForColumn("v") <= 0 {
                    // insert it
                    let values: [AnyObject] = [address.accountIndex, address.chainIndex, address.keyIndex, address.address]
                    guard database.executeUpdate("INSERT INTO \"\(AddressEntity.tableName)\" (\"\(AddressEntity.accountIndexKey)\", \"\(AddressEntity.chainIndexKey)\", \"\(AddressEntity.keyIndexKey)\", \"\(AddressEntity.addressKey)\") VALUES (?, ?, ?, ?)", withArgumentsInArray: values) else {
                        strongSelf.logger.error("Unable to store address: \(database.lastErrorMessage())")
                        return false
                    }
                }
            }
            return true
        }
    }
    
    // MARK: Metadata management
    
    func executePragmaCommands(statements: [String]) {
        store.performBlock() { [weak self] database in
            guard let strongSelf = self else { return }

            for statement in statements {
                guard let _ = database.executeQuery(statement, withArgumentsInArray: nil) else {
                    strongSelf.logger.error("Unable to execute pragma command \"\(statement)\": \(database.lastErrorMessage())")
                    return
                }
            }
        }
    }
    
    func fetchSchemaVersion(completion: (Int?) -> Void) {
        store.performBlock() { [weak self] database in
            guard let strongSelf = self else { return }
            
            guard let results = database.executeQuery("SELECT \(MetadataEntity.schemaVersionKey) FROM \(MetadataEntity.tableName)", withArgumentsInArray: nil) else {
                strongSelf.logger.error("Unable to fetch store schema version: \(database.lastErrorMessage())")
                dispatchAsyncOnMainQueue() { completion(nil) }
                return
            }
            guard results.next() && !results.columnIsNull(MetadataEntity.schemaVersionKey) else {
                strongSelf.logger.warn("Unable to fetch schema version, no row")
                dispatchAsyncOnMainQueue() { completion(nil) }
                return
            }
            let version = results.longForColumn(MetadataEntity.schemaVersionKey)
            dispatchAsyncOnMainQueue() { completion(version > 0 ? version : nil) }
        }
    }
    
    func createTables(statements: [String]) {
        store.performTransaction() { [weak self] database in
            guard let strongSelf = self else { return false }

            for statement in statements {
                guard database.executeUpdate(statement, withArgumentsInArray: nil) else {
                    strongSelf.logger.error("Unable to create table \"\(statement)\": \(database.lastErrorMessage())")
                    return false
                }
            }
            return true
        }
    }
    
    func setMetadata(metadata: [String: AnyObject]) {
        store.performTransaction() { [weak self] database in
            guard let strongSelf = self else { return false }
            
            let updateStatement = metadata.map { return "\"\($0.0)\" = :\($0.0)" }.joinWithSeparator(", ")
            guard database.executeUpdate("UPDATE \(MetadataEntity.tableName) SET \(updateStatement)", withParameterDictionary: metadata) else {
                strongSelf.logger.error("Unable to set database metadata \(metadata): \(database.lastErrorMessage())")
                return false
            }
            if database.changes() == 0 {
                let insertStatement = metadata.map { "\"\($0.0)\"" }.joinWithSeparator(", ")
                let valuesStatement = metadata.map { ":\($0.0)" }.joinWithSeparator(", ")
                guard database.executeUpdate("INSERT INTO \(MetadataEntity.tableName) (\(insertStatement)) VALUES (\(valuesStatement))", withParameterDictionary: metadata) else {
                    strongSelf.logger.error("Unable to set database metadata \(metadata): \(database.lastErrorMessage())")
                    return false
                }
            }
            return true
        }
    }
    
    // MARK: Internal methods
    
    private func fetchModel<T: SQLiteFetchableModel>(statement: String, _ values: AnyObject..., completion: (T?) -> Void) {
        store.performBlock() { [weak self] database in
            guard let strongSelf = self else { return }
            
            guard let results = database.executeQuery(statement, withArgumentsInArray: values) else {
                strongSelf.logger.error("Unable to fetch model of type \(T.self): \(database.lastErrorMessage())")
                dispatchAsyncOnMainQueue { completion(nil) }
                return
            }
            guard results.next() else {
                dispatchAsyncOnMainQueue { completion(nil) }
                return
            }
            dispatchAsyncOnMainQueue { completion(T.init(resultSet: results)) }
        }
    }
    
    private func fetchCollection<T: SQLiteFetchableModel>(statement: String, _ values: AnyObject..., completion: ([T]?) -> Void) {
        store.performBlock() { [weak self] database in
            guard let strongSelf = self else { return }
            
            guard let results = database.executeQuery(statement, withArgumentsInArray: values) else {
                strongSelf.logger.error("Unable to fetch collection of type \(T.self): \(database.lastErrorMessage())")
                dispatchAsyncOnMainQueue { completion(nil) }
                return
            }
            dispatchAsyncOnMainQueue { completion(T.collectionFromSet(results)) }
        }
    }
    
    // MARK: Initialization
    
    init(store: SQLiteStore) {
        self.store = store
    }
    
}