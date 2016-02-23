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
    let source: WalletTaskSource?
    private let block: (completion: () -> Void) -> Void
    
    func process(completionQueue: NSOperationQueue, completion: () -> Void) {
        block(completion: completion)
    }
    
    // MARK: Initialize
    
    init(identifier: String, source: WalletTaskSource?, block: (completion: () -> Void) -> Void) {
        self.identifier = identifier
        self.source = source
        self.block = block
    }
    
}