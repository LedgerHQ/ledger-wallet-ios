//
//  WalletTransactionsStream.swift
//  ledger-wallet-ios
//
//  Created by Nicolas Bigot on 06/12/2015.
//  Copyright © 2015 Ledger. All rights reserved.
//

import Foundation

protocol WalletTransactionsStreamDelegate: class {
    
    func transactionsStreamDidStartDequeuingTransactions(transactionsStream: WalletTransactionsStream)
    func transactionsStreamDidStopDequeuingTransactions(transactionsStream: WalletTransactionsStream, updatedStore: Bool)
    func transactionsStreamDidUpdateAccountLayouts(transactionsStream: WalletTransactionsStream)
    func transactionsStreamDidUpdateOperations(transactionsStream: WalletTransactionsStream)
    func transactionsStreamDidUpdateDoubleSpendConflicts(transactionsStream: WalletTransactionsStream)
    func transactionsStream(transactionsStream: WalletTransactionsStream, didMissAccountAtIndex index: Int, continueBlock: (Bool) -> Void)
    
}

final class WalletTransactionsStream {
    
    weak var delegate: WalletTransactionsStreamDelegate?
    private var busy = false
    private var dequeuePassUpdatedStore = false
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
            if transactions.count > 1 {
                strongSelf.logger.info("Got \(transactions.count) enqueued transaction(s) to process")
            }
            strongSelf.pendingTransactions.appendContentsOf(transactions)
            
            // process next pending transaction if not busy
            if !strongSelf.busy {
                strongSelf.initiateDequeueProcess()
            }
        }
    }
    
    // MARK: Dequeue lifecycle
    
    private func initiateDequeueProcess() {
        busy = true
        dequeuePassUpdatedStore = false
        notifyStartOfDequeuingTransactions()
        processNextPendingTransaction()
    }
    
    private func terminateDequeueProcess() {
        busy = false
        funnels.forEach({ $0.flush() })
        notifyStopOfDequeuingTransactions(updatedStore: dequeuePassUpdatedStore)
        dequeuePassUpdatedStore = false
    }

    // MARK: Internal methods
    
    private func processNextPendingTransaction() {
        workingQueue.addOperationWithBlock() { [weak self] in
            guard let strongSelf = self else { return }
            
            // pop first transaction
            guard let transaction = strongSelf.pendingTransactions.first else {
                strongSelf.terminateDequeueProcess()
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

// MARK: - Delegate management

private extension WalletTransactionsStream {
    
    private func notifyStartOfDequeuingTransactions() {
        delegateQueue.addOperationWithBlock() { [weak self] in
            guard let strongSelf = self else { return }
            strongSelf.delegate?.transactionsStreamDidStartDequeuingTransactions(strongSelf)
        }
    }
    
    private func notifyStopOfDequeuingTransactions(updatedStore updatedStore: Bool) {
        delegateQueue.addOperationWithBlock() { [weak self] in
            guard let strongSelf = self else { return }
            strongSelf.delegate?.transactionsStreamDidStopDequeuingTransactions(strongSelf, updatedStore: updatedStore)
        }
    }
    
    private func notifyUpdateAccountLayouts() {
        delegateQueue.addOperationWithBlock() { [weak self] in
            guard let strongSelf = self else { return }
            strongSelf.delegate?.transactionsStreamDidUpdateAccountLayouts(strongSelf)
        }
    }
    
    private func notifyUpdateOperations() {
        delegateQueue.addOperationWithBlock() { [weak self] in
            guard let strongSelf = self else { return }
            strongSelf.delegate?.transactionsStreamDidUpdateOperations(strongSelf)
        }
    }
    
    private func notifyUpdateDoubleSpendConflicts() {
        delegateQueue.addOperationWithBlock() { [weak self] in
            guard let strongSelf = self else { return }
            strongSelf.delegate?.transactionsStreamDidUpdateDoubleSpendConflicts(strongSelf)
        }
    }
    
    private func notifyMissingAccountAtIndex(index: Int, continueBlock: (Bool) -> Void) {
        delegateQueue.addOperationWithBlock() { [weak self] in
            guard let strongSelf = self else { return }
            strongSelf.delegate?.transactionsStream(strongSelf, didMissAccountAtIndex: index) { [weak self] shouldContinue in
                guard let strongSelf = self else { return }
                strongSelf.workingQueue.addOperationWithBlock() { continueBlock(shouldContinue) }
            }
        }
    }
    
}

// MARK: - WalletTransactionsStreamLayoutFunnelDelegate

extension WalletTransactionsStream: WalletTransactionsStreamLayoutFunnelDelegate {
    
    func layoutFunnelDidUpdateAccountLayouts(layoutfunnel: WalletTransactionsStreamLayoutFunnel) {
        dequeuePassUpdatedStore = true
        notifyUpdateAccountLayouts()
    }
    
    func layoutFunnel(layoutfunnel: WalletTransactionsStreamLayoutFunnel, didMissAccountAtIndex index: Int, continueBlock: (Bool) -> Void) {
        notifyMissingAccountAtIndex(index, continueBlock: continueBlock)
    }
    
}

// MARK: - WalletTransactionsStreamSaveFunnelDelegate

extension WalletTransactionsStream: WalletTransactionsStreamSaveFunnelDelegate {

    func saveFunnelDidUpdateTransactions(saveFunnel: WalletTransactionsStreamSaveFunnel) {
        dequeuePassUpdatedStore = true
    }

    func saveFunnelDidUpdateOperations(saveFunnel: WalletTransactionsStreamSaveFunnel) {
        dequeuePassUpdatedStore = true
        notifyUpdateOperations()
    }
    
    func saveFunnelDidUpdateDoubleSpendConflicts(saveFunnel: WalletTransactionsStreamSaveFunnel) {
        dequeuePassUpdatedStore = true
        notifyUpdateDoubleSpendConflicts()
    }
    
}