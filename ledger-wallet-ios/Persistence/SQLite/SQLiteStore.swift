//
//  SQLiteStore.swift
//  ledger-wallet-ios
//
//  Created by Nicolas Bigot on 27/11/2015.
//  Copyright © 2015 Ledger. All rights reserved.
//

import Foundation

typealias SQLiteStoreContext = FMDatabase

final class SQLiteStore {

    private var database: FMDatabase!
    private let URL: NSURL?
    private let workingQueue = NSOperationQueue(name: "SQLiteStore", maxConcurrentOperationCount: 1)
    private let logger = Logger.sharedInstance(name: "SQLiteStore")
    
    var isOpen: Bool {
        var open = false
        workingQueue.addOperationWithBlock() {
            guard let database = self.database else {
                return
            }
            open = database.goodConnection()
        }
        workingQueue.waitUntilAllOperationsAreFinished()
        return open
    }
    
    // MARK: Blocks management
    
    func performBlock(block: (SQLiteStoreContext) -> Void) {
        workingQueue.addOperationWithBlock() { [weak self] in
            guard let strongSelf = self else { return }
            
            guard let database = strongSelf.database else {
                strongSelf.logger.error("Unable to perform block: not opened")
                return
            }

            block(database)
        }
    }

    func performTransaction(block: (SQLiteStoreContext) -> Bool) {
        workingQueue.addOperationWithBlock() { [weak self] in
            guard let strongSelf = self else { return }
            
            guard let database = strongSelf.database else {
                strongSelf.logger.error("Unable to perform transaction: no opened")
                return
            }
            
            database.beginTransaction()
            if block(database) {
                database.commit()
            }
            else {
                database.rollback()
            }
        }
    }
    
    // MARK: Open/close
    
    func open() -> Bool {
        var opened = false
        
        workingQueue.addOperationWithBlock() { [weak self] in
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
                strongSelf.logger.info("Opening store at URL \"\(URL.absoluteString)\"")
            }
            else {
                strongSelf.logger.info("Opening store in memory")
            }

            // create and open database
            guard let database = FMDatabase(path: databasePath) where database.open() else {
                if strongSelf.URL != nil {
                    strongSelf.logger.error("Unable to open store at URL: \(strongSelf.URL!.absoluteString)")
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
            opened = true
        }
        workingQueue.waitUntilAllOperationsAreFinished()
        return opened
    }
    
    func close() -> Bool {
        var closed = true
        
        workingQueue.cancelAllOperations()
        workingQueue.addOperationWithBlock() { [weak self] in
            guard let strongSelf = self else { return }
            guard let database = strongSelf.database else { return }
            
            if strongSelf.URL != nil {
                strongSelf.logger.info("Closing store at URL \"\(strongSelf.URL!)\"")
            }
            else
            {
                strongSelf.logger.info("Closing store in memory")
            }
            closed = database.close()
            strongSelf.database = nil
        }
        workingQueue.waitUntilAllOperationsAreFinished()
        return closed
    }
    
    // MARK: Initialization
    
    init(URL: NSURL?) {
        self.URL = URL
    }
    
    deinit {
        close()
    }
    
}