//
//  BaseManager.swift
//  ledger-wallet-ios
//
//  Created by Nicolas Bigot on 27/01/2015.
//  Copyright (c) 2015 Ledger. All rights reserved.
//

import Foundation

class BaseManager: NSObject {

    private static var instances: [String: BaseManager] = [:]
    
    // MARK: - Singleton
    
    class func sharedInstance() -> BaseManager {
        let className = self.className()
        if let instance = instances[className] {
            return instance
        }
        let instance: BaseManager = self()
        instances[className] = instance
        return instance
    }

    override required init() {
   
    }
    
}