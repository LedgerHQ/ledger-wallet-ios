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
    class var itemClass: String { return kSecClassGenericPassword }
    private(set) var persistentReference: NSData!
    private(set) var data: NSData!
    private(set) var creationDate: NSDate!
    
    // MARK: - Test environment
    
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
    
    // MARK: - Static methods
    
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
                    if let keychainItem = self(attributes: item) {
                        keychainItems.append(keychainItem)
                    }
                }
            }
        }
        return keychainItems
    }
    
    class func fetchAllWithCompletion(completion: ([KeychainItem]) -> Void) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) {
            let items = self.fetchAll()
            dispatch_async(dispatch_get_main_queue()) {
                completion(items)
            }
        }
    }
    
    class func removeAll() -> Bool {
        // build query
        var query = defaultQuery()
        
        // perform keychain query
        let status = SecItemDelete(query)
        return status == errSecSuccess || status == errSecItemNotFound
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
                if let keychainItem = self(attributes: item) {
                    return keychainItem
                }
            }
        }
        return nil
    }
    
    private class func defaultQuery() -> [String: AnyObject] {
        return [
            kSecClass: itemClass,
            kSecAttrService: serviceIdentifier + (testEnvironment ? ".test" : "")
        ]
    }
    
    // MARK: - Instance methods
    
    func remove() -> Bool {
        // build query
        var query: [String: AnyObject] = [kSecValuePersistentRef: persistentReference]
        
        // perform keychain query
        let status = SecItemDelete(query)
        
        // clear itself
        clear()
        return status == errSecSuccess
    }
    
    private func clear() {
        persistentReference = nil
        data = nil
        creationDate = nil
    }
    
    // MARK: - Initialization
    
    func initialize(attributes: [String: AnyObject], data: NSData) -> Bool {
        return true
    }
    
    required init?(attributes: [String: AnyObject]) {
        persistentReference = attributes[kSecValuePersistentRef] as? NSData
        data = attributes[kSecValueData] as? NSData
        creationDate = attributes[kSecAttrCreationDate] as? NSDate
        if (persistentReference == nil || data == nil || creationDate == nil || !initialize(attributes, data: data!)) {
            return nil
        }
    }
    
}