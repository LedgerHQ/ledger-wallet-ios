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
    
    var isValid: Bool { return persistentReference != nil && creationDate != nil }
    var count: Int { return keysAndValues.count }
    class var serviceIdentifier: String { return "" }
    class var itemClass: String { return kSecClassGenericPassword as! String }
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
    
    class func fetchAll() -> [KeychainItem] {
        // build query
        var query = defaultQuery()
        query.updateValue(kSecMatchLimitAll, forKey: kSecMatchLimit as! String)
        query.updateValue(true, forKey: kSecReturnData as! String)
        query.updateValue(true, forKey: kSecReturnAttributes as! String)
        query.updateValue(true, forKey: kSecReturnPersistentRef as! String)
        
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
                    let keychainItem = self(attributes: item)
                    if keychainItem.isValid {
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
    
    class func destroyAll() -> Bool {
        // build query
        var query = defaultQuery()
        
        // perform keychain query
        let status = SecItemDelete(query)
        return status == errSecSuccess || status == errSecItemNotFound
    }
    
    class func create() -> Self {
        // build query
        var query = defaultQuery()
        query.updateValue(kSecAttrAccessibleWhenUnlocked, forKey: kSecAttrAccessible as! String)
        query.updateValue(NSUUID().UUIDString, forKey: kSecAttrAccount as! String)
        query.updateValue(true, forKey: kSecReturnAttributes as! String)
        query.updateValue(true, forKey: kSecReturnPersistentRef as! String)
        
        // perform keychain query
        var result: AnyObject? = nil
        let status = withUnsafeMutablePointer(&result) { SecItemAdd(query, UnsafeMutablePointer($0)) }
        let item = result as! [String: AnyObject]
        let keychainItem = self(attributes: item)
        return keychainItem
    }
    
    private class func defaultQuery() -> [String: AnyObject] {
        return [
            (kSecClass as! String): itemClass,
            (kSecAttrService as! String): serviceIdentifier + (testEnvironment ? ".test" : "")
        ]
    }
    
    // MARK: - Instance methods
    
    func setValue(value: String?, forKey key: String) {
        if (value != nil) {
            keysAndValues[key] = value!
            save()
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
        save()
    }

    func destroy() -> Bool {
        // build query
        var query: [String: AnyObject] = [(kSecValuePersistentRef as! String): persistentReference]
        
        // perform keychain query
        let status = SecItemDelete(query)
        
        // clear itself
        clear()
        return status == errSecSuccess
    }
    
    private func save() {
        // build query
        var query: [String: AnyObject] = [(kSecValuePersistentRef as! String): persistentReference]
        
        // perform request
        let data = JSON.dataFromJSONObject(keysAndValues)!
        let attributes = [(kSecValueData as! String): data]
        let status = SecItemUpdate(query, attributes)
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
    
    required init(attributes: [String: AnyObject]) {
        persistentReference = attributes[kSecValuePersistentRef as! String] as! NSData
        creationDate = attributes[kSecAttrCreationDate as! String] as! NSDate
        let data = attributes[kSecValueData as! String] as? NSData
        load(data)
    }
    
}

extension KeychainItem: Printable {
    
    var description: String {
        return "KeychainItem: \(keysAndValues)"
    }
    
}