//
//  KeychainItem.swift
//  ledger-wallet-ios
//
//  Created by Nicolas Bigot on 26/01/2015.
//  Copyright (c) 2015 Ledger. All rights reserved.
//

import Foundation
import Security

class KeychainItem {
    
    var valid: Bool { return persistentReference != nil }
    class var serviceIdentifier: String { return "" }
    private(set) var persistentReference: NSData!
    private(set) var data: NSData!
    
    //MARK: Test environment
    
    class var testEnvironment: Bool {
        get {
        return Static.testEnvironment
        }
        set {
            Static.testEnvironment = newValue
        }
    }
    private struct Static {
        private static var testEnvironment = false
    }
    
    //MARK: Static methods
    
    class func fetchAll() -> [KeychainItem] {
        // build query
        var query = defaultQuery()
        query.updateValue(kSecMatchLimitAll, forKey: kSecMatchLimit)
        query.updateValue(true, forKey: kSecReturnData)
        query.updateValue(true, forKey: kSecReturnAttributes)
        query.updateValue(true, forKey: kSecReturnPersistentRef)
        
        // build keychain items array
        var keychainItems: [KeychainItem] = []
        
        // perform keychain query
        var result: AnyObject? = nil
        let status = withUnsafeMutablePointer(&result) { SecItemCopyMatching(query, UnsafeMutablePointer($0)) }
        if (status == errSecSuccess) {
            if let items = result as? [[String: AnyObject]] {
                // loop through all returned items
                for item in items {
                    // try to build keychain item with given attributes
                    if let keychainItem = KeychainItem(attributes: item) {
                        keychainItems.append(keychainItem)
                    }
                }
            }
        }
        return keychainItems
    }
    
    class func removeAll() -> Bool {
        return fetchAll().map({ $0.remove() }).reduce(true, &)
    }
    
    class func add(data: NSData) -> KeychainItem? {
        // build query
        var query = defaultQuery()
        query.updateValue(kSecAttrAccessibleWhenUnlocked, forKey: kSecAttrAccessible)
        query.updateValue(data, forKey: kSecValueData)
        query.updateValue(NSUUID().UUIDString, forKey: kSecAttrAccount)
        query.updateValue(true, forKey: kSecReturnData)
        query.updateValue(true, forKey: kSecReturnAttributes)
        query.updateValue(true, forKey: kSecReturnPersistentRef)
        
        // perform keychain query
        var result: AnyObject? = nil
        let status = withUnsafeMutablePointer(&result) { SecItemAdd(query, UnsafeMutablePointer($0)) }
        if (status == errSecSuccess) {
            if let item = result as? [String: AnyObject] {
                // try to build keychain item with given attributes
                if let keychainItem = KeychainItem(attributes: item) {
                    return keychainItem
                }
            }
        }
        return nil
    }
    
    private class func defaultQuery() -> [String: AnyObject] {
        return [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: serviceIdentifier + (testEnvironment ? ".test" : "")
        ]
    }
    
    //MARK: Instance methods
    
    func remove() -> Bool {
        // build query
        var query: [String: AnyObject] = [kSecValuePersistentRef: persistentReference]
        
        // perform keychain query
        let status = SecItemDelete(query)
        
        // clear itself
        persistentReference = nil
        data = nil
        
        return status == errSecSuccess
    }
    
    //MARK: Initialization
    
    func initialize() -> Bool {
        return false
    }
    
    private init?(attributes: [String: AnyObject]) {
        persistentReference = attributes[kSecValuePersistentRef] as? NSData
        data = attributes[kSecValueData] as? NSData
        if (persistentReference == nil || data == nil || !initialize()) {
            return nil
        }
    }
    
}