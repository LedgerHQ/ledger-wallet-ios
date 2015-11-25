//
//  OperationEntity+CoreDataProperties.swift
//  ledger-wallet-ios
//
//  Created by Nicolas Bigot on 24/11/2015.
//  Copyright © 2015 Ledger. All rights reserved.
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

import Foundation
import CoreData

extension OperationEntity {

    @NSManaged var account: AccountEntity?

}
