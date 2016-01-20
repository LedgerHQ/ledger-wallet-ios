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
    
    func process(context: WalletTransactionsStreamContext, workingQueue: NSOperationQueue, completion: (Bool) -> Void) {
        let allAddresses = context.remoteTransaction.allAddresses
        guard allAddresses.count > 0 else {
            logger.warn("Got transaction with empty addresses, aborting")
            completion(false)
            return
        }
        
        // fetch addresses from cache
        addressCache.fetchAddressesWithAddresses(allAddresses, queue: workingQueue) { [weak self] addresses in
            guard let strongSelf = self else { return }
            
            guard let addresses = addresses else {
                strongSelf.logger.error("Unable to fetch addresses from transaction addresses, aborting")
                completion(false)
                return
            }
            
            guard addresses.count > 0 else {
                completion(false)
                return
            }
            
            strongSelf.mapAddresses(addresses, toTransactionInContext: context)
            completion(true)
        }
    }
    
    private func mapAddresses(addresses: [WalletAddress], toTransactionInContext context: WalletTransactionsStreamContext) {
        for input in context.remoteTransaction.inputs {
            if let address = input.address, addressModel = addressWithAddress(address, fromBucket: addresses) {
                context.mappedInputs[input] = addressModel
            }
        }
        for output in context.remoteTransaction.outputs {
            if let address = output.address, addressModel = addressWithAddress(address, fromBucket: addresses) {
                context.mappedOutputs[output] = addressModel
            }
        }
        if context.mappedInputs.count + context.mappedOutputs.count < addresses.count {
            logger.error("Mapped \(context.mappedInputs.count + context.mappedOutputs.count) addresses but found \(addresses.count) from store")
        }
    }
    
    private func addressWithAddress(address: String, fromBucket addresses: [WalletAddress]) -> WalletAddress? {
        return addresses.filter({ $0.address == address }).first
    }
    
    // MARK: Initialization
    
    init(addressCache: WalletAddressCache) {
        self.addressCache = addressCache
    }
    
}