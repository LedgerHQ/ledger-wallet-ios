//
//  WalletStoreManager.swift
//  ledger-wallet-ios
//
//  Created by Nicolas Bigot on 27/11/2015.
//  Copyright © 2015 Ledger. All rights reserved.
//

import Foundation

final class WalletStoreManager {
    
    private let logger = Logger.sharedInstance(name: "WalletStoreManager")
    
    // MARK: Convenience method
    
    func manageStoreAtURL(URL: NSURL?) -> SQLiteStore {
        let store = SQLiteStore(URL: URL)
        let schema = WalletStoreSchemas.version1()
        executePragmaCommands(store, schema: schema)
        checkForSchemaMigration(store, schema: schema)
        return store
    }
    
    // MARK: Schema installation
    
    private func executePragmaCommands(store: SQLiteStore, schema: SQLiteSchema) {
        let statements = schema.executablePragmaCommands
        store.performBlock() { database in
            self.logger.info("Executing pragma commands")
            for statement in statements {
                guard let _ = database.executeQuery(statement) else {
                    self.logger.error("Unable to execute pragma command \"\(statement)\": \(database.lastErrorMessage())")
                    return
                }
            }
        }
    }
    
    private func checkForSchemaMigration(store: SQLiteStore, schema: SQLiteSchema) {
        store.performBlock() { database in
            self.logger.info("Checking store for schema migration")
            if let version = self.fetchDatabaseSchemaVersion(database) {
                self.logger.info("Store schema version \(version), current version \(schema.version)")
                if schema.version > version {
                    self.migrateFromSchemaWithVersion(version, toSchema: schema)
                }
            }
            else {
                self.logger.warn("Unable to get store schema version, creating tables")
                self.initializationStore(store, withSchema: schema)
            }
        }
    }
    
    private func initializationStore(store: SQLiteStore, withSchema schema: SQLiteSchema) {
        let statements = schema.executableStatements
        store.performTransaction() { database in
            self.logger.info("Initializing store with schema with version \(schema.version)")
            for statement in statements {
                guard database.executeUpdate(statement) else {
                    self.logger.error("Unable to create table \"\(statement)\": \(database.lastErrorMessage())")
                    return false
                }
            }
            guard self.setDatabaseSchemaVersion(database, version: schema.version) else {
                self.logger.error("Unable to set schema version to \(schema.version)")
                return false
            }
            return true
        }
    }
    
    private func migrateFromSchemaWithVersion(storeVersion: Int, toSchema schema: SQLiteSchema) {
        logger.info("Migrating from schema version \(storeVersion) to schema version \(schema.version)")
        // TODO: mark current schema version
    }
    
    private func fetchDatabaseSchemaVersion(database: FMDatabase) -> Int? {
        guard let results = database.executeQuery("SELECT \(MetadataEntity.schemaVersionKey) FROM \(MetadataEntity.tableName)") where results.next() else {
            return nil
        }
        let version = results.longForColumn(MetadataEntity.schemaVersionKey)
        return (version > 0 ? version : nil)
    }
    
    private func setDatabaseSchemaVersion(database: FMDatabase, version: Int) -> Bool {
        guard database.executeUpdate("UPDATE \(MetadataEntity.tableName) SET \(MetadataEntity.schemaVersionKey) = ?", version) else {
            return false
        }
        if database.changes() == 0 {
            guard database.executeUpdate("INSERT INTO \(MetadataEntity.tableName) (\(MetadataEntity.schemaVersionKey)) VALUES (?)", version) else {
                return false
            }
            return database.changes() == 1
        }
        else {
            return database.changes() == 1
        }
    }
    
}