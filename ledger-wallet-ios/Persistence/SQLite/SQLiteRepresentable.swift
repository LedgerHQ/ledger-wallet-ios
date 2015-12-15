//
//  SQLiteRepresentable.swift
//  ledger-wallet-ios
//
//  Created by Nicolas Bigot on 30/11/2015.
//  Copyright © 2015 Ledger. All rights reserved.
//

import Foundation

protocol SQLiteRepresentable {
    
    var representativeStatement:String { get }
    
}