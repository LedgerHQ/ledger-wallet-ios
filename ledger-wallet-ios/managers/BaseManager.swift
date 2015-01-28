//
//  BaseManager.swift
//  ledger-wallet-ios
//
//  Created by Nicolas Bigot on 27/01/2015.
//  Copyright (c) 2015 Ledger. All rights reserved.
//

import Foundation

class BaseManager: NSObject {
    
    // MARK: Singleton
    
    class func sharedInstance() -> BaseManager {
        let className = self.className()
        if let instance = Singleton.instances[className] {
            return instance
        }
        let instance: BaseManager = self()
        Singleton.instances[className] = instance
        return instance
    }
    
    private struct Singleton {
        private static private(set) var instances: [String: BaseManager] = [:]
    }
    
    override required init() {
   
    }
    
}