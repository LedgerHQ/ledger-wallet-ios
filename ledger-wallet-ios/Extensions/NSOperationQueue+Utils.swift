//
//  NSOperationQueue+Utils.swift
//  ledger-wallet-ios
//
//  Created by Nicolas Bigot on 08/12/2015.
//  Copyright © 2015 Ledger. All rights reserved.
//

import Foundation

extension NSOperationQueue {
    
    convenience init(maxConcurrentOperationCount: Int) {
        self.init(name: nil, maxConcurrentOperationCount: maxConcurrentOperationCount)
    }
    
    convenience init(name: String?, maxConcurrentOperationCount: Int) {
        self.init()
        self.name = name
        self.maxConcurrentOperationCount = maxConcurrentOperationCount
    }
    
}