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
    
    func fetchDiscoverableAccounts(completion: [WalletDiscoverableAccount] -> Void) {
        let statement = "SELECT \"\(AccountEntity.indexKey)\", \(AccountEntity.nextExternalIndexKey), \(AccountEntity.nextInternalIndexKey), \(AccountEntity.extendedPublicKeyKey) FROM \(AccountEntity.tableName) ORDER BY \"\(AccountEntity.indexKey)\" ASC"
        fetchCollection(statement, completion: completion)
    }
    
    // MARK: Addresses management
    
    func fetchAddressForAccountIndex(accountIndex: Int, chainIndex: Int, keyIndex: Int, completion: WalletAddress? -> Void) {
        let statement = "SELECT "
        fetchModel(statement, completion: completion)
    }
    
    // MARK: Metadata management
    
    func executePragmaCommands(statements: [String]) {
        store.performBlock() { [weak self] database in
            guard let strongSelf = self else { return }

            for statement in statements {
                guard let _ = database.executeQuery(statement) else {
                    strongSelf.logger.error("Unable to execute pragma command \"\(statement)\": \(database.lastErrorMessage())")
                    return
                }
            }
        }
    }
    
    func fetchSchemaVersion(completion: (Int?) -> Void) {
        store.performBlock() { [weak self] database in
            guard let strongSelf = self else { return }
            
            guard let results = database.executeQuery("SELECT \(MetadataEntity.schemaVersionKey) FROM \(MetadataEntity.tableName)") else {
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
                guard database.executeUpdate(statement) else {
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
    
    // MARK: Utils
    
    private func fetchModel<T: SQLiteFetchableModel>(statement: String, completion: (T?) -> Void) {
        store.performBlock() { [weak self] database in
            guard let strongSelf = self else {
                dispatchAsyncOnMainQueue { completion(nil) }
                return
            }
            
            guard let results = database.executeQuery(statement) else {
                strongSelf.logger.error("Unable to fetch model of type \(T.self): \(database.lastErrorMessage())")
                dispatchAsyncOnMainQueue { completion(nil) }
                return
            }
            dispatchAsyncOnMainQueue { completion(T.init(resultSet: results)) }
        }
    }
    
    private func fetchCollection<T: SQLiteFetchableModel>(statement: String, completion: ([T]) -> Void) {
        store.performBlock() { [weak self] database in
            guard let strongSelf = self else {
                dispatchAsyncOnMainQueue { completion([]) }
                return
            }
            
            guard let results = database.executeQuery(statement) else {
                strongSelf.logger.error("Unable to fetch collection of type \(T.self): \(database.lastErrorMessage())")
                dispatchAsyncOnMainQueue { completion([]) }
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