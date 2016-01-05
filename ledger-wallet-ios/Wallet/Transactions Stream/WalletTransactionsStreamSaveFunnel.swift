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
    private static let writeBatchSize = 200
    private let storeProxy: WalletStoreProxy
    private var pendingTransactions: [WalletTransactionContainer] = []
    private var pendingOperations: [WalletOperation] = []
    private let logger = Logger.sharedInstance(name: "WalletTransactionsStreamSaveFunnel")
    
    func process(context: WalletTransactionsStreamContext, completion: (Bool) -> Void) {
        // write transaction
        pendingTransactions.append(context.remoteTransaction)
        while writeTransactionsIfNeeded() {}
        
        // write operations
        pendingOperations.appendContentsOf(context.sendOperations)
        pendingOperations.appendContentsOf(context.receiveOperations)
        while writeOperationsIfNeeded() {}
        completion(true)
    }
    
    func flush() {
        // flush transactions
        while writeTransactionsIfNeeded() {}
        if pendingTransactions.count > 0 {
            writeTransactions(pendingTransactions)
            pendingTransactions = []
        }

        // flush operations
        while writeOperationsIfNeeded() {}
        if pendingOperations.count > 0 {
            writeOperations(pendingOperations)
            pendingOperations = []
        }
    }
    
    // MARK: Transactions management
    
    private func writeTransactionsIfNeeded() -> Bool {
        guard pendingTransactions.count >= self.dynamicType.writeBatchSize else {
            return false
        }
        
        let transactions = Array(pendingTransactions.prefix(self.dynamicType.writeBatchSize))
        pendingTransactions.removeFirst(self.dynamicType.writeBatchSize)
        writeTransactions(transactions)
        return true
    }
    
    private func writeTransactions(transactions: [WalletTransactionContainer]) {
        guard transactions.count > 0 else { return }

        logger.info("Writing batch of \(transactions.count) transaction(s) to store")
        storeProxy.storeTransactions(transactions)
        delegate?.saveFunnelDidUpdateTransactions(self)
        
        logger.info("Updating balance of all accounts")
        storeProxy.updateAllAccountBalances()
        delegate?.saveFunnerDidUpdateAccountBalances(self)
    }
    
    // MARK: Operations management
    
    private func writeOperationsIfNeeded() -> Bool {
        guard pendingOperations.count >= self.dynamicType.writeBatchSize else {
            return false
        }
        
        let operations = Array(pendingOperations.prefix(self.dynamicType.writeBatchSize))
        pendingOperations.removeFirst(self.dynamicType.writeBatchSize)
        writeOperations(operations)
        return true
    }
    
    private func writeOperations(operations: [WalletOperation]) {
        guard operations.count > 0 else { return }
        
        logger.info("Writing batch of \(operations.count) operation(s) to store")
        storeProxy.storeOperations(operations)
        delegate?.saveFunnelDidUpdateAccountOperations(self)
    }
    
    // MARK: Initialization
    
    init(storeProxy: WalletStoreProxy, addressCache: WalletAddressCache, layoutHolder: WalletLayoutHolder, callingQueue: NSOperationQueue) {
        self.storeProxy = storeProxy
    }
    
}