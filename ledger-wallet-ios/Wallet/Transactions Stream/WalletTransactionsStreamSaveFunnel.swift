//
//  WalletTransactionsStreamSaveFunnel.swift
//  ledger-wallet-ios
//
//  Created by Nicolas Bigot on 17/12/2015.
//  Copyright © 2015 Ledger. All rights reserved.
//

import Foundation

// MARK: - WalletTransactionsStreamSaveFunnelOperationType

private enum WalletTransactionsStreamSaveFunnelOperationType: Hashable, Equatable {
    
    case UpdateTransaction(success: Bool)
    case UpdateOperations(success: Bool)
    case AddDoubleSpendConflicts(success: Bool)
    case RemoveTransactions(success: Bool)
    
    var hashValue: Int {
        switch self {
        case .UpdateTransaction: return 0
        case .UpdateOperations: return 1
        case .AddDoubleSpendConflicts: return 2
        case .RemoveTransactions: return 3
        }
    }
    
    var isSuccessful: Bool {
        switch self {
        case .UpdateTransaction(let success): return success
        case .UpdateOperations(let success): return success
        case .AddDoubleSpendConflicts(let success): return success
        case .RemoveTransactions(let success): return success
        }
    }
    
}

private func ==(lhs: WalletTransactionsStreamSaveFunnelOperationType, rhs: WalletTransactionsStreamSaveFunnelOperationType) -> Bool {
    return lhs.hashValue == rhs.hashValue
}

// MARK: - WalletTransactionsStreamSaveFunnel

protocol WalletTransactionsStreamSaveFunnelDelegate: class {
    
    func saveFunnelDidUpdateTransactions(saveFunnel: WalletTransactionsStreamSaveFunnel)
    func saveFunnelDidUpdateOperations(saveFunnel: WalletTransactionsStreamSaveFunnel)
    func saveFunnelDidUpdateDoubleSpendConflicts(saveFunnel: WalletTransactionsStreamSaveFunnel)
    
}

final class WalletTransactionsStreamSaveFunnel: WalletTransactionsStreamFunnelType {
    
    weak var delegate: WalletTransactionsStreamSaveFunnelDelegate?
    private let storeProxy: WalletStoreProxy
    private var finishedOperations: Set<WalletTransactionsStreamSaveFunnelOperationType> = []
    private var expectedOperations: Set<WalletTransactionsStreamSaveFunnelOperationType> = []
    
    func process(context: WalletTransactionsStreamContext, workingQueue: NSOperationQueue, completion: (Bool) -> Void) {
        // write transactions
        expectedOperations.insert(.UpdateTransaction(success: true))
        storeProxy.storeTransactions([context.remoteTransaction], queue: workingQueue) { [weak self] success in
            self?.writeCompletionHandler(.UpdateTransaction(success: success), completion: completion)
        }
        
        // write operations
        let operations = context.sendOperations + context.receiveOperations
        if operations.count > 0 {
            expectedOperations.insert(.UpdateOperations(success: true))
            storeProxy.storeOperations(operations, queue: workingQueue) { [weak self] success in
                self?.writeCompletionHandler(.UpdateOperations(success: success), completion: completion)
            }
        }
        
        // write double spend conflicts
        if context.conflictsToAdd.count > 0 {
            expectedOperations.insert(.AddDoubleSpendConflicts(success: true))
            storeProxy.addDoubleSpendConflicts(context.conflictsToAdd, queue: workingQueue) { [weak self] success in
                self?.writeCompletionHandler(.AddDoubleSpendConflicts(success: success), completion: completion)
            }
        }
        
        // remove transactions
        if context.transactionsToRemove.count > 0 {
            expectedOperations.insert(.RemoveTransactions(success: true))
            storeProxy.removeTransactions(context.transactionsToRemove, queue: workingQueue) { [weak self] success in
                self?.writeCompletionHandler(.RemoveTransactions(success: success), completion: completion)
            }
        }
    }

    // MARK: Write management
    
    private func writeCompletionHandler(finishedOperation: WalletTransactionsStreamSaveFunnelOperationType, completion: (Bool) -> Void) {
        finishedOperations.insert(finishedOperation)
        
        // if all operations have completed
        if expectedOperations.isSubsetOf(finishedOperations) {
            let finishedSubset = finishedOperations.union(expectedOperations)

            // notify delegate
            notifyDelegateAboutWhatHappened(finishedSubset)

            // continue
            finishedOperations = []
            expectedOperations = []
            let success = finishedSubset.reduce(true, combine: { $0 && $1.isSuccessful })
            completion(success)
        }
    }
    
    private func notifyDelegateAboutWhatHappened(finishedOperations: Set<WalletTransactionsStreamSaveFunnelOperationType>) {
        // determine what happened
        if finishedOperations.contains(.UpdateTransaction(success: true)) ||
            finishedOperations.contains(.RemoveTransactions(success: true)) {
            delegate?.saveFunnelDidUpdateTransactions(self)
        }
        if finishedOperations.contains(.UpdateOperations(success: true)) ||
            finishedOperations.contains(.RemoveTransactions(success: true)) {
            delegate?.saveFunnelDidUpdateOperations(self)
        }
        if finishedOperations.contains(.AddDoubleSpendConflicts(success: true)) ||
            finishedOperations.contains(.RemoveTransactions(success: true)) {
            delegate?.saveFunnelDidUpdateDoubleSpendConflicts(self)
        }
    }
    
    // MARK: Initialization
    
    init(storeProxy: WalletStoreProxy) {
        self.storeProxy = storeProxy
    }
    
}