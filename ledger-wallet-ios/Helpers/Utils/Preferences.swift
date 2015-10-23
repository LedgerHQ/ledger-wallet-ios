//
//  Preferences.swift
//  ledger-wallet-ios
//
//  Created by Nicolas Bigot on 09/03/2015.
//  Copyright (c) 2015 Ledger. All rights reserved.
//

import Foundation

final class Preferences {
    
    let storeName: String
    private let userDefaults: NSUserDefaults
    private var inBatchUpdate = false

    // MARK: - Setters
    
    func setObject(value: AnyObject?, forKey defaultName: String) {
        userDefaults.setObject(value, forKey: persistentKeyForName(defaultName))
        synchronizeIfNeeded()
    }
    
    func setInteger(value: Int, forKey defaultName: String) {
        userDefaults.setInteger(value, forKey: persistentKeyForName(defaultName))
        synchronizeIfNeeded()
    }
    
    func setFloat(value: Float, forKey defaultName: String) {
        userDefaults.setFloat(value, forKey: persistentKeyForName(defaultName))
        synchronizeIfNeeded()
    }
    
    func setDouble(value: Double, forKey defaultName: String) {
        userDefaults.setDouble(value, forKey: persistentKeyForName(defaultName))
        synchronizeIfNeeded()
    }
    
    func setBool(value: Bool, forKey defaultName: String) {
        userDefaults.setBool(value, forKey: persistentKeyForName(defaultName))
        synchronizeIfNeeded()
    }
    
    func setURL(url: NSURL, forKey defaultName: String) {
        userDefaults.setURL(url, forKey: persistentKeyForName(defaultName))
        synchronizeIfNeeded()
    }
    
    // MARK: - Getters
    
    func objectForKey(defaultName: String) -> AnyObject? {
        return userDefaults.objectForKey(persistentKeyForName(defaultName))
    }
    
    func stringForKey(defaultName: String) -> String? {
        return userDefaults.stringForKey(persistentKeyForName(defaultName))
    }
    
    func arrayForKey(defaultName: String) -> [AnyObject]? {
        return userDefaults.arrayForKey(persistentKeyForName(defaultName))
    }
    
    func dictionaryForKey(defaultName: String) -> [NSObject : AnyObject]? {
        return userDefaults.dictionaryForKey(persistentKeyForName(defaultName))
    }
    
    func dataForKey(defaultName: String) -> NSData? {
        return userDefaults.dataForKey(persistentKeyForName(defaultName))
    }
    
    func integerForKey(defaultName: String) -> Int {
        return userDefaults.integerForKey(persistentKeyForName(defaultName))
    }
    
    func floatForKey(defaultName: String) -> Float {
        return userDefaults.floatForKey(persistentKeyForName(defaultName))
    }
    
    func doubleForKey(defaultName: String) -> Double {
        return userDefaults.doubleForKey(persistentKeyForName(defaultName))
    }
    
    func boolForKey(defaultName: String) -> Bool {
        return userDefaults.boolForKey(persistentKeyForName(defaultName))
    }
    
    func URLForKey(defaultName: String) -> NSURL? {
        return userDefaults.URLForKey(persistentKeyForName(defaultName))
    }
    
    // MARK: - Utils

    func beginBatchUpdate() {
        guard inBatchUpdate == false else { return }
        inBatchUpdate = true
    }
    
    func endBatchUpdate() {
        guard inBatchUpdate == true else { return }
        inBatchUpdate = false
        synchronize()
    }
    
    func removeObjectForKey(defaultName: String) {
        userDefaults.removeObjectForKey(persistentKeyForName(defaultName))
        synchronizeIfNeeded()
    }
    
    func synchronize() -> Bool {
        return userDefaults.synchronize()
    }
    
    private func synchronizeIfNeeded() -> Bool {
        if inBatchUpdate { return false }
        return synchronize()
    }
    
    func dictionaryRepresentation() -> [String : AnyObject] {
        let defaults = userDefaults.dictionaryRepresentation()
        var result: [String : AnyObject] = [:]
        for (key, value) in defaults where key.hasPrefix(storeName) {
            result[key] = value
        }
        return result
    }
    
    func clear() {
        for (key, _) in dictionaryRepresentation() {
            userDefaults.removeObjectForKey(key)
        }
        synchronize()
    }
    
    private func persistentKeyForName(name: String) -> String {
        return "\(storeName).\(name)"
    }
    
    // MARK: - Initialization
    
    init(storeName: String) {
        self.storeName = storeName
        self.userDefaults = NSUserDefaults.standardUserDefaults()
    }
    
    deinit {
        synchronize()
    }
    
}