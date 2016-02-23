//
//  WalletTaskType.swift
//  ledger-wallet-ios
//
//  Created by Nicolas Bigot on 12/01/2016.
//  Copyright © 2016 Ledger. All rights reserved.
//

import Foundation

enum WalletTaskSource {
    
    case TransactionsConsumer
    case TransactionsListener
    
}

protocol WalletTaskType {
    
    var identifier: String { get }
    var source: WalletTaskSource? { get }
    
    func process(completionQueue: NSOperationQueue, completion: () -> Void)
    
}