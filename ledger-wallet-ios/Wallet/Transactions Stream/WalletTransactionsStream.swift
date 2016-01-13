//
//  WalletTransactionsStream.swift
//  ledger-wallet-ios
//
//  Created by Nicolas Bigot on 06/12/2015.
//  Copyright © 2015 Ledger. All rights reserved.
//

import Foundation

protocol WalletTransactionsStreamDelegate: class {
    
    func transactionsStreamDidUpdateAccountLayouts(transactionsStream: WalletTransactionsStream)
    func transactionsStreamDidUpdateOperations(transactionsStream: WalletTransactionsStream)
    func transactionsStreamDidUpdateDoubleSpendConflicts(transactionsStream: WalletTransactionsStream)
    func transactionsStream(transactionsStream: WalletTransactionsStream, didMissAccountAtIndex index: Int, continueBlock: (Bool) -> Void)
    
}

final class WalletTransactionsStream {
    
    weak var delegate: WalletTransactionsStreamDelegate?
    private let funnels: [WalletTransactionsStreamFunnelType]
    private let delegateQueue: NSOperationQueue
    private let workingQueue = NSOperationQueue(name: "WalletTransactionsStream", maxConcurrentOperationCount: 1)
    private let logger = Logger.sharedInstance(name: "WalletTransactionsStream")
    
    // MARK: Transactions management
    
    func processTransaction(transaction: WalletTransactionContainer, completionQueue: NSOperationQueue, completion: () -> Void) {
        if funnels.count > 0 {
            let firstFunnel = funnels[0]
            let context = WalletTransactionsStreamContext(remoteTransaction: transaction)
            pushContext(context, intoFunnel: firstFunnel, completionQueue: completionQueue, completion: completion)
        }
        else {
            completionQueue.addOperationWithBlock() { completion() }
        }
    }
    
    // MARK: Funnels management
    
    private func pushContext(context: WalletTransactionsStreamContext, intoFunnel funnel: WalletTransactionsStreamFunnelType, completionQueue: NSOperationQueue, completion: () -> Void) {
        workingQueue.addOperationWithBlock() { [weak self] in
            guard let strongSelf = self else { return }

            // process context in funnel
            funnel.process(context, workingQueue: strongSelf.workingQueue) { [weak self] keepPushing in
                guard let strongSelf = self else { return }
                
                if keepPushing, let nextFunnel = strongSelf.funnelAfter(funnel) {
                    strongSelf.pushContext(context, intoFunnel: nextFunnel, completionQueue: completionQueue, completion: completion)
                }
                else {
                    completionQueue.addOperationWithBlock() { completion() }
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
        self.funnels = [
            WalletTransactionsStreamDiscardFunnel(addressCache: addressCache),
            WalletTransactionsStreamLayoutFunnel(storeProxy: storeProxy, addressCache: addressCache, layoutHolder: layoutHolder),
            WalletTransactionsStreamOperationsFunnel(),
            WalletTransactionsStreamSpentFunnel(storeProxy: storeProxy),
            WalletTransactionsStreamSaveFunnel(storeProxy: storeProxy)
        ]
        
        // plug delegates
        funnelWithType(WalletTransactionsStreamLayoutFunnel)?.delegate = self
        funnelWithType(WalletTransactionsStreamSaveFunnel)?.delegate = self
    }
    
}

// MARK: - Delegate management

private extension WalletTransactionsStream {
    
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
        notifyUpdateAccountLayouts()
    }
    
    func layoutFunnel(layoutfunnel: WalletTransactionsStreamLayoutFunnel, didMissAccountAtIndex index: Int, continueBlock: (Bool) -> Void) {
        notifyMissingAccountAtIndex(index, continueBlock: continueBlock)
    }
    
}

// MARK: - WalletTransactionsStreamSaveFunnelDelegate

extension WalletTransactionsStream: WalletTransactionsStreamSaveFunnelDelegate {

    func saveFunnelDidUpdateTransactions(saveFunnel: WalletTransactionsStreamSaveFunnel) {
    
    }

    func saveFunnelDidUpdateOperations(saveFunnel: WalletTransactionsStreamSaveFunnel) {
        notifyUpdateOperations()
    }
    
    func saveFunnelDidUpdateDoubleSpendConflicts(saveFunnel: WalletTransactionsStreamSaveFunnel) {
        notifyUpdateDoubleSpendConflicts()
    }
    
}