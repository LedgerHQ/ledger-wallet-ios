//
//  WalletUnspentOutputsCollector.swift
//  ledger-wallet-ios
//
//  Created by Nicolas Bigot on 24/02/2016.
//  Copyright © 2016 Ledger. All rights reserved.
//

import Foundation

enum WalletUnspentOutputsCollectorError: ErrorType {
    
    case InternalFailure
    case InsufficientFunds
    case AlreadyCollecting
    
}

final class WalletUnspentOutputsCollector {
    
    private var collecting = false
    private let storeProxy: WalletStoreProxy
    private let workingQueue = NSOperationQueue(name: "WalletUnspentOutputsCollector", maxConcurrentOperationCount: 1)
    private let logger = Logger.sharedInstance(name: "WalletUnspentOutputsCollector")
    
    var isCollecting: Bool {
        var collecting = false
        workingQueue.addOperationWithBlock() { [weak self] in
            guard let strongSelf = self else { return }
            
            collecting = strongSelf.collecting
        }
        workingQueue.waitUntilAllOperationsAreFinished()
        return collecting
    }
    
    func collectUnspentOutputs(accountIndex accountIndex: Int, amount: Int64, completionQueue: NSOperationQueue, completion: ([WalletUnspentTransactionOutput]?, WalletUnspentOutputsCollectorError?) -> Void) {
        workingQueue.addOperationWithBlock() { [weak self] in
            guard let strongSelf = self else { return }
            
            guard !strongSelf.collecting else {
                strongSelf.logger.error("Already collecting unspent outputs from another account, aborting")
                completionQueue.addOperationWithBlock() { completion(nil, .AlreadyCollecting) }
                return
            }
            
            strongSelf.logger.info("Collecting unspent outputs from account \(accountIndex) for amount \(amount)")
            strongSelf.collecting = true
            strongSelf.storeProxy.fetchUnspentTransactionOutputsFromAccountAtIndex(accountIndex, completionQueue: strongSelf.workingQueue) { [weak self] outputs in
                guard let strongSelf = self else { return }
                guard strongSelf.collecting else { return }
                
                guard let outputs = outputs else {
                    strongSelf.logger.error("Failed to fetch unspent outputs, aborting")
                    strongSelf.collecting = false
                    completionQueue.addOperationWithBlock() { completion(nil, .InternalFailure) }
                    return
                }
                
                strongSelf.logger.info("Fetched \(outputs.count) unspent output(s), checking if balance is enough")
                strongSelf.processCollectedUnspentOutputs(accountIndex: accountIndex, outputs: outputs, amount: amount, completionQueue: completionQueue, completion: completion)
            }
        }
    }
    
    private func processCollectedUnspentOutputs(accountIndex accountIndex: Int, outputs: [WalletUnspentTransactionOutput], amount: Int64, completionQueue: NSOperationQueue, completion: ([WalletUnspentTransactionOutput]?, WalletUnspentOutputsCollectorError?) -> Void) {
        var collectedOutputs: [WalletUnspentTransactionOutput] = []
        
        // collect required amount
        var collectedAmount: Int64 = 0
        for output in outputs where collectedAmount < amount {
            collectedOutputs.append(output)
            collectedAmount += output.output.value
        }
        
        // check amount
        guard collectedAmount >= amount else {
            logger.warn("Not enough funds \(collectedAmount) to collect unspent outputs, aborting")
            collecting = false
            completionQueue.addOperationWithBlock() { completion(nil, .InsufficientFunds) }
            return
        }
        
        logger.info("Successfully collected unspent outputs")
        collecting = false
        completionQueue.addOperationWithBlock() { completion(collectedOutputs, nil) }
    }
    
    // MARK: Initialization
    
    init(storeProxy: WalletStoreProxy) {
        self.storeProxy = storeProxy
    }
    
}