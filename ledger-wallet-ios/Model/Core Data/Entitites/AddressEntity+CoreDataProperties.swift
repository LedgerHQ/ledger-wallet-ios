//
//  AddressEntity+CoreDataProperties.swift
//  ledger-wallet-ios
//
//  Created by Nicolas Bigot on 26/11/2015.
//  Copyright © 2015 Ledger. All rights reserved.
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

import Foundation
import CoreData

extension AddressEntity {

    @NSManaged var address: String?
    @NSManaged var chainIndex: Int32
    @NSManaged var keyIndex: Int32
    @NSManaged var account: AccountEntity?

}
