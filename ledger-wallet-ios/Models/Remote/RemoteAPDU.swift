//
//  RemoteAPDU.swift
//  ledger-wallet-ios
//
//  Created by Nicolas Bigot on 04/02/2016.
//  Copyright © 2016 Ledger. All rights reserved.
//

import Foundation

struct RemoteAPDU {
    
    let data: NSData
    
    // MARK: Initialization
    
    init?(data: NSData) {
        guard data.length > 0 && data.length <= Int(UInt16.max) else {
            return nil
        }
        self.data = data
    }
    
    init?(hexString: String) {
        self.init(data: BTCDataFromHex(hexString))
    }
    
}