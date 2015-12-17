//
//  WalletTransactionsStreamDiscardFunnel.swift
//  ledger-wallet-ios
//
//  Created by Nicolas Bigot on 16/12/2015.
//  Copyright © 2015 Ledger. All rights reserved.
//

import Foundation

final class WalletTransactionsStreamDiscardFunnel: WalletTransactionsStreamFunnelType {

    private let addressCache: WalletAddressCache
    private let logger = Logger.sharedInstance(name: "WalletTransactionsStreamDiscardFunnel")
    
    func process(context: WalletTransactionsStreamContext, completion: (Bool) -> Void) {
        let allAddresses = context.transaction.allAddresses
        guard allAddresses.count > 0 else {
            logger.error("Got transaction with empty addresses, continuing")
            completion(false)
            return
        }
        
        // fetch addresses from cache
        addressCache.addressesWithAddresses(allAddresses) { [weak self] addresses in
            guard let strongSelf = self else { return }
            
            guard let addresses = addresses else {
                strongSelf.logger.error("Unable to fetch addresses from transaction addresses, continuing")
                completion(false)
                return
            }
            
            guard addresses.count > 0 else {
                strongSelf.logger.info("Unknown transaction from wallet, continuing")
                completion(false)
                return
            }
            
            context.addresses = addresses
            completion(true)
        }
    }
    
    func flush() {
        
    }
    
    // MARK: Initialization
    
    init(store: SQLiteStore, callingQueue: NSOperationQueue) {
        self.addressCache = WalletAddressCache(store: store, delegateQueue: callingQueue)
    }
    
}