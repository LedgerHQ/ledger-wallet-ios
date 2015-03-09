//
//  BaseManager.swift
//  ledger-wallet-ios
//
//  Created by Nicolas Bigot on 27/01/2015.
//  Copyright (c) 2015 Ledger. All rights reserved.
//

import Foundation

class BaseManager: NSObject {

    private struct Singleton {
        private static var instances: [String: BaseManager] = [:]
    }

    // MARK: - Singleton
    
    class func sharedInstance() -> Self {
        return sharedInstance(self)
    }
    
    private class func sharedInstance<T: BaseManager>(type: T.Type) -> T {
        let className = self.className()
        if let instance = Singleton.instances[className] {
            return instance as T
        }
        let instance = self()
        Singleton.instances[className] = instance
        return instance as T
    }

    override required init() {
   
    }
    
}