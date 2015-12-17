//
//  WalletTransactionsStream.swift
//  ledger-wallet-ios
//
//  Created by Nicolas Bigot on 06/12/2015.
//  Copyright © 2015 Ledger. All rights reserved.
//

import Foundation

final class WalletTransactionsStream {
    
    private var busy = false
    private var pendingTransactions: [WalletRemoteTransaction] = []
    private var funnels: [WalletTransactionsStreamFunnelType] = []
    private let delegateQueue: NSOperationQueue
    private let workingQueue = NSOperationQueue(name: "WalletTransactionsStream", maxConcurrentOperationCount: 1)
    private let logger = Logger.sharedInstance(name: "WalletTransactionsStream")
    
    // MARK: Transactions management
    
    func enqueueTransactions(transactions: [WalletRemoteTransaction]) {
        guard transactions.count > 0 else { return }
        
        workingQueue.addOperationWithBlock() { [weak self] in
            guard let strongSelf = self else { return }
            
            // enqueue transactions
            strongSelf.logger.info("Got \(transactions.count) enqueued transaction(s) to process")
            strongSelf.pendingTransactions.appendContentsOf(transactions)
            
            // process next pending transaction if not busy
            if !strongSelf.busy {
                strongSelf.busy = true
                strongSelf.processNextPendingTransaction()
            }
        }
    }

    func reloadLayout() {
//        layoutHolder.reload()
    }
    
    // MARK: Internal methods
    
    private func processNextPendingTransaction() {
        workingQueue.addOperationWithBlock() { [weak self] in
            guard let strongSelf = self else { return }
            
            // pop first transaction
            guard let transaction = strongSelf.pendingTransactions.first else {
                strongSelf.busy = false
                strongSelf.funnels.forEach({ $0.flush() })
                return
            }
            strongSelf.pendingTransactions.removeFirst()
            
            // build context
            let context = WalletTransactionsStreamContext(transaction: transaction)
            if strongSelf.funnels.count > 0 {
                strongSelf.pushContext(context, intoFunnel: strongSelf.funnels[0])
            }
            else {
                strongSelf.processNextPendingTransaction()
            }
        }
    }
    
    private func pushContext(context: WalletTransactionsStreamContext, intoFunnel funnel: WalletTransactionsStreamFunnelType) {
        workingQueue.addOperationWithBlock() { [weak self] in
            guard let _ = self else { return }

            // process context in funnel
            funnel.process(context) { [weak self] keepPushing in
                guard let strongSelf = self else { return }
                
                if keepPushing, let nextFunnel = strongSelf.funnelAfter(funnel) {
                    strongSelf.pushContext(context, intoFunnel: nextFunnel)
                }
                else {
                    strongSelf.processNextPendingTransaction()
                }
            }
        }
    }
    
    private func funnelAfter(funnel: WalletTransactionsStreamFunnelType) -> WalletTransactionsStreamFunnelType? {
        guard let index = funnels.indexOf({ $0 === funnel }) where funnels.count > index + 1 else {
            return nil
        }
        return funnels[index + 1]
    }

    private func funnelWithType(type: WalletTransactionsStreamFunnelType.Type) -> WalletTransactionsStreamFunnelType? {
        return funnels.filter({ return $0.self === type }).first
    }
    
    // MARK: Initialization
    
    init(store: SQLiteStore, delegateQueue: NSOperationQueue) {
        self.delegateQueue = delegateQueue
        self.funnels.append(WalletTransactionsStreamDiscardFunnel(store: store, callingQueue: workingQueue))
        self.funnels.append(WalletTransactionsStreamLayoutFunnel(store: store, callingQueue: workingQueue))
        self.funnels.append(WalletTransactionsStreamOperationFunnel(store: store, callingQueue: workingQueue))
        self.funnels.append(WalletTransactionsStreamSaveFunnel(store: store, callingQueue: workingQueue))
        (funnelWithType(WalletTransactionsStreamLayoutFunnel.self) as? WalletTransactionsStreamLayoutFunnel)?.delegate = self
    }
    
}

// MARK: - WalletTransactionsStreamLayoutFunnelDelegate

extension WalletTransactionsStream: WalletTransactionsStreamLayoutFunnelDelegate {
    
    func layoutFunnel(layoutfunnel: WalletTransactionsStreamLayoutFunnel, didMissAccountAtIndex index: Int, continueBlock: (Bool) -> Void) {
        
    }
    
}