//
//  WalletTaskType.swift
//  ledger-wallet-ios
//
//  Created by Nicolas Bigot on 12/01/2016.
//  Copyright © 2016 Ledger. All rights reserved.
//

import Foundation

protocol WalletTaskType {
    
    var identifier: String { get }
    
    func process(completionQueue: NSOperationQueue, completion: () -> Void)
    
}