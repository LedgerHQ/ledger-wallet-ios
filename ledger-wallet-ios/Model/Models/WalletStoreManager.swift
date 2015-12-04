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
        let storeProxy = WalletStoreProxy(store: store)
        
        if let schema = WalletStoreSchemas.currentSchema {
            executePragmaCommands(storeProxy, schema: schema)
            checkForSchemaMigration(storeProxy, schema: schema, uniqueIdentifier: uniqueIdentifier)
        }
        else {
            logger.error("Unable to get current schema")
        }
//        store.performBlock() { database in
//            database.executeUpdate("INSERT INTO account ('index', 'extended_public_key') VALUES (0, 'xpub6Cec5KTvWeSNEw9bHe5v5sFPRwpM1x86Scuu7FuBpsQrhBg5GjhhBePAxpUQxmX8RNdAW2rfxZPQrrE5JAUqaa7MRfnXGKjQJB2awZ7Qgxy')", withArgumentsInArray: nil)
//            database.executeUpdate("INSERT INTO account ('index', 'extended_public_key') VALUES (1, 'xpub6Cec5KTvWeSNG1BsXpNab628WvCGZEECqiHPY7JcBWSQgKfQN5wK4hUr3e9PM464Q7u9owCNHKTRGNGMxYdfPgUFZ3hR3ko2ap7xqxHmCxk')", withArgumentsInArray: nil)
//            database.executeUpdate("INSERT INTO account ('index', 'extended_public_key') VALUES (2, 'xpub6Cec5KTvWeSNJtrFK6PqoCoP369xG8HYEDswqmTsQq63frkqF6dqYV56qRjJ7VQn1TEaejBPowG9vMGxVhsfRinhTgH5fTcAvMedABC8w6P')", withArgumentsInArray: nil)
//            database.executeUpdate("INSERT INTO account ('index', 'extended_public_key') VALUES (3, 'xpub6Cec5KTvWeSNLwb2fMVRYVJn4w49WebLyg7cJM2QsbQotPggFX49H8jKvieYCMHaGCsKrW9VVknSt7KRxRuacasuGyJm74hZ4JeNRdsRB6Y')", withArgumentsInArray: nil)
//            database.executeUpdate("INSERT INTO account ('index', 'extended_public_key') VALUES (4, 'xpub6Cec5KTvWeSNQLuVYmj4JZkX8q3VpSoQRd4BRkcPmhQvDaFi3yPobQXW795SLwN9zHXv9vYJyt4FrkWRBuJZMrg81qx7BDxNffPtJmFg2mb')", withArgumentsInArray: nil)
//        }
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