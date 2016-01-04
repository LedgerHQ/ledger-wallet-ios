//
//  WalletTransactionsStreamLayoutFunnel.swift
//  ledger-wallet-ios
//
//  Created by Nicolas Bigot on 16/12/2015.
//  Copyright © 2015 Ledger. All rights reserved.
//

import Foundation

protocol WalletTransactionsStreamLayoutFunnelDelegate: class {
    
    func layoutFunnelDidUpdateAccountLayouts(layoutfunnel: WalletTransactionsStreamLayoutFunnel)
    func layoutFunnel(layoutfunnel: WalletTransactionsStreamLayoutFunnel, didMissAccountAtIndex index: Int, continueBlock: (Bool) -> Void)
    
}

final class WalletTransactionsStreamLayoutFunnel: WalletTransactionsStreamFunnelType {

    weak var delegate: WalletTransactionsStreamLayoutFunnelDelegate?
    private let layoutHolder: WalletLayoutHolder
    private let addressCache: WalletAddressCache
    private let storeProxy: WalletStoreProxy
    private let callingQueue: NSOperationQueue
    private let logger = Logger.sharedInstance(name: "WalletTransactionsStreamLayoutFunnel")
    
    func process(context: WalletTransactionsStreamContext, completion: (Bool) -> Void) {
        // check that transaction affects observable account
        checkObservableAccount(context) { [weak self] in
            guard let strongSelf = self else { return }
            
            // update internal and external indexes
            strongSelf.updateAccountIndexes(context)
            
            completion(true)
        }
    }
    
    private func checkObservableAccount(context: WalletTransactionsStreamContext, completion: () -> Void) {
        guard let observableAccountIndex = layoutHolder.observableAccountIndex else {
            completion()
            return
        }
        
        // check that outputs affects this account
        guard transactionReferencesObservableAccountAtIndex(observableAccountIndex, context: context) else {
            completion()
            return
        }
        
        // try to fetch account with observable index
        let nextAccountIndex = observableAccountIndex + 1
        logger.info("Transaction affects observable account at index \(observableAccountIndex), checking if next observable account \(nextAccountIndex) exists")
        storeProxy.fetchAccountAtIndex(nextAccountIndex, queue: callingQueue) { [weak self] account in
            guard let strongSelf = self else { return }
            
            // if the account exists
            if account != nil {
                strongSelf.logger.info("Next observable account \(nextAccountIndex) exists, continuing")
                completion()
                return
            }
        
            strongSelf.logger.warn("Unknown next observable account at index \(nextAccountIndex), asking delegate")
            strongSelf.askDelegateToProvideObservableAccountAtIndex(nextAccountIndex, completion: completion)
        }
    }
    
    private func askDelegateToProvideObservableAccountAtIndex(index: Int, completion: () -> Void) {
        guard let delegate = delegate else {
            logger.error("Unable to ask missing observable account to missing delegate, continuing")
            completion()
            return
        }
        
        let continueBlock = { [weak self] (retry: Bool) in
            guard let strongSelf = self else { return }
            
            if retry {
                // try to refetch account with observable index
                strongSelf.checkThatDelegateProvidedObservableAccountAtIndex(index, completion: completion)
            }
            else {
                strongSelf.logger.warn("Delegate failed to provide next observable account at index \(index), continuing")
                completion()
                return
            }
        }
        
        delegate.layoutFunnel(self, didMissAccountAtIndex: index, continueBlock: continueBlock)
    }
    
    private func checkThatDelegateProvidedObservableAccountAtIndex(index: Int, completion: () -> Void) {
        logger.info("Delegate provided account at index \(index), retrying")
        storeProxy.fetchAccountAtIndex(index, queue: callingQueue) { [weak self] account in
            guard let strongSelf = self else { return }
         
            if account != nil {
                strongSelf.logger.info("Next observable account at index \(index) found, continuing")
            }
            else {
                strongSelf.logger.error("Still no account at index \(index), continuing")
            }
            completion()
        }
    }
    
    private func transactionReferencesObservableAccountAtIndex(index: Int, context: WalletTransactionsStreamContext) -> Bool {
        for (_, address) in context.mappedOutputs where address.path.accountIndex == index {
            return true
        }
        return false
    }
    
    private func updateAccountIndexes(context: WalletTransactionsStreamContext) {
        for (_, address) in context.mappedOutputs {
            var updatedLayouts = false
            
            if address.path.isExternal {
                if layoutHolder.externalIndex(address.path.keyIndex, isInsideObservableRangeForAccountAtIndex: address.path.accountIndex) {
                    // bump external index
                    layoutHolder.setNextExternalIndex(address.path.keyIndex + 1, forAccountAtIndex: address.path.accountIndex)
                    updatedLayouts = true
                    
                    // cache new addresses
                    if let range = layoutHolder.observableExternalRangeForAccountAtIndex(address.path.accountIndex) {
                        let paths = range.map({ return address.path.pathWithKeyIndex($0) })
                        cacheAddressesAtPaths(paths, external: true)
                    }
                }
            }
            else {
                if layoutHolder.internalIndex(address.path.keyIndex, isInsideObservableRangeForAccountAtIndex: address.path.accountIndex) {
                    // bump internal index
                    layoutHolder.setNextInternalIndex(address.path.keyIndex + 1, forAccountAtIndex: address.path.accountIndex)
                    updatedLayouts = true
                    
                    // cache new addresses
                    if let range = layoutHolder.observableInternalRangeForAccountAtIndex(address.path.accountIndex) {
                        let paths = range.map({ return address.path.pathWithKeyIndex($0) })
                        cacheAddressesAtPaths(paths, external: false)
                    }
                }
            }
            
            if updatedLayouts {
                delegate?.layoutFunnelDidUpdateAccountLayouts(self)
            }
        }
    }
    
    private func cacheAddressesAtPaths(paths: [WalletAddressPath], external: Bool) {
        if let first = paths.first, last = paths.last {
            logger.info("Caching new \(external ? "external" : "internal") addresses for range \(first.rangeStringToKeyIndex(last.keyIndex))")
            addressCache.fetchOrDeriveAddressesAtPaths(paths, queue: callingQueue, completion: { _ in })
        }
    }
    
    // MARK: Initialization
    
    init(storeProxy: WalletStoreProxy, addressCache: WalletAddressCache, layoutHolder: WalletLayoutHolder, callingQueue: NSOperationQueue) {
        self.layoutHolder = layoutHolder
        self.addressCache = addressCache
        self.storeProxy = storeProxy
        self.callingQueue = callingQueue
    }

}