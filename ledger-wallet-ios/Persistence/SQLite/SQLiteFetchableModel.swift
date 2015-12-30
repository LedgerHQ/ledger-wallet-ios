//
//  SQLiteFetchableModel.swift
//  ledger-wallet-ios
//
//  Created by Nicolas Bigot on 02/12/2015.
//  Copyright © 2015 Ledger. All rights reserved.
//

import Foundation

protocol SQLiteFetchableModel {
        
    static func collectionFromResultSet(resultSet: SQLiteStoreResultSet) -> [Self]
    
    init?(resultSet: SQLiteStoreResultSet)
    
}

extension SQLiteFetchableModel {
    
    static func collectionFromResultSet(resultSet: SQLiteStoreResultSet) -> [Self] {
        var results: [Self] = []
        
        while resultSet.next() {
            if let result = self.init(resultSet: resultSet) {
                results.append(result)
            }
        }
        return results
    }
    
    static func optionalIntegerForKey(key: String, resultSet: SQLiteStoreResultSet) -> Int? {
        guard !resultSet.columnIsNull(key) else {
            return nil
        }
        return resultSet.longForColumn(key)
    }
    
    static func optionalInteger64ForKey(key: String, resultSet: SQLiteStoreResultSet) -> Int64? {
        guard !resultSet.columnIsNull(key) else {
            return nil
        }
        return resultSet.longLongIntForColumn(key)
    }
    
    static func optionalStringForKey(key: String, resultSet: SQLiteStoreResultSet) -> String? {
        guard !resultSet.columnIsNull(key) else {
            return nil
        }
        return resultSet.stringForColumn(key)
    }
    
    static func optionalBoolForKey(key: String, resultSet: SQLiteStoreResultSet) -> Bool? {
        guard !resultSet.columnIsNull(key) else {
            return nil
        }
        return resultSet.boolForColumn(key)
    }

    
}