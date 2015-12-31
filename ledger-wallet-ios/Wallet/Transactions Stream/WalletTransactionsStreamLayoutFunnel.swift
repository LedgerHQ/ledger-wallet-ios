//
//  WalletTransactionsStreamLayoutFunnel.swift
//  ledger-wallet-ios
//
//  Created by Nicolas Bigot on 16/12/2015.
//  Copyright © 2015 Ledger. All rights reserved.
//

import Foundation

protocol WalletTransactionsStreamLayoutFunnelDelegate: class {
    
    func layoutFunnelDidUpdateLayout(layoutfunnel: WalletTransactionsStreamLayoutFunnel)
    func layoutFunnel(layoutfunnel: WalletTransactionsStreamLayoutFunnel, didMissAccountAtIndex index: Int, continueBlock: (Bool) -> Void)
    
}

final class WalletTransactionsStreamLayoutFunnel: WalletTransactionsStreamFunnelType {

    weak var delegate: WalletTransactionsStreamLayoutFunnelDelegate?
    private let layoutHolder: WalletLayoutHolder
    private let addressCache: WalletAddressCache
    private let callingQueue: NSOperationQueue
    private let logger = Logger.sharedInstance(name: "WalletTransactionsStreamLayoutFunnel")
    
    func process(context: WalletTransactionsStreamContext, completion: (Bool) -> Void) {
        // update internal and external indexes
        updateAccountIndexes(context)
        
        // check that transaction affects observable account
        checkObservableAccount(context)
        
        completion(true)
    }
    
    private func checkObservableAccount(context: WalletTransactionsStreamContext) {
        // TODO:
    }
    
    private func updateAccountIndexes(context: WalletTransactionsStreamContext) {
        for (_, address) in context.mappedOutputs {
            if address.path.isExternal {
                if layoutHolder.externalIndex(address.path.keyIndex, isInsideObservableRangeForAccountAtIndex: address.path.accountIndex) {
                    // bump external index
                    layoutHolder.setNextExternalIndex(address.path.keyIndex + 1, forAccountAtIndex: address.path.accountIndex)
                    
                    // cache new addresses
                    if let range = layoutHolder.observableExternalRangeForAccountAtIndex(address.path.accountIndex) {
                        let paths = range.map({ return address.path.pathWithKeyIndex($0) })
                        if let first = paths.first, last = paths.last {
                            logger.info("Caching new external addresses for range \(first.rangeStringToKeyIndex(last.keyIndex))")
                            addressCache.fetchOrDeriveAddressesAtPaths(paths, queue: callingQueue, completion: { _ in })
                        }
                    }
                    
                    delegate?.layoutFunnelDidUpdateLayout(self)
                }
            }
            else {
                if layoutHolder.internalIndex(address.path.keyIndex, isInsideObservableRangeForAccountAtIndex: address.path.accountIndex) {
                    // bump internal index
                    layoutHolder.setNextInternalIndex(address.path.keyIndex + 1, forAccountAtIndex: address.path.accountIndex)
                    
                    // cache new addresses
                    if let range = layoutHolder.observableInternalRangeForAccountAtIndex(address.path.accountIndex) {
                        let paths = range.map({ return address.path.pathWithKeyIndex($0) })
                        if let first = paths.first, last = paths.last {
                            logger.info("Caching new internal addresses for range \(first.rangeStringToKeyIndex(last.keyIndex))")
                            addressCache.fetchOrDeriveAddressesAtPaths(paths, queue: callingQueue, completion: { _ in })
                        }
                    }
                    
                    delegate?.layoutFunnelDidUpdateLayout(self)
                }
            }
        }
    }
    
    // MARK: Initialization
    
    init(storeProxy: WalletStoreProxy, addressCache: WalletAddressCache, layoutHolder: WalletLayoutHolder, callingQueue: NSOperationQueue) {
        self.layoutHolder = layoutHolder
        self.addressCache = addressCache
        self.callingQueue = callingQueue
    }

}