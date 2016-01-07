//
//  WalletTransactionsStreamSaveFunnel.swift
//  ledger-wallet-ios
//
//  Created by Nicolas Bigot on 17/12/2015.
//  Copyright © 2015 Ledger. All rights reserved.
//

import Foundation

protocol WalletTransactionsStreamSaveFunnelDelegate: class {
    
    func saveFunnelDidUpdateTransactions(saveFunnel: WalletTransactionsStreamSaveFunnel)
    func saveFunnelDidUpdateAccountOperations(saveFunnel: WalletTransactionsStreamSaveFunnel)
    func saveFunnerDidUpdateAccountBalances(saveFunnel: WalletTransactionsStreamSaveFunnel)
    
}

final class WalletTransactionsStreamSaveFunnel: WalletTransactionsStreamFunnelType {
    
    weak var delegate: WalletTransactionsStreamSaveFunnelDelegate?
    private let storeProxy: WalletStoreProxy
    private var wroteTransactionsSinceLastFlush = false
    private var wroteOperationsSinceLastFlush = false
    
    func process(context: WalletTransactionsStreamContext, completion: (Bool) -> Void) {
        // write transactions
        storeProxy.storeTransactions([context.remoteTransaction])
        wroteTransactionsSinceLastFlush = true
        
        // write operations
        let operations = context.sendOperations + context.receiveOperations
        if operations.count > 0 {
            storeProxy.storeOperations(operations)
            wroteOperationsSinceLastFlush = true
        }
        
        // write double spend conflicts
        if context.doubleSpendConflicts.count > 0 {
            storeProxy.addDoubleSpendConflicts(context.doubleSpendConflicts)
        }
        completion(true)
    }

    func flush() {
        if wroteTransactionsSinceLastFlush {
            delegate?.saveFunnelDidUpdateTransactions(self)
        }
        if wroteOperationsSinceLastFlush {
            delegate?.saveFunnelDidUpdateAccountOperations(self)
        }
        if wroteTransactionsSinceLastFlush || wroteOperationsSinceLastFlush {
            storeProxy.updateAllAccountBalances()
            delegate?.saveFunnerDidUpdateAccountBalances(self)
        }
        wroteTransactionsSinceLastFlush = false
        wroteOperationsSinceLastFlush = false
    }
    
    // MARK: Initialization
    
    init(storeProxy: WalletStoreProxy, addressCache: WalletAddressCache, layoutHolder: WalletLayoutHolder, callingQueue: NSOperationQueue) {
        self.storeProxy = storeProxy
    }
    
}