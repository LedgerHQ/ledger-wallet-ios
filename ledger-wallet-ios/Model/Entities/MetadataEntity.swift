//
//  MetadataEntity.swift
//  ledger-wallet-ios
//
//  Created by Nicolas Bigot on 01/12/2015.
//  Copyright © 2015 Ledger. All rights reserved.
//

import Foundation

final class MetadataEntity: SQLiteStorable {
    
    static let tableName = "metadata"
    static let identifierKey = "id"
    static let schemaVersionKey = "schema_version"

}