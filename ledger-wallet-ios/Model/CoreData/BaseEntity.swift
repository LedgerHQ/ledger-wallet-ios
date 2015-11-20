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
    
    static var entityName: String { get }
    static func insertInContext(context: NSManagedObjectContext) -> Self
    static func fetchRequest() -> NSFetchRequest
    
}

extension BaseEntity where Self: NSManagedObject {
    
    static var entityName: String {
        return Self.className().stringByReplacingOccurrencesOfString("Entity", withString: "")
    }
    
    static func insertInContext(context: NSManagedObjectContext) -> Self {
        return NSEntityDescription.insertNewObjectForEntityForName(entityName, inManagedObjectContext: context) as! Self
    }
    
    static func fetchRequest() -> NSFetchRequest {
        return NSFetchRequest(entityName: entityName)
    }

}