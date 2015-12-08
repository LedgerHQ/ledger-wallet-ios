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
    
    // MARK: Blocks management
    
    func performBlock(block: (SQLiteStoreContext) -> Void) {
        queue.addOperationWithBlock() { [weak self] in
            guard let strongSelf = self else { return }

            block(strongSelf.database)
        }
    }

    func performTransaction(block: (SQLiteStoreContext) -> Bool) {
        queue.addOperationWithBlock() { [weak self] in
            guard let strongSelf = self else { return }
            
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
    
    private func open() {
        queue.addOperationWithBlock() {
            let fileManager = NSFileManager.defaultManager()
            
            var databasePath: String? = nil
            if let URL = self.URL {
                // check that URL is a file
                guard let path = URL.path where URL.fileURL else {
                    self.logger.error("Unable to init store with non-file URL \"\(URL)\"")
                    return
                }
                databasePath = path
                
                // check that URL is not a directory
                var isDirectory: ObjCBool = false
                fileManager.fileExistsAtPath(path, isDirectory: &isDirectory)
                guard !isDirectory else {
                    self.logger.error("Unable to init store with directory URL \"\(URL)\"")
                    return
                }
                
                // create database directory if needed
                let databaseDirectory = (path as NSString).stringByDeletingLastPathComponent
                if !fileManager.fileExistsAtPath(databaseDirectory) {
                    do {
                        try fileManager.createDirectoryAtPath(databaseDirectory, withIntermediateDirectories: true, attributes: nil)
                    }
                    catch {
                        self.logger.error("Unable to create store directory at URL \"\(databaseDirectory)\"")
                        return
                    }
                }
                
                // create database file if needed
                if !fileManager.fileExistsAtPath(path) {
                    guard fileManager.createFileAtPath(path, contents: nil, attributes: nil) else {
                        self.logger.error("Unable to create store file at URL \"\(URL)\"")
                        return
                    }
                }
                self.logger.info("Opening store at URL \"\(URL)\"")
            }
            else {
                self.logger.info("Opening store in memory")
            }

            // create and open database
            guard let database = FMDatabase(path: databasePath) where database.open() else {
                if self.URL != nil {
                    self.logger.error("Unable to open store at URL: \(self.URL!)")
                }
                else {
                    self.logger.error("Unable to open store in memory")
                }
                return
            }
            database.crashOnErrors = false
            database.logsErrors = false
            database.setShouldCacheStatements(true)
            self.database = database
        }
    }
    
    private func close() -> Bool {
        var success = false
        queue.addOperationWithBlock() {
            guard let database = self.database else {
                self.logger.warn("Unable to close: no database")
                return
            }
            if self.URL != nil {
                self.logger.info("Closing store at URL \"\(self.URL!)\"")
            }
            success = database.close()
            self.database = nil
        }
        return success
    }
    
    // MARK: Initialization
    
    init(URL: NSURL?) {
        self.URL = URL
        open()
    }
    
    deinit {
        close()
        waitCompletionOfAllBlocks()
    }
    
}