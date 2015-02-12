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
    
    class func sharedInstance() -> Self {
        return sharedInstance(self)
    }
    
    private class func sharedInstance<T: BaseManager>(type: T.Type) -> T {
        let className = self.className()
        if let instance = instances[className] as? T {
            return instance
        }
        let instance = T()
        instances[className] = instance
        return instance
    }

    override required init() {
   
    }
    
}