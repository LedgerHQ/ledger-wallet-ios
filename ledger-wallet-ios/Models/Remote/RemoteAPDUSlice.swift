//
//  RemoteAPDUSlice.swift
//  ledger-wallet-ios
//
//  Created by Nicolas Bigot on 04/02/2016.
//  Copyright © 2016 Ledger. All rights reserved.
//

import Foundation

struct RemoteAPDUSlice {
    
    let index: Int
    let data: NSData
    
    // MARK: Initialization
    
    init(index: Int, data: NSData) {
        self.index = index
        self.data = data
    }
    
}