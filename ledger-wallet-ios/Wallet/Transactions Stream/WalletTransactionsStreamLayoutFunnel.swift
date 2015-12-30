//
//  WalletTransactionsStreamLayoutFunnel.swift
//  ledger-wallet-ios
//
//  Created by Nicolas Bigot on 16/12/2015.
//  Copyright © 2015 Ledger. All rights reserved.
//

import Foundation

protocol WalletTransactionsStreamLayoutFunnelDelegate: class {
    
    func layoutFunnel(layoutfunnel: WalletTransactionsStreamLayoutFunnel, didMissAccountAtIndex index: Int, continueBlock: (Bool) -> Void)
    
}

final class WalletTransactionsStreamLayoutFunnel: WalletTransactionsStreamFunnelType {

    weak var delegate: WalletTransactionsStreamLayoutFunnelDelegate?
    private let layoutHolder: WalletLayoutHolder
    private let callingQueue: NSOperationQueue
    private let logger = Logger.sharedInstance(name: "WalletTransactionsStreamLayoutFunnel")
    
    func process(context: WalletTransactionsStreamContext, completion: (Bool) -> Void) {
        // update internal and external indexes
        for (output, address) in context.mappedOutputs {
            
        }
        completion(true)
    }
    
    // MARK: Initialization
    
    init(storeProxy: WalletStoreProxy, addressCache: WalletAddressCache, layoutHolder: WalletLayoutHolder, callingQueue: NSOperationQueue) {
        self.callingQueue = callingQueue
        self.layoutHolder = layoutHolder
    }

}