//
//  SQLiteStoreResultSet.swift
//  ledger-wallet-ios
//
//  Created by Nicolas Bigot on 05/01/2016.
//  Copyright © 2016 Ledger. All rights reserved.
//

import Foundation

typealias SQLiteStoreResultSet = FMResultSet

extension SQLiteStoreResultSet {
    
    func integerForKey(key: String) -> Int? {
        guard !columnIsNull(key) else {
            return nil
        }
        return longForColumn(key)
    }
    
    func integer64ForKey(key: String) -> Int64? {
        guard !columnIsNull(key) else {
            return nil
        }
        return longLongIntForColumn(key)
    }
    
    func unsignedInteger32ForKey(key: String) -> UInt32? {
        guard !columnIsNull(key) else {
            return nil
        }
        return UInt32(intForColumn(key))
    }
    
    func stringForKey(key: String) -> String? {
        guard !columnIsNull(key) else {
            return nil
        }
        return stringForColumn(key)
    }
    
    func boolForKey(key: String) -> Bool? {
        guard !columnIsNull(key) else {
            return nil
        }
        return boolForColumn(key)
    }
    
}