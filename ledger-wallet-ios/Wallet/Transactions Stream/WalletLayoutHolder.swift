//
//  WalletLayoutHolder.swift
//  ledger-wallet-ios
//
//  Created by Nicolas Bigot on 14/12/2015.
//  Copyright © 2015 Ledger. All rights reserved.
//

import Foundation

final class WalletLayoutHolder {
    
    static let BIP44AddressesGap = 20
    
    private let storeProxy: WalletStoreProxy
    private var accounts: [WalletAccount] = []
    private let workingQueue = NSOperationQueue(name: "WalletLayoutHolder", maxConcurrentOperationCount: 1)
    private let logger = Logger.sharedInstance(name: "WalletLayoutHolder")
    
    // MARK: Indexes management
    
    var observableAccountIndex: Int? {
        var value: Int? = nil
        workingQueue.addOperationWithBlock() { [weak self] in
            guard let strongSelf = self else { return }
            strongSelf.accounts.forEach() { account in
                if account.nextExternalIndex == 0 && account.nextInternalIndex == 0 {
                    value = account.index
                    return
                }
            }
        }
        workingQueue.waitUntilAllOperationsAreFinished()
        return value
    }
    
    func externalIndex(index: Int, isInsideObservableRangeForAccountAtIndex accountIndex: Int) -> Bool {
        guard let range = observableExternalRangeForAccountAtIndex(accountIndex) else { return false }
        return range.contains(index)
    }
    
    func internalIndex(index: Int, isInsideObservableRangeForAccountAtIndex accountIndex: Int) -> Bool {
        guard let range = observableInternalRangeForAccountAtIndex(accountIndex) else { return false }
        return range.contains(index)
    }
    
    func nextExternalIndexForAccountAtIndex(index: Int) -> Int? {
        return nextIndexForAccountAtIndex(index, external: true)
    }
    
    func nextInternalIndexForAccountAtIndex(index: Int) -> Int? {
        return nextIndexForAccountAtIndex(index, external: false)
    }
    
    func setNextExternalIndex(index: Int, forAccountAtIndex accountIndex: Int) {
        setNextIndex(index, forAccountAtIndex: accountIndex, external: true)
    }
    
    func setNextInternalIndex(index: Int, forAccountAtIndex accountIndex: Int) {
        setNextIndex(index, forAccountAtIndex: accountIndex, external: false)
    }
    
    func observableExternalRangeForAccountAtIndex(index: Int) -> Range<Int>? {
        return observableRangeForAccountAtIndex(index, external: true)
    }
    
    func observableInternalRangeForAccountAtIndex(index: Int) -> Range<Int>? {
        return observableRangeForAccountAtIndex(index, external: false)
    }
    
    private func nextIndexForAccountAtIndex(index: Int, external: Bool) -> Int? {
        var value: Int? = nil
        workingQueue.addOperationWithBlock() { [weak self] in
            guard let strongSelf = self else { return }
            guard strongSelf.accounts.count > index else {
                strongSelf.logger.error("Unable to fetch account \(index) to get next index")
                return
            }
            
            // fetch index
            let account = strongSelf.accounts[index]
            value = external ? account.nextExternalIndex : account.nextInternalIndex
        }
        workingQueue.waitUntilAllOperationsAreFinished()
        return value
    }
    
    private func setNextIndex(index: Int, forAccountAtIndex accountIndex: Int, external: Bool) {
        workingQueue.addOperationWithBlock() { [weak self] in
            guard let strongSelf = self else { return }
            guard strongSelf.accounts.count > accountIndex else {
                strongSelf.logger.error("Unable to fetch account \(accountIndex) to set next index")
                return
            }
            
            // make sure we do not override a current index
            let account = strongSelf.accounts[accountIndex]
            if external {
                guard index > account.nextExternalIndex else {
                    strongSelf.logger.warn("Setting next external index \(index) <= than current index \(account.nextExternalIndex) for account at index \(accountIndex), ignoring")
                    return
                }
            }
            else {
                guard index > account.nextInternalIndex else {
                    strongSelf.logger.warn("Setting next internal index \(index) <= than current index \(account.nextInternalIndex) for account at index \(accountIndex), ignoring")
                    return
                }
            }
            
            // store new index
            strongSelf.logger.info("Setting next \(external ? "external" : "internal") index \(index) for account at index \(accountIndex)")
            if external {
                strongSelf.accounts[accountIndex] = strongSelf.accounts[accountIndex].withNextExternalIndex(index)
                strongSelf.storeProxy.setNextExternalIndex(index, forAccountAtIndex: accountIndex)
            }
            else {
                strongSelf.accounts[accountIndex] = strongSelf.accounts[accountIndex].withNextInternalIndex(index)
                strongSelf.storeProxy.setNextInternalIndex(index, forAccountAtIndex: accountIndex)
            }
        }
    }
    
    private func observableRangeForAccountAtIndex(index: Int, external: Bool) -> Range<Int>? {
        guard let index = nextIndexForAccountAtIndex(index, external: external) else { return nil }
        return index...index + self.dynamicType.BIP44AddressesGap - 1
    }
    
    // MARK: Restoration
    
    func reload() {
        workingQueue.addOperationWithBlock() { [weak self] in
            guard let strongSelf = self else { return }
        
            strongSelf.storeProxy.fetchAllAccounts() { [weak self] accounts in
                guard let strongSelf = self else { return }
                
                // ensure we fetched accounts
                guard let accounts = accounts else {
                    strongSelf.logger.error("Unable to reload all accounts from store")
                    return
                }
                
                strongSelf.accounts = accounts
                strongSelf.logger.info("Successfully reloaded \(accounts.count) accounts from store")
            }
        }
    }
    
    // MARK: Initialization
    
    init(store: SQLiteStore) {
        self.storeProxy = WalletStoreProxy(store: store, delegateQueue: workingQueue)
        reload()
    }
    
}