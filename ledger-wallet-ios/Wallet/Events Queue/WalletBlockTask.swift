//
//  WalletBlockTask.swift
//  ledger-wallet-ios
//
//  Created by Nicolas Bigot on 13/01/2016.
//  Copyright © 2016 Ledger. All rights reserved.
//

import Foundation

struct WalletBlockTask: WalletTaskType {
    
    let identifier: String
    private let block: () -> Void
    
    func process(completionQueue: NSOperationQueue, completion: () -> Void) {
        block()
        completion()
    }
    
    // MARK: Initialize
    
    init(identifier: String, block: () -> Void) {
        self.identifier = identifier
        self.block = block
    }
    
}