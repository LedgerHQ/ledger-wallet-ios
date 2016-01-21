//
//  WalletBlocksStream.swift
//  ledger-wallet-ios
//
//  Created by Nicolas Bigot on 20/01/2016.
//  Copyright © 2016 Ledger. All rights reserved.
//

import Foundation

protocol WalletBlocksStreamDelegate: class {
    
    func blocksStreamDidUpdateTransactions(blocksStream: WalletBlocksStream)
    
}

final class WalletBlocksStream {
    
    weak var delegate: WalletBlocksStreamDelegate?
    private let delegateQueue: NSOperationQueue
    private let workingQueue = NSOperationQueue(name: "WalletBlocksStream", maxConcurrentOperationCount: 1)
    private let logger = Logger.sharedInstance(name: "WalletBlocksStream")
    private let storeProxy: WalletStoreProxy
    
    // MARK: Blocks management
    
    func processBlock(block: WalletBlockContainer, completionQueue: NSOperationQueue, completion: () -> Void) {
        logger.info("Received new block \(block.block.hash) with \(block.transactionHashes.count) transaction(s)")
        
        workingQueue.addOperationWithBlock() { [weak self] in
            guard let strongSelf = self else { return }
            
            strongSelf.checkIfBlockConfirmsKnownTransactions(block, completionQueue: completionQueue, completion: completion)
        }
    }
    
    private func checkIfBlockConfirmsKnownTransactions(block: WalletBlockContainer, completionQueue: NSOperationQueue, completion: () -> Void) {
        logger.info("Checking if block \(block.block.hash) confirms known transactions")
        
        storeProxy.countTransactionsWithHashes(block.transactionHashes, completionQueue: workingQueue) { [weak self] count in
            guard let strongSelf = self else { return }
            
            guard let count = count else {
                strongSelf.logger.error("Unable to count transactions affected by block \(block.block.hash), aborting")
                completionQueue.addOperationWithBlock() { completion() }
                return
            }
            
            guard count > 0 else {
                strongSelf.logger.info("Block \(block.block.hash) does not affect any known transactions, aborting")
                completionQueue.addOperationWithBlock() { completion() }
                return
            }
            
            strongSelf.storeBlockInDatabase(block, affectedCount: count, completionQueue: completionQueue, completion: completion)
        }
    }
    
    private func storeBlockInDatabase(block: WalletBlockContainer, affectedCount: Int, completionQueue: NSOperationQueue, completion: () -> Void) {
        logger.info("Confirming \(affectedCount) transaction(s) out of \(block.transactionHashes.count) from block \(block.block.hash)")
        
        storeProxy.storeBlocks([block], completionQueue: workingQueue) { [weak self] success in
            guard let strongSelf = self else { return }

            if !success {
                strongSelf.logger.error("Unable to confirm \(affectedCount) transaction(s) out of \(block.transactionHashes.count) from block \(block.block.hash), aborting")
            }
            else {
                strongSelf.delegateQueue.addOperationWithBlock() { [weak self] in
                    guard let strongSelf = self else { return }
                    strongSelf.delegate?.blocksStreamDidUpdateTransactions(strongSelf)
                }
            }
            completionQueue.addOperationWithBlock() { completion() }
        }
    }
    
    // MARK: Initialization
    
    init(storeProxy: WalletStoreProxy, delegateQueue: NSOperationQueue) {
        self.storeProxy = storeProxy
        self.delegateQueue = delegateQueue
    }
    
}