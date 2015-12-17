//
//  WalletTransactionsStreamSaveFunnel.swift
//  ledger-wallet-ios
//
//  Created by Nicolas Bigot on 17/12/2015.
//  Copyright © 2015 Ledger. All rights reserved.
//

import Foundation

final class WalletTransactionsStreamSaveFunnel: WalletTransactionsStreamFunnelType {
    
    private static let writeBatchSize = 100
    private let storeProxy: WalletStoreProxy
    private var pendingTransactions: [WalletRemoteTransaction] = []
    private let logger = Logger.sharedInstance(name: "WalletTransactionsStreamSaveFunnel")
    
    func process(context: WalletTransactionsStreamContext, completion: (Bool) -> Void) {
        pendingTransactions.append(context.transaction)
        while writeTransactionsIfNeeded() {}
        completion(true)
    }
    
    func flush() {
        while writeTransactionsIfNeeded() {}
        if pendingTransactions.count > 0 {
            logger.info("Writting transaction batch (\(pendingTransactions.count)) to store")
            storeProxy.storeTransactions(pendingTransactions)
            pendingTransactions = []
        }
    }
    
    private func writeTransactionsIfNeeded() -> Bool {
        if pendingTransactions.count >= self.dynamicType.writeBatchSize {
            logger.info("Writting transaction batch (\(self.dynamicType.writeBatchSize)) to store")
            let transactions = Array(pendingTransactions.prefix(self.dynamicType.writeBatchSize))
            pendingTransactions.removeFirst(self.dynamicType.writeBatchSize)
            storeProxy.storeTransactions(transactions)
            return true
        }
        return false
    }
    
    // MARK: Initialization
    
    init(store: SQLiteStore, callingQueue: NSOperationQueue) {
        self.storeProxy = WalletStoreProxy(store: store, delegateQueue: callingQueue)
    }
    
}