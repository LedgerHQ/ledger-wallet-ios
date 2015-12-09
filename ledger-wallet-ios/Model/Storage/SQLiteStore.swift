//
//  SQLiteStore.swift
//  ledger-wallet-ios
//
//  Created by Nicolas Bigot on 27/11/2015.
//  Copyright © 2015 Ledger. All rights reserved.
//

import Foundation

typealias SQLiteStoreContext = FMDatabase
typealias SQLiteStoreResultSet = FMResultSet

final class SQLiteStore {

    private var database: FMDatabase!
    private let queue = NSOperationQueue(name: "SQLiteStore", maxConcurrentOperationCount: 1)
    private let URL: NSURL?
    private let logger = Logger.sharedInstance(name: "SQLiteStore")
    
    var isOpen: Bool {
        var open = false
        queue.addOperationWithBlock() {
            guard let database = self.database else {
                return
            }
            open = database.goodConnection()
        }
        queue.waitUntilAllOperationsAreFinished()
        return open
    }
    
    // MARK: Blocks management
    
    func performBlock(block: (SQLiteStoreContext) -> Void) {
        queue.addOperationWithBlock() { [weak self] in
            guard let strongSelf = self else { return }
            
            guard let database = strongSelf.database where database.goodConnection() else {
                strongSelf.logger.warn("Unable to perform block: no connection")
                return
            }

            block(strongSelf.database)
        }
    }

    func performTransaction(block: (SQLiteStoreContext) -> Bool) {
        queue.addOperationWithBlock() { [weak self] in
            guard let strongSelf = self else { return }
            
            guard let database = strongSelf.database where database.goodConnection() else {
                strongSelf.logger.warn("Unable to perform transaction: no connection")
                return
            }
            
            strongSelf.database.beginTransaction()
            if block(strongSelf.database) {
                strongSelf.database.commit()
            }
            else {
                strongSelf.database.rollback()
            }
        }
    }

    func waitCompletionOfAllBlocks() {
        queue.waitUntilAllOperationsAreFinished()
    }
    
    // MARK: Open/close
    
    func open() {
        queue.addOperationWithBlock() { [weak self] in
            guard let strongSelf = self else { return }
            guard strongSelf.database == nil else { return }

            let fileManager = NSFileManager.defaultManager()
            
            var databasePath: String? = nil
            if let URL = strongSelf.URL {
                // check that URL is a file
                guard let path = URL.path where URL.fileURL else {
                    strongSelf.logger.error("Unable to init store with non-file URL \"\(URL)\"")
                    return
                }
                databasePath = path
                
                // check that URL is not a directory
                var isDirectory: ObjCBool = false
                fileManager.fileExistsAtPath(path, isDirectory: &isDirectory)
                guard !isDirectory else {
                    strongSelf.logger.error("Unable to init store with directory URL \"\(URL)\"")
                    return
                }
                
                // create database directory if needed
                let databaseDirectory = (path as NSString).stringByDeletingLastPathComponent
                if !fileManager.fileExistsAtPath(databaseDirectory) {
                    do {
                        try fileManager.createDirectoryAtPath(databaseDirectory, withIntermediateDirectories: true, attributes: nil)
                    }
                    catch {
                        strongSelf.logger.error("Unable to create store directory at URL \"\(databaseDirectory)\"")
                        return
                    }
                }
                
                // create database file if needed
                if !fileManager.fileExistsAtPath(path) {
                    guard fileManager.createFileAtPath(path, contents: nil, attributes: nil) else {
                        strongSelf.logger.error("Unable to create store file at URL \"\(URL)\"")
                        return
                    }
                }
                strongSelf.logger.info("Opening store at URL \"\(URL)\"")
            }
            else {
                strongSelf.logger.info("Opening store in memory")
            }

            // create and open database
            guard let database = FMDatabase(path: databasePath) where database.open() else {
                if strongSelf.URL != nil {
                    strongSelf.logger.error("Unable to open store at URL: \(strongSelf.URL!)")
                }
                else {
                    strongSelf.logger.error("Unable to open store in memory")
                }
                return
            }
            database.crashOnErrors = false
            database.logsErrors = false
            database.setShouldCacheStatements(true)
            strongSelf.database = database
        }
    }
    
    func close() {
        queue.cancelAllOperations()
        queue.addOperationWithBlock() { [weak self] in
            guard let strongSelf = self else { return }
            guard let database = strongSelf.database else { return }
            
            if strongSelf.URL != nil {
                strongSelf.logger.info("Closing store at URL \"\(strongSelf.URL!)\"")
            }
            else
            {
                strongSelf.logger.info("Closing store in memory")
            }
            database.close()
            strongSelf.database = nil
        }
    }
    
    // MARK: Initialization
    
    init(URL: NSURL?) {
        self.URL = URL
    }
    
    deinit {
        close()
        waitCompletionOfAllBlocks()
    }
    
}