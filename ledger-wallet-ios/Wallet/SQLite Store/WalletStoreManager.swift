//
//  WalletStoreManager.swift
//  ledger-wallet-ios
//
//  Created by Nicolas Bigot on 27/11/2015.
//  Copyright © 2015 Ledger. All rights reserved.
//

import Foundation

final class WalletStoreManager {
    
    private static let logger = Logger.sharedInstance(name: "WalletStoreManager")
    
    // MARK: - Convenience method
    
    class func storeAtURL(URL: NSURL?, withUniqueIdentifier uniqueIdentifier: String) -> SQLiteStore {
        let store = SQLiteStore(URL: URL)
        
        if let schema = WalletStoreSchemas.currentSchema {
            executePragmaCommands(store, schema: schema)
            checkForSchemaMigration(store, schema: schema, uniqueIdentifier: uniqueIdentifier)
        }
        else {
            logger.error("Unable to get current schema")
        }
        return store
    }
    
    // MARK: - Schema installation
    
    private class func executePragmaCommands(store: SQLiteStore, schema: SQLiteSchema) {
        logger.info("Executing pragma commands")
        
        store.performBlock() { context in
            let statements = schema.executablePragmaCommands
            for statement in statements {
                guard WalletStoreExecutor.executePragmaCommand(statement, context: context) else {
                    return
                }
            }
        }
    }
    
    private class func checkForSchemaMigration(store: SQLiteStore, schema: SQLiteSchema, uniqueIdentifier: String) {
        logger.info("Checking store for schema migration")
        
        store.performBlock() { context in
            if let storeVersion = WalletStoreExecutor.schemaVersion(context) {
                logger.info("Store schema version \(storeVersion), current version \(schema.version)")
                if schema.version > storeVersion {
                    logger.warn("Current schema version is greater than store version, migrating")
                    guard self.migrateFromSchemaWithVersion(storeVersion, toSchema: schema, context: context) else {
                        return
                    }
                }
            }
            else {
                logger.warn("Unable to get store schema version, creating tables")
                guard self.initializeStoreWithSchema(schema, uniqueIdentifier: uniqueIdentifier, context: context) else {
                    return
                }
            }
        }
    }

    private class func initializeStoreWithSchema(schema: SQLiteSchema, uniqueIdentifier: String, context: SQLiteStoreContext) -> Bool {
        let statements = schema.executableStatements
        
        logger.info("Initializing store with schema with version \(schema.version)")
        context.beginTransaction()
        
        for statement in statements {
            guard WalletStoreExecutor.executeTableCreation(statement, context: context) else {
                context.rollback()
                return false
            }
        }
        
        logger.info("Setting default store metadata")
        let metadata: [String: AnyObject] = [
            MetadataEntity.schemaVersionKey: schema.version,
            MetadataEntity.uniqueIdentifierKey: uniqueIdentifier
        ]
        guard WalletStoreExecutor.setMetadata(metadata, context: context) else {
            context.rollback()
            return false
        }
        
        context.commit()
        return true
    }
    
    private class func migrateFromSchemaWithVersion(oldVersion: Int, toSchema newSchema: SQLiteSchema, context: SQLiteStoreContext) -> Bool {
        let _ = WalletStoreSchemas.schemaWithVersion(oldVersion)
        
        context.beginTransaction()
        
        // TODO: mark current schema version
        
        context.commit()
        return true
    }
    
}