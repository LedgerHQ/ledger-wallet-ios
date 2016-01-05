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
    
}