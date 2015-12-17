//
//  WalletMetadataTableEntity.swift
//  ledger-wallet-ios
//
//  Created by Nicolas Bigot on 01/12/2015.
//  Copyright © 2015 Ledger. All rights reserved.
//

import Foundation

final class WalletMetadataTableEntity: SQLiteTableEntityType {
    
    static let tableName = "metadata"
    
    static let schemaVersionKey = "schema_version"
    static let uniqueIdentifierKey = "unique_identifier"

}