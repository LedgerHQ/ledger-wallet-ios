//
//  WalletBalanceUpdater.swift
//  ledger-wallet-ios
//
//  Created by Nicolas Bigot on 07/01/2016.
//  Copyright © 2016 Ledger. All rights reserved.
//

import Foundation

protocol WalletBalanceUpdaterDelegate: class {
    
    func balanceUpdaterDidUpdateAccountBalances(balanceUpdater: WalletBalanceUpdater)
    
}

final class WalletBalanceUpdater {
    
    weak var delegate: WalletBalanceUpdaterDelegate?
    private let workingQueue = NSOperationQueue(name: "WalletBalanceUpdater", maxConcurrentOperationCount: 1)
    private let logger = Logger.sharedInstance(name: "WalletBalanceUpdater")
    private let storeProxy: WalletStoreProxy
    private let delegateQueue: NSOperationQueue
    private var updatingBalance = false
    
    func updateAccountBalances() {
        workingQueue.addOperationWithBlock() { [weak self] in
            guard let strongSelf = self else { return }
            guard !strongSelf.updatingBalance else { return }
            
            // mark begin of update
            strongSelf.updatingBalance = true
            
            // fetch all accounts to compute balances
            strongSelf.logger.info("Received request to update balance of all accounts")
            strongSelf.fetchAllAccounts()
        }
    }
    
    private func fetchAllAccounts() {
        storeProxy.fetchAllAccounts(workingQueue) { [weak self] accounts in
            guard let strongSelf = self else { return }
            
            // check that we got accounts
            guard let accounts = accounts else {
                strongSelf.logger.error("Unable to fetch accounts to update balances, aborting")
                strongSelf.updatingBalance = false
                return
            }
            
            // if there are accounts to update
            guard accounts.count > 0 else {
                strongSelf.logger.info("No accounts to compute balance, aborting")
                strongSelf.updatingBalance = false
                return
            }
            
            // update balance
            strongSelf.updateBalanceOfAccounts(accounts)
        }
    }
    
    private func updateBalanceOfAccounts(accounts: [WalletAccount]) {
        storeProxy.updateBalanceOfAccounts(accounts, completionQueue: workingQueue) { [weak self] success in
            guard let strongSelf = self else { return }

            if success {
                strongSelf.logger.info("Successully updated balance of all accounts")
                strongSelf.delegate?.balanceUpdaterDidUpdateAccountBalances(strongSelf)
            }
            else {
                strongSelf.logger.error("Failed to update balance of all accounts")
            }
            strongSelf.updatingBalance = false
        }
    }

    // MARK: Initialization
    
    init(storeProxy: WalletStoreProxy, delegateQueue: NSOperationQueue) {
        self.storeProxy = storeProxy
        self.delegateQueue = delegateQueue
    }
    
}