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
    
    func storeProxyAtURL(URL: NSURL?, withUniqueIdentifier uniqueIdentifier: String) -> WalletStoreProxy {
        let store = SQLiteStore(URL: URL)
        let storeProxy = WalletStoreProxy(store: store, handlersQueue: dispatchMainQueue())
        
        if let schema = WalletStoreSchemas.currentSchema {
            executePragmaCommands(storeProxy, schema: schema)
            checkForSchemaMigration(storeProxy, schema: schema, uniqueIdentifier: uniqueIdentifier)
        }
        else {
            logger.error("Unable to get current schema")
        }
        return storeProxy
    }
    
    // MARK: Schema installation
    
    private func executePragmaCommands(storeProxy: WalletStoreProxy, schema: SQLiteSchema) {
        let statements = schema.executablePragmaCommands
        
        logger.info("Executing pragma commands")
        storeProxy.executePragmaCommands(statements)
    }
    
    private func checkForSchemaMigration(storeProxy: WalletStoreProxy, schema: SQLiteSchema, uniqueIdentifier: String) {
        logger.info("Checking store for schema migration")
        storeProxy.fetchSchemaVersion() { version in
            if let storeVersion = version {
                self.logger.info("Store schema version \(storeVersion), current version \(schema.version)")
                if schema.version > storeVersion {
                    self.migrateFromSchemaWithVersion(storeVersion, toSchema: schema)
                }
            }
            else {
                self.logger.warn("Unable to get store schema version, creating tables")
                self.initializeStore(storeProxy, schema: schema, uniqueIdentifier: uniqueIdentifier)
            }
        }
    }
    
    private func initializeStore(storeProxy: WalletStoreProxy, schema: SQLiteSchema, uniqueIdentifier: String) {
        let statements = schema.executableStatements
        
        logger.info("Initializing store with schema with version \(schema.version)")
        storeProxy.createTables(statements)
        
        logger.info("Setting default store metadata")
        let metadata: [String: AnyObject] = [
            MetadataEntity.schemaVersionKey: schema.version,
            MetadataEntity.uniqueIdentifierKey: uniqueIdentifier
        ]
        storeProxy.setMetadata(metadata)
    }
    
    private func migrateFromSchemaWithVersion(oldVersion: Int, toSchema newSchema: SQLiteSchema) {
        logger.info("Migrating from schema version \(oldVersion) to schema version \(newSchema.version)")
        let _ = WalletStoreSchemas.schemaWithVersion(oldVersion)
        // TODO: mark current schema version
    }
    
}