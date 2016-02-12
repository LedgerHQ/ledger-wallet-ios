//
//  NSMutableData+Utils.swift
//  ledger-wallet-ios
//
//  Created by Nicolas Bigot on 11/02/2016.
//  Copyright © 2016 Ledger. All rights reserved.
//

import Foundation

extension NSMutableData {
    
    func appendByte(var byte: UInt8) {
        self.appendBytes(&byte, length: 1)
    }
    
}