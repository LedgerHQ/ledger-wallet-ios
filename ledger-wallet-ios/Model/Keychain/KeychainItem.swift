//
//  KeychainItem.swift
//  ledger-wallet-ios
//
//  Created by Nicolas Bigot on 26/01/2015.
//  Copyright (c) 2015 Ledger. All rights reserved.
//

import Foundation
import Security

protocol KeychainItem {
    
    var valid: Bool { get }
    var count: Int { get }
    var autosaves: Bool { get set }
    
    static func fetchAll() -> [AnyObject]
    static func destroyAll() -> Bool
    
    static var serviceIdentifier: String { get }
    static var itemClass: String { get }
    static var accessibleAttribute: String { get }
    
    init()
    init(attributes: [String: AnyObject])
    
    func setValue(value: String?, forKey key: String)
    func valueForKey(key: String) -> String?
    func removeValueForKey(key: String)
    func destroy() -> Bool
    func save() -> Bool
}

class GenericKeychainItem: KeychainItem {
    
    var valid: Bool { return persistentReference != nil && creationDate != nil }
    var count: Int { return keysAndValues.count }
    var autosaves = true
    
    class var serviceIdentifier: String { return "" }
    class var itemClass: String { return kSecClassGenericPassword as String }
    class var accessibleAttribute: String { return kSecAttrAccessibleWhenUnlocked as String }
    
    private(set) var creationDate: NSDate! = nil
    private var persistentReference: NSData! = nil
    private var keysAndValues: [String: String] = [:]
    
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
                    if keychainItem.valid {
                        keychainItems.append(keychainItem)
                    }
                    else {
                        keychainItem.destroy()
                    }
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
    
    func setValue(value: String?, forKey key: String) {
        if (value != nil) {
            keysAndValues[key] = value!
            saveIfNeeded()
        }
        else {
            removeValueForKey(key)
        }
    }
    
    func valueForKey(key: String) -> String? {
        return keysAndValues[key]
    }
    
    func removeValueForKey(key: String) {
        keysAndValues.removeValueForKey(key)
        saveIfNeeded()
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
            (kSecAttrService as String): serviceIdentifier + (testEnvironment ? ".test" : "")
        ]
    }
    
    private func saveIfNeeded() {
        if autosaves == true {
            save()
        }
    }
    
    private func load(data: NSData?) {
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
    
    required convenience init() {
        // build query
        var query = self.dynamicType.defaultQuery()
        query.updateValue(self.dynamicType.accessibleAttribute, forKey: kSecAttrAccessible as String)
        query.updateValue(NSUUID().UUIDString, forKey: kSecAttrAccount as String)
        query.updateValue(true, forKey: kSecReturnAttributes as String)
        query.updateValue(true, forKey: kSecReturnPersistentRef as String)
        
        // perform keychain query insertion
        var result: AnyObject? = nil
        _ = withUnsafeMutablePointer(&result) { SecItemAdd(query, UnsafeMutablePointer($0)) }
        let item = result as! [String: AnyObject]
        
        // continue initialization
        self.init(attributes: item)
    }
    
    required init(attributes: [String: AnyObject]) {
        assert(self.dynamicType.serviceIdentifier != "", "Keychain item should have a service identifier")
        
        // load mandatory internal properties
        persistentReference = attributes[kSecValuePersistentRef as String] as! NSData
        creationDate = attributes[kSecAttrCreationDate as String] as! NSDate
        
        // load keychain item data
        load(attributes[kSecValueData as String] as? NSData)
    }
    
}