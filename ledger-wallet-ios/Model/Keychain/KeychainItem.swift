//
//  KeychainItem.swift
//  ledger-wallet-ios
//
//  Created by Nicolas Bigot on 26/01/2015.
//  Copyright (c) 2015 Ledger. All rights reserved.
//

import Foundation
import Security

class GenericKeychainItem {
    
    var valid: Bool { return persistentReference != nil && creationDate != nil }
    var count: Int { return keysAndValues.count }
    var autosaves = true
    
    class var serviceIdentifier: String { return "" }
    class var itemClass: String { return kSecClassGenericPassword as String }
    class var accessibleAttribute: String { return kSecAttrAccessibleWhenUnlocked as String }
    
    private(set) var creationDate: NSDate! = nil
    private var persistentReference: NSData! = nil
    private var keysAndValues: [String: String] = [:]
    
    // MARK: - Static methods
    
    static func fetchAll() -> [AnyObject] {
        // build query
        var query = defaultQuery()
        query.updateValue(kSecMatchLimitAll, forKey: kSecMatchLimit as String)
        query.updateValue(true, forKey: kSecReturnData as String)
        query.updateValue(true, forKey: kSecReturnAttributes as String)
        query.updateValue(true, forKey: kSecReturnPersistentRef as String)
        
        // build keychain items array
        var keychainItems: [AnyObject] = []
        
        // perform keychain query
        var result: AnyObject? = nil
        let status = withUnsafeMutablePointer(&result) { SecItemCopyMatching(query, UnsafeMutablePointer($0)) }
        if (status == errSecSuccess) {
            if let items = result as? [[String: AnyObject]] {
                // loop through all returned items
                for item in items {
                    // try to build keychain item with given attributes
                    let keychainItem = self.init(attributes: item)
                    keychainItems.append(keychainItem)
                }
            }
        }
        return keychainItems
    }

    class func destroyAll() -> Bool {
        // build query
        let query = defaultQuery()
        
        // perform keychain query
        let status = SecItemDelete(query)
        return status == errSecSuccess || status == errSecItemNotFound
    }
    
    // MARK: - Public interface
    
    func setValue(value: String?, forKey key: String) -> Bool {
        if (value != nil) {
            keysAndValues[key] = value!
            return saveIfNeeded()
        }
        else {
            return removeValueForKey(key)
        }
    }
    
    func valueForKey(key: String) -> String? {
        return keysAndValues[key]
    }
    
    func removeValueForKey(key: String) -> Bool {
        keysAndValues.removeValueForKey(key)
        return saveIfNeeded()
    }

    func destroy() -> Bool {
        // build query
        let query: [String: AnyObject] = [(kSecValuePersistentRef as String): persistentReference]
        
        // perform keychain query
        let status = SecItemDelete(query)
        
        // clear itself
        clear()
        
        return status == errSecSuccess
    }
    
    func save() -> Bool {
        // build query
        let query: [String: AnyObject] = [(kSecValuePersistentRef as String): persistentReference]
        
        // perform request
        let data = JSON.dataFromJSONObject(keysAndValues)!
        let attributes = [(kSecValueData as String): data]
        let status = SecItemUpdate(query, attributes)
        
        return status == errSecSuccess
    }
    
    // MARK: - Private interface
    
    private class func defaultQuery() -> [String: AnyObject] {
        return [
            (kSecClass as String): itemClass,
            (kSecAttrService as String): serviceIdentifier
        ]
    }
    
    private func saveIfNeeded() -> Bool {
        if autosaves == true {
            return save()
        }
        return true
    }
    
    private func loadData(data: NSData?) {
        if (data == nil) {
            return
        }
        if let keysAndValues = JSON.JSONObjectFromData(data!) as? [String: String] {
            for (key, value) in keysAndValues {
                self.keysAndValues.updateValue(value, forKey: key)
            }
        }
    }
    
    private func clear() {
        keysAndValues.removeAll(keepCapacity: false)
        persistentReference = nil
        creationDate = nil
    }
    
    // MARK: - Initialization
    
    private func loadAttributes(attributes: [String: AnyObject]) {
        // load mandatory internal properties
        persistentReference = attributes[kSecValuePersistentRef as String] as! NSData
        creationDate = attributes[kSecAttrCreationDate as String] as! NSDate
    }
    
    required init() {
        // build query
        var query = self.dynamicType.defaultQuery()
        query.updateValue(self.dynamicType.accessibleAttribute, forKey: kSecAttrAccessible as String)
        query.updateValue(NSUUID().UUIDString, forKey: kSecAttrAccount as String)
        query.updateValue(true, forKey: kSecReturnAttributes as String)
        query.updateValue(true, forKey: kSecReturnPersistentRef as String)
        
        // perform keychain query insertion
        var result: AnyObject? = nil
        _ = withUnsafeMutablePointer(&result) { SecItemAdd(query, UnsafeMutablePointer($0)) }
        let attributes = result as! [String: AnyObject]
        
        // load attributes
        loadAttributes(attributes)
    }
    
    required init(attributes: [String: AnyObject]) {
        // load attributes
        loadAttributes(attributes)
        
        // load keychain item data
        loadData(attributes[kSecValueData as String] as? NSData)
    }
    
}