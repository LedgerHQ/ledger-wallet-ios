//
//  SharableObject.swift
//  ledger-wallet-ios
//
//  Created by Nicolas Bigot on 27/01/2015.
//  Copyright (c) 2015 Ledger. All rights reserved.
//

import Foundation

class SharableObject: NSObject {

    private struct Singleton {
        private static var instances: [String: SharableObject] = [:]
    }

    // MARK: - Singleton
    
    class func sharedInstance() -> Self {
        return sharedInstance(self)
    }
    
    class func deleteInstance() {
        Singleton.instances[self.className()] = nil
    }
    
    private class func sharedInstance<T: SharableObject>(type: T.Type) -> T {
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