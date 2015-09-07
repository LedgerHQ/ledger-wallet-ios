//
//  ApplicationManager.swift
//  ledger-wallet-ios
//
//  Created by Nicolas Bigot on 13/02/2015.
//  Copyright (c) 2015 Ledger. All rights reserved.
//

import Foundation

final class ApplicationManager: BaseManager {
        
    var UUID: String {
        if let uuid = preferences.stringForKey("uuid") {
            return uuid
        }
        let uuid = NSUUID().UUIDString
        preferences.setObject(uuid, forKey: "uuid")
        return uuid
    }
    
    var isInDebug: Bool {
        #if DEBUG
            return true
            #else
            return false
        #endif
    }
    
    var isInProduction: Bool {
        return !isInDebug
    }
    
    var bundleIdentifier: String {
        return NSBundle.mainBundle().bundleIdentifier ?? ""
    }

    var disablesIdleTimer: Bool {
        get {
            return UIApplication.sharedApplication().idleTimerDisabled
        }
        set {
            UIApplication.sharedApplication().idleTimerDisabled = newValue
        }
    }
    
    var libraryDirectoryPath: String {
        return NSSearchPathForDirectoriesInDomains(.LibraryDirectory, .UserDomainMask, true)[0] as! String
    }
    
    var temporaryDirectoryPath: String {
        return NSTemporaryDirectory()
    }
    
    // MARK: Utilities
    
    func handleFirstLaunch() {
        // if app hasn't been launched before
        if !preferences.boolForKey("already_launched") {
            preferences.setBool(true, forKey: "already_launched")
            
            // delete all pairing keychain items
            PairingKeychainItem.destroyAll()
        }
    }
    
    func printLibraryPathIfNeeded() {
        if self.isInDebug {
            Logger.sharedInstance(self.className()).info(libraryDirectoryPath)
        }
    }
    
    func clearTemporaryDirectory() {
        let directoryPath = self.temporaryDirectoryPath
        let fileManager = NSFileManager.defaultManager()
        
        if !fileManager.fileExistsAtPath(directoryPath) {
            return
        }
        
        if var content = fileManager.contentsOfDirectoryAtPath(directoryPath, error: nil) as? [String] {
            content = content.filter({ !$0.hasPrefix(".") })
            for file in content {
                let filepath = directoryPath.stringByAppendingPathComponent(file)
                fileManager.removeItemAtPath(filepath, error: nil)
            }
        }
    }
    
}