//
//  WalletBalanceUpdater.swift
//  ledger-wallet-ios
//
//  Created by Nicolas Bigot on 07/01/2016.
//  Copyright © 2016 Ledger. All rights reserved.
//

import Foundation

final class WalletBalanceUpdater {
    
    private let workingQueue = NSOperationQueue(name: "WalletBalanceUpdater", maxConcurrentOperationCount: 1)
    private let logger = Logger.sharedInstance(name: "WalletBalanceUpdater")
    private let storeProxy: WalletStoreProxy
    private var updatingBalance = false
    
    var isUpdating: Bool {
        var updatingBalance = false
        workingQueue.addOperationWithBlock() { [weak self] in
            guard let strongSelf = self else { return }

            updatingBalance = strongSelf.updatingBalance
        }
        workingQueue.waitUntilAllOperationsAreFinished()
        return updatingBalance
    }
    
    func updateAccountBalances(completionQueue completionQueue: NSOperationQueue, completion: (updated: Bool) -> Void) {
        workingQueue.addOperationWithBlock() { [weak self] in
            guard let strongSelf = self else { return }
            guard !strongSelf.updatingBalance else { return }
            
            // mark begin of update
            strongSelf.updatingBalance = true
            
            // fetch all accounts to compute balances
            strongSelf.logger.info("Received request to update balance of all accounts")
            strongSelf.fetchAllAccounts(completionQueue, completion: completion)
        }
    }
    
    private func fetchAllAccounts(completionQueue: NSOperationQueue, completion: (updated: Bool) -> Void) {
        workingQueue.addOperationWithBlock() { [weak self] in
            guard let strongSelf = self else { return }
            guard strongSelf.updatingBalance else { return }

            strongSelf.storeProxy.fetchAllAccounts(strongSelf.workingQueue) { [weak self] accounts in
                guard let strongSelf = self else { return }
                guard strongSelf.updatingBalance else { return }
                
                // check that we got accounts
                guard let accounts = accounts else {
                    strongSelf.logger.error("Unable to fetch accounts to update balances, aborting")
                    strongSelf.updatingBalance = false
                    completionQueue.addOperationWithBlock() { completion(updated: false) }
                    return
                }
                
                // if there are accounts to update
                guard accounts.count > 0 else {
                    strongSelf.logger.info("No accounts to compute balance, aborting")
                    strongSelf.updatingBalance = false
                    completionQueue.addOperationWithBlock() { completion(updated: false) }
                    return
                }
                
                // update balance
                strongSelf.updateBalanceOfAccounts(accounts, completionQueue: completionQueue, completion: completion)
            }
        }
    }
    
    private func updateBalanceOfAccounts(accounts: [WalletAccount], completionQueue: NSOperationQueue, completion: (updated: Bool) -> Void) {
        workingQueue.addOperationWithBlock() { [weak self] in
            guard let strongSelf = self else { return }
            guard strongSelf.updatingBalance else { return }

            strongSelf.storeProxy.updateBalanceOfAccounts(accounts, completionQueue: strongSelf.workingQueue) { [weak self] success in
                guard let strongSelf = self else { return }
                guard strongSelf.updatingBalance else { return }
                
                strongSelf.updatingBalance = false
                if success {
                    strongSelf.logger.info("Successully updated balance of all accounts")
                    completionQueue.addOperationWithBlock() { completion(updated: true) }
                }
                else {
                    strongSelf.logger.error("Failed to update balance of all accounts")
                    completionQueue.addOperationWithBlock() { completion(updated: false) }
                }
            }
        }
    }

    // MARK: Initialization
    
    init(storeProxy: WalletStoreProxy) {
        self.storeProxy = storeProxy
    }
    
}