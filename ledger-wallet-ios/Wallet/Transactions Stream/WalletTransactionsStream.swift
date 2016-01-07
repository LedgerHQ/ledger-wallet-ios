//
//  WalletTransactionsStream.swift
//  ledger-wallet-ios
//
//  Created by Nicolas Bigot on 06/12/2015.
//  Copyright © 2015 Ledger. All rights reserved.
//

import Foundation

protocol WalletTransactionsStreamDelegate: class {
    
    func transactionsStreamDidUpdateAccountLayout(transactionsStream: WalletTransactionsStream)
    func transactionsStreamDidUpdateAccountOperations(transactionsStream: WalletTransactionsStream)
    func transactionsStream(transactionsStream: WalletTransactionsStream, didMissAccountAtIndex index: Int, continueBlock: (Bool) -> Void)
    
}

final class WalletTransactionsStream {
    
    weak var delegate: WalletTransactionsStreamDelegate?
    private var busy = false
    private var pendingTransactions: [WalletTransactionContainer] = []
    private var funnels: [WalletTransactionsStreamFunnelType] = []
    private let delegateQueue: NSOperationQueue
    private let workingQueue = NSOperationQueue(name: "WalletTransactionsStream", maxConcurrentOperationCount: 1)
    private let logger = Logger.sharedInstance(name: "WalletTransactionsStream")
    
    // MARK: Transactions management
    
    func enqueueTransactions(transactions: [WalletTransactionContainer]) {
        guard transactions.count > 0 else { return }
        
        workingQueue.addOperationWithBlock() { [weak self] in
            guard let strongSelf = self else { return }
            
            // enqueue transactions
            strongSelf.logger.info("Got \(transactions.count) enqueued transaction(s) to process")
            
            //FIXME: enqueue double spend
            var fakeTransactions = transactions
            let lastTx = fakeTransactions.popLast()!
            
            let fakeTx = WalletTransaction(hash: lastTx.transaction.hash, receiveAt: lastTx.transaction.receiveAt, lockTime: lastTx.transaction.lockTime, fees: lastTx.transaction.fees, blockHash: nil, blockTime: nil, blockHeight: nil)
            let fakeTxContainer = WalletTransactionContainer(transaction: fakeTx, inputs: lastTx.inputs, outputs: lastTx.outputs)
            
            let doubleSpendTx = WalletTransaction(hash: lastTx.transaction.hash + "-hello", receiveAt: fakeTx.receiveAt, lockTime: fakeTx.lockTime, fees: fakeTx.fees, blockHash: nil, blockTime: nil, blockHeight: nil)
            let doubleSpendTxContainer = WalletTransactionContainer(transaction: doubleSpendTx, inputs: lastTx.inputs, outputs: lastTx.outputs)

            strongSelf.pendingTransactions.appendContentsOf(fakeTransactions)
            strongSelf.pendingTransactions.append(fakeTxContainer)
            strongSelf.pendingTransactions.append(doubleSpendTxContainer)

            
            // process next pending transaction if not busy
            if !strongSelf.busy {
                strongSelf.busy = true
                strongSelf.processNextPendingTransaction()
            }
        }
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
            if strongSelf.funnels.count > 0 {
                let context = WalletTransactionsStreamContext(remoteTransaction: transaction)
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

    private func funnelWithType<T: WalletTransactionsStreamFunnelType>(type: T.Type) -> T? {
        return funnels.filter({ return $0 is T }).first as? T
    }
    
    // MARK: Initialization
    
    init(storeProxy: WalletStoreProxy, addressCache: WalletAddressCache, layoutHolder: WalletLayoutHolder, delegateQueue: NSOperationQueue) {
        self.delegateQueue = delegateQueue
        
        // create funnels
        let funnelTypes: [WalletTransactionsStreamFunnelType.Type] = [
            WalletTransactionsStreamDiscardFunnel.self,
            WalletTransactionsStreamLayoutFunnel.self,
            WalletTransactionsStreamOperationsFunnel.self,
            WalletTransactionsStreamSpentFunnel.self,
            WalletTransactionsStreamSaveFunnel.self,
        ]
        funnelTypes.forEach() {
            self.funnels.append($0.init(storeProxy: storeProxy, addressCache: addressCache, layoutHolder: layoutHolder, callingQueue: workingQueue))
        }
        
        // plug delegates
        funnelWithType(WalletTransactionsStreamLayoutFunnel)?.delegate = self
        funnelWithType(WalletTransactionsStreamSaveFunnel)?.delegate = self
    }
    
}

// MARK: - WalletTransactionsStreamLayoutFunnelDelegate

extension WalletTransactionsStream: WalletTransactionsStreamLayoutFunnelDelegate {
    
    func layoutFunnelDidUpdateAccountLayouts(layoutfunnel: WalletTransactionsStreamLayoutFunnel) {
        
    }
    
    func layoutFunnel(layoutfunnel: WalletTransactionsStreamLayoutFunnel, didMissAccountAtIndex index: Int, continueBlock: (Bool) -> Void) {
        // ask delegate
        delegateQueue.addOperationWithBlock() { [weak self] in
            guard let strongSelf = self else { return }
            
            strongSelf.delegate?.transactionsStream(strongSelf, didMissAccountAtIndex: index) { [weak self] shouldContinue in
                guard let strongSelf = self else { return }
                
                strongSelf.workingQueue.addOperationWithBlock() { continueBlock(shouldContinue) }
            }
        }
    }
    
}

// MARK: - WalletTransactionsStreamSaveFunnelDelegate

extension WalletTransactionsStream: WalletTransactionsStreamSaveFunnelDelegate {
    
    func saveFunnelDidUpdateOperations(saveFunnel: WalletTransactionsStreamSaveFunnel) {
        
    }
    
    func saveFunnelDidUpdateTransactions(saveFunnel: WalletTransactionsStreamSaveFunnel) {
        
    }
    
    func saveFunnerDidUpdateAccountBalances(saveFunnel: WalletTransactionsStreamSaveFunnel) {
        
    }
    
    func saveFunnelDidUpdateDoubleSpendConflicts(saveFunnel: WalletTransactionsStreamSaveFunnel) {
        
    }
    
}