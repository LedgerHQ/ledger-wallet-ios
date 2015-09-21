//
//  SharableObject.swift
//  ledger-wallet-ios
//
//  Created by Nicolas Bigot on 27/01/2015.
//  Copyright (c) 2015 Ledger. All rights reserved.
//

import Foundation

class SharableObject: NSObject {
    
    private static var instances: [String: SharableObject] = [:]

    // MARK: - Singleton
    
    class func sharedInstance() -> Self {
        return sharedInstance(self)
    }

    private class func sharedInstance<T: SharableObject>(type: T.Type) -> T {       
        let className = self.className()
        objc_sync_enter(self)
        if self.instances[className] == nil {
            self.instances[className] = self.init()
        }
        let instance = instances[className] as! T
        objc_sync_exit(self)
        return instance
    }

    override required init() {
   
    }
    
}