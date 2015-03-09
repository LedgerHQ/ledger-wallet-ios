//
//  ApplicationManager.swift
//  ledger-wallet-ios
//
//  Created by Nicolas Bigot on 13/02/2015.
//  Copyright (c) 2015 Ledger. All rights reserved.
//

import Foundation

class ApplicationManager: BaseManager {
    
    class func isInDebug() -> Bool {
        #if DEBUG
            return true
            #else
            return false
        #endif
    }
    
    class func isInProduction() -> Bool {
        return !isInDebug()
    }
    
}