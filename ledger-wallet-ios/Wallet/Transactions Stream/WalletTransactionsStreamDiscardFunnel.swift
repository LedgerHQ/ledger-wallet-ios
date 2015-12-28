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
            logger.warn("Got transaction with empty addresses, aborting")
            completion(false)
            return
        }
        
        // fetch addresses from cache
        addressCache.addressesWithAddresses(allAddresses) { [weak self] addresses in
            guard let strongSelf = self else { return }
            
            guard let addresses = addresses else {
                strongSelf.logger.error("Unable to fetch addresses from transaction addresses, aborting")
                completion(false)
                return
            }
            
            guard addresses.count > 0 else {
                strongSelf.logger.info("Unknown transaction from wallet, aborting")
                completion(false)
                return
            }
            
            strongSelf.mapAddresses(addresses, toTransactionInContext: context)
            completion(true)
        }
    }
    
    func flush() {
        
    }
    
    private func mapAddresses(addresses: [WalletAddressModel], toTransactionInContext context: WalletTransactionsStreamContext) {
        for input in context.transaction.inputs {
            if let input = input as? WalletRemoteTransactionRegularInput, address = input.address, addressModel = addressWithAddress(address, fromBucket: addresses) {
                context.mappedInputs[input] = addressModel
            }
        }
        for output in context.transaction.outputs {
            if let address = output.address, addressModel = addressWithAddress(address, fromBucket: addresses) {
                context.mappedOutputs[output] = addressModel
            }
        }
        if context.mappedInputs.count + context.mappedOutputs.count < addresses.count {
            logger.error("Mapped \(context.mappedInputs.count + context.mappedOutputs.count) addresses but found \(addresses.count) from store")
        }
    }
    
    private func addressWithAddress(address: String, fromBucket addresses: [WalletAddressModel]) -> WalletAddressModel? {
        return addresses.filter({ $0.address == address }).first
    }
    
    // MARK: Initialization
    
    init(store: SQLiteStore, callingQueue: NSOperationQueue) {
        self.addressCache = WalletAddressCache(store: store, delegateQueue: callingQueue)
    }
    
}