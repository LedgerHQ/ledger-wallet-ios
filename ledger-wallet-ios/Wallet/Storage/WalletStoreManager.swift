//
//  WalletStoreManager.swift
//  ledger-wallet-ios
//
//  Created by Nicolas Bigot on 27/11/2015.
//  Copyright © 2015 Ledger. All rights reserved.
//

import Foundation

final class WalletStoreManager {
    
    private let store: SQLiteStore
    private let logger = Logger.sharedInstance(name: "WalletStoreManager")
    
    // MARK: Convenience method
    
    class func managedStoreAtURL(URL: NSURL?, identifier: String, coinNetwork: CoinNetworkType) -> SQLiteStore? {
        let store = SQLiteStore(URL: URL)
        guard store.open() else {
            return nil
        }
        
        let manager = WalletStoreManager(store: store)
        let schema = WalletStoreSchemas.currentSchema
        manager.executePragmaCommands(schema)
        manager.automigrateOrInstallSchema(schema, identifier: identifier, coinNetwork: coinNetwork)
        return store
    }
    
    // MARK: Schema installation
    
    private func executePragmaCommands(schema: SQLiteSchema) {
        store.performBlock() { context in
            let statements = schema.executablePragmaCommands
            for statement in statements {
                guard WalletStoreExecutor.executePragmaCommand(statement, context: context) else {
                    return
                }
            }
        }
    }
    
    private func installSchema(schema: SQLiteSchema, identifier: String, coinNetwork: CoinNetworkType) {
        store.performBlock() { context in
            self.installSchema(schema, identifier: identifier, coinNetwork: coinNetwork, context: context)
        }
    }
    
    private func migrateToSchema(schema: SQLiteSchema) {
        store.performBlock() { context in
            self.migrateToSchemaIfNeeded(schema, context: context)
        }
    }
    
    private func automigrateOrInstallSchema(schema: SQLiteSchema, identifier: String, coinNetwork: CoinNetworkType) {
        store.performBlock() { context in
            if self.needsToInstallSchema(schema, context: context) {
                self.installSchema(schema, identifier: identifier, coinNetwork: coinNetwork, context: context)
            }
            else {
                self.migrateToSchemaIfNeeded(schema, context: context)
            }
        }
    }

    private func installSchema(schema: SQLiteSchema, identifier: String, coinNetwork: CoinNetworkType, context: SQLiteStoreContext) -> Bool {
        logger.info("Initializing store with schema with version \(schema.version)")
        context.beginTransaction()
        
        for statement in schema.executableStatements {
            guard WalletStoreExecutor.executeTableCreation(statement, context: context) else {
                context.rollback()
                return false
            }
        }
        
        logger.info("Setting default store metadata")
        let metadata: [String: AnyObject] = [
            WalletMetadataEntity.schemaVersionKey: schema.version,
            WalletMetadataEntity.uniqueIdentifierKey: identifier,
            WalletMetadataEntity.coinNetworkIdentifierKey: coinNetwork.identifier,
        ]
        guard WalletStoreExecutor.updateMetadata(metadata, context: context) else {
            context.rollback()
            return false
        }
        
        context.commit()
        return true
    }

    private func needsToInstallSchema(schema: SQLiteSchema, context: SQLiteStoreContext) -> Bool {
        if WalletStoreExecutor.schemaVersion(context) != nil {
            return false
        }
        return true
    }
    
    private func migrateToSchemaIfNeeded(schema: SQLiteSchema, context: SQLiteStoreContext) -> Bool {
        logger.info("Checking if schema migration is required")
        guard let storeVersion = WalletStoreExecutor.schemaVersion(context) else {
            logger.warn("Unable to get store schema version, aborting")
            return false
        }
        
        logger.info("Store schema version \(storeVersion), current version \(schema.version)")
        if schema.version > storeVersion {
            logger.info("Current schema version is greater than store version, migrating")
            guard let oldSchema = WalletStoreSchemas.schemaWithVersion(storeVersion) else {
                logger.error("Unable to get old schema \(storeVersion), aborting")
                return false
            }
            return self.migrateFromSchema(oldSchema, toSchema: schema, context: context)
        }
        else {
            self.logger.info("Current schema version is equal to store version, nothing to be done")
        }
        return false
    }

    private func migrateFromSchema(oldSchema: SQLiteSchema, toSchema newSchema: SQLiteSchema, context: SQLiteStoreContext) -> Bool {
        guard newSchema.version > oldSchema.version else { return false }
        
        context.beginTransaction()
        
        // TODO: mark current schema version
        
        context.commit()
        return true
    }
    
    // MARK: Initialization
    
    init(store: SQLiteStore) {
        self.store = store
    }
    
}