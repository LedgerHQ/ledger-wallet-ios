//
//  WalletStoreBlockTask.swift
//  ledger-wallet-ios
//
//  Created by Nicolas Bigot on 20/01/2016.
//  Copyright © 2016 Ledger. All rights reserved.
//

import Foundation

struct WalletStoreBlockTask: WalletTaskType {
    
    let identifier = "WalletStoreBlockTask"
    private let block: WalletBlockContainer
    private weak var blocksStream: WalletBlocksStream?
    
    func process(completionQueue: NSOperationQueue, completion: () -> Void) {
        guard let blocksStream = blocksStream else {
            completion()
            return
        }
        blocksStream.processBlock(block, completionQueue: completionQueue, completion: completion)
    }
    
    // MARK: Initialization
    
    init(block: WalletBlockContainer, blocksStream: WalletBlocksStream) {
        self.block = block
        self.blocksStream = blocksStream
    }
    
}