//
//  BaseWalletManager.swift
//  ledger-wallet-ios
//
//  Created by Nicolas Bigot on 02/12/2015.
//  Copyright © 2015 Ledger. All rights reserved.
//

import Foundation

protocol BaseWalletManager: class {
    
    var uniqueIdentifier: String { get }
    
    init(uniqueIdentifier: String)
    func refreshTransactions()
    
}