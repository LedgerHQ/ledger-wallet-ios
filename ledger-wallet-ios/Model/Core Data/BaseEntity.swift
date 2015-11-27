//
//  BaseEntity.swift
//  ledger-wallet-ios
//
//  Created by Nicolas Bigot on 19/11/2015.
//  Copyright © 2015 Ledger. All rights reserved.
//

import Foundation
import CoreData

protocol BaseEntity: class {
    
    typealias EntityClass: NSManagedObject = Self
    
    static var entityName: String { get }
    static func insertInContext(context: NSManagedObjectContext) -> EntityClass
    static func fetchRequest() -> NSFetchRequest
    
}

extension BaseEntity where Self: NSManagedObject, EntityClass == Self {
    
    static var entityName: String {
        return Self.className().stringByReplacingOccurrencesOfString("Entity", withString: "")
    }
    
    static func insertInContext(context: NSManagedObjectContext) -> EntityClass {
        return NSEntityDescription.insertNewObjectForEntityForName(entityName, inManagedObjectContext: context) as! EntityClass
    }
    
    static func fetchRequest() -> NSFetchRequest {
        return NSFetchRequest(entityName: entityName)
    }
    
    static func fetchRequestWithPredicate(predicate: String, _ arguments: AnyObject...) -> NSFetchRequest {
        let fetchRequest = self.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: predicate, arguments)
        return fetchRequest
    }

}