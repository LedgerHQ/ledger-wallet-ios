//
//  CoreDataStack.swift
//  ledger-wallet-ios
//
//  Created by Nicolas Bigot on 18/11/2015.
//  Copyright © 2015 Ledger. All rights reserved.
//

import Foundation
import CoreData

enum CoreDataStoreType {
    
    case Sqlite
    case Memory
    
    private var systemStoreType: String {
        switch self {
        case .Sqlite: return NSSQLiteStoreType
        case .Memory: return NSInMemoryStoreType
        }
    }
    
    private var requiresFileStorage: Bool {
        switch self {
        case .Memory: return false
        default: return true
        }
    }
    
}

final class CoreDataStack {

    private var logger = Logger.sharedInstance(name: "CoreDataStack")
    private var privateManagedObjectContext: NSManagedObjectContext!
    private var mainManagedObjectContext: NSManagedObjectContext!
    private var persistentStoreCoordinator: NSPersistentStoreCoordinator!
    private var persistentStore: NSPersistentStore!
    
    // MARK: Blocks
    
    func performBlock(block: (NSManagedObjectContext) -> Void) {
        guard let mainManagedObjectContext = mainManagedObjectContext else {
            logger.error("Unable to perform block (no main context)")
            return
        }
        
        mainManagedObjectContext.performBlock() {
            block(mainManagedObjectContext)
        }
    }

    // MARK: Persistence
    
    func saveAndWait(wait: Bool) {
        guard
            let mainManagedObjectContext = mainManagedObjectContext,
            privateManagedObjectContext = privateManagedObjectContext
        else {
            logger.error("Unable to save (no main or private context)")
            return
        }
        
        performMethodForWait(wait)(mainManagedObjectContext)() { [weak self] in
            guard let strongSelf = self else { return }
            guard mainManagedObjectContext.hasChanges || privateManagedObjectContext.hasChanges else { return }
    
            do {
                try mainManagedObjectContext.save()
            }
            catch {
                strongSelf.logger.error("Unable to save main context \(error)")
                return
            }
            
            strongSelf.performMethodForWait(wait)(privateManagedObjectContext)() {
                do {
                    try privateManagedObjectContext.save()
                }
                catch {
                    strongSelf.logger.error("Unable to save private context \(error)")
                    return
                }
            }
        }
    }
    
    // MARK: Stack opening

    private func createDatabasesDirectory() -> Bool {
        let fileManager = NSFileManager.defaultManager()
        let databasesPath = ApplicationManager.sharedInstance.databasesDirectoryPath
        if !fileManager.fileExistsAtPath(databasesPath) {
            do {
                try fileManager.createDirectoryAtPath(databasesPath, withIntermediateDirectories: true, attributes: nil)
            }
            catch {
                logger.error("Unable to create databases directory at path \(databasesPath) \(error)")
                return false
            }
        }
        return true
    }
    
    private func initializeContextsWithModelName(modelName: String) -> Bool {
        guard let modelURL = NSBundle.mainBundle().URLForResource(modelName, withExtension: "momd") else {
            logger.error("Unable to locate model with name \"\(modelName)\"")
            return false
        }
        
        guard let managedObjectModel = NSManagedObjectModel(contentsOfURL: modelURL) else {
            logger.error("Unable to create object model at URL \(modelURL)")
            return false
        }
        logger.info("Model URL: \(modelURL)")
        
        // create contexts
        persistentStoreCoordinator = NSPersistentStoreCoordinator(managedObjectModel: managedObjectModel)
        mainManagedObjectContext = managedObjectContextWithConcurrencyType(.MainQueueConcurrencyType)
        privateManagedObjectContext = managedObjectContextWithConcurrencyType(.PrivateQueueConcurrencyType)
        
        // setup stack
        privateManagedObjectContext.persistentStoreCoordinator = persistentStoreCoordinator
        mainManagedObjectContext.parentContext = privateManagedObjectContext
        
        return true
    }
    
    private func initializePersistentStoreWithType(storeType: CoreDataStoreType) -> Bool {
        // add persistent store
        do {
            if storeType.requiresFileStorage {
                let databaseURL = NSURL(fileURLWithPath: (ApplicationManager.sharedInstance.databasesDirectoryPath as NSString).stringByAppendingPathComponent(LedgerSqliteDatabaseName + ".sqlite"))
                let options = [NSMigratePersistentStoresAutomaticallyOption: true, NSInferMappingModelAutomaticallyOption: true]
                persistentStore = try persistentStoreCoordinator.addPersistentStoreWithType(storeType.systemStoreType, configuration: nil, URL: databaseURL, options: options)
                logger.info("Database URL: \(databaseURL)")
            }
            else {
                persistentStore = try persistentStoreCoordinator.addPersistentStoreWithType(storeType.systemStoreType, configuration: nil, URL: nil, options: nil)
            }
        }
        catch {
            logger.error("Unable to initialize stack with type \"\(storeType)\" \(error)")
            return false
        }
        return true
    }
    
    // MARK: Utils
    
    private func managedObjectContextWithConcurrencyType(concurrencyType: NSManagedObjectContextConcurrencyType) -> NSManagedObjectContext {
        let context = NSManagedObjectContext(concurrencyType: concurrencyType)
        context.undoManager = nil
        return context
    }
    
    private func dispatchMethodForWait(wait: Bool) -> (dispatch_queue_t, dispatch_block_t) -> Void {
        if wait {
            return dispatch_sync
        }
        return dispatch_async
    }
    
    private func performMethodForWait(wait: Bool) -> NSManagedObjectContext -> (() -> Void) -> Void {
        if wait {
            return NSManagedObjectContext.performBlockAndWait
        }
        return NSManagedObjectContext.performBlock
    }
    
    // MARK: Initialization
    
    init(storeType: CoreDataStoreType, modelName: String, completion: (success: Bool) -> Void) {
        guard createDatabasesDirectory() else {
            completion(success: false)
            return
        }
        
        guard initializeContextsWithModelName(modelName) else {
            completion(success: false)
            return
        }
        
        dispatchAsyncOnGlobalQueueWithPriority(DISPATCH_QUEUE_PRIORITY_HIGH) { [weak self] in
            guard let strongSelf = self else { return }
            let success = strongSelf.initializePersistentStoreWithType(storeType)
            dispatchAsyncOnMainQueue() {
                completion(success: success)
            }
        }
    }

}