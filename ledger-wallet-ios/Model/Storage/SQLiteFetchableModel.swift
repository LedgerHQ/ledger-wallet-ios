//
//  SQLiteFetchableModel.swift
//  ledger-wallet-ios
//
//  Created by Nicolas Bigot on 02/12/2015.
//  Copyright © 2015 Ledger. All rights reserved.
//

import Foundation

protocol SQLiteFetchableModel {
    
    static func collectionFromSet(resultSet: FMResultSet) -> [Self]
    static func integerForKey(key: String, resultSet: FMResultSet) -> Int?
    static func stringForKey(key: String, resultSet: FMResultSet) -> String?
    init?(resultSet: FMResultSet)
    
}

extension SQLiteFetchableModel {
    
    static func collectionFromSet(resultSet: FMResultSet) -> [Self] {
        var results: [Self] = []
        while resultSet.next() {
            if let result = self.init(resultSet: resultSet) {
                results.append(result)
            }
        }
        return results
    }
    
    static func integerForKey(key: String, resultSet: FMResultSet) -> Int? {
        guard !resultSet.columnIsNull(key) else {
            return nil
        }
        return resultSet.longForColumn(key)
    }
    
    static func stringForKey(key: String, resultSet: FMResultSet) -> String? {
        guard !resultSet.columnIsNull(key) else {
            return nil
        }
        return resultSet.stringForColumn(key)
    }
    
}