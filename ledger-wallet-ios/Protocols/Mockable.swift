//
//  Mockable.swift
//  ledger-wallet-ios
//
//  Created by Nicolas Bigot on 11/02/2015.
//  Copyright (c) 2015 Ledger. All rights reserved.
//

import Foundation

protocol Mockable {
    
    static func testObject() -> Self
    
}