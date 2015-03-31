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
    let userDefaults: NSUserDefaults

    // MARK: - Setters
    
    func setObject(value: AnyObject?, forKey defaultName: String) {
        userDefaults.setObject(value, forKey: persistentKeyForName(defaultName))
        synchronize()
    }
    
    func setInteger(value: Int, forKey defaultName: String) {
        userDefaults.setInteger(value, forKey: persistentKeyForName(defaultName))
        synchronize()
    }
    
    func setFloat(value: Float, forKey defaultName: String) {
        userDefaults.setFloat(value, forKey: persistentKeyForName(defaultName))
        synchronize()
    }
    
    func setDouble(value: Double, forKey defaultName: String) {
        userDefaults.setDouble(value, forKey: persistentKeyForName(defaultName))
        synchronize()
    }
    
    func setBool(value: Bool, forKey defaultName: String) {
        userDefaults.setBool(value, forKey: persistentKeyForName(defaultName))
        synchronize()
    }
    
    func setURL(url: NSURL, forKey defaultName: String) {
        userDefaults.setURL(url, forKey: persistentKeyForName(defaultName))
        synchronize()
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
    
    func stringArrayForKey(defaultName: String) -> [AnyObject]? {
        return userDefaults.stringArrayForKey(persistentKeyForName(defaultName))
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

    func removeObjectForKey(defaultName: String) {
        userDefaults.removeObjectForKey(persistentKeyForName(defaultName))
        synchronize()
    }
    
    func synchronize() -> Bool {
        return userDefaults.synchronize()
    }
    
    private func persistentKeyForName(name: String) -> String {
        return "\(storeName).\(name)"
    }
    
    // MARK: - Initialization
    
    init(storeName: String) {
        self.storeName = storeName
        self.userDefaults = NSUserDefaults.standardUserDefaults()
    }
    
}