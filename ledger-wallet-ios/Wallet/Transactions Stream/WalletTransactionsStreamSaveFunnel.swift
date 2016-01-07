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
    func saveFunnerDidUpdateAccountBalances(saveFunnel: WalletTransactionsStreamSaveFunnel)
    
}

final class WalletTransactionsStreamSaveFunnel: WalletTransactionsStreamFunnelType {
    
    weak var delegate: WalletTransactionsStreamSaveFunnelDelegate?
    private let storeProxy: WalletStoreProxy
    private let callingQueue: NSOperationQueue
    private var finishedOperations: Set<WalletTransactionsStreamSaveFunnelOperationType> = []
    private var expectedOperations: Set<WalletTransactionsStreamSaveFunnelOperationType> = []
    private var wroteTransactionsSinceLastFlush = false
    private var wroteOperationsSinceLastFlush = false
    private var wroteDoubleSpendConflictsSinceLastFlush = false
    
    func process(context: WalletTransactionsStreamContext, completion: (Bool) -> Void) {
        // write transactions
        expectedOperations.insert(.UpdateTransaction(success: true))
        storeProxy.storeTransactions([context.remoteTransaction], queue: callingQueue) { [weak self] success in
            self?.writeCompletionHandler(.UpdateTransaction(success: success), completion: completion)
        }
        
        // write operations
        let operations = context.sendOperations + context.receiveOperations
        if operations.count > 0 {
            expectedOperations.insert(.UpdateOperations(success: true))
            storeProxy.storeOperations(operations, queue: callingQueue) { [weak self] success in
                self?.writeCompletionHandler(.UpdateOperations(success: success), completion: completion)
            }
        }
        
        // write double spend conflicts
        if context.doubleSpendConflicts.count > 0 {
            expectedOperations.insert(.AddDoubleSpendConflicts(success: true))
            storeProxy.addDoubleSpendConflicts(context.doubleSpendConflicts, queue: callingQueue) { [weak self] success in
                self?.writeCompletionHandler(.AddDoubleSpendConflicts(success: success), completion: completion)
            }
        }
        
        // remove transactions
        if context.transactionsToRemove.count > 0 {
            expectedOperations.insert(.RemoveTransactions(success: true))
            storeProxy.removeTransactions(context.transactionsToRemove, queue: callingQueue) { [weak self] success in
                self?.writeCompletionHandler(.RemoveTransactions(success: success), completion: completion)
            }
        }
    }

    func flush() {
        if wroteTransactionsSinceLastFlush {
            delegate?.saveFunnelDidUpdateTransactions(self)
        }
        if wroteOperationsSinceLastFlush {
            delegate?.saveFunnelDidUpdateOperations(self)
        }
        if wroteDoubleSpendConflictsSinceLastFlush {
            delegate?.saveFunnelDidUpdateDoubleSpendConflicts(self)
        }
        if wroteTransactionsSinceLastFlush || wroteDoubleSpendConflictsSinceLastFlush {
            storeProxy.updateAllAccountBalances(callingQueue, completion: { _ in })
            delegate?.saveFunnerDidUpdateAccountBalances(self)
        }
        wroteTransactionsSinceLastFlush = false
        wroteOperationsSinceLastFlush = false
        wroteDoubleSpendConflictsSinceLastFlush = false
    }
    
    // MARK: Write management
    
    private func writeCompletionHandler(finishedOperation: WalletTransactionsStreamSaveFunnelOperationType, completion: (Bool) -> Void) {
        finishedOperations.insert(finishedOperation)
        
        // mark finished operation to perform proper flush
        switch finishedOperation {
        case .UpdateTransaction(let success) where success: wroteTransactionsSinceLastFlush = true
        case .UpdateOperations(let success) where success: wroteOperationsSinceLastFlush = true
        case .AddDoubleSpendConflicts(let success) where success: wroteDoubleSpendConflictsSinceLastFlush = true
        case .RemoveTransactions(let success) where success: wroteTransactionsSinceLastFlush = true; wroteDoubleSpendConflictsSinceLastFlush = true
        default: break
        }
        
        // if all operations have completed
        if expectedOperations.isSubsetOf(finishedOperations) {
            let finishedSubset = finishedOperations.union(expectedOperations)
            
            finishedOperations = []
            expectedOperations = []
            let success = finishedSubset.reduce(true, combine: { $0 && $1.isSuccessful })
            completion(success)
        }
    }
    
    // MARK: Initialization
    
    init(storeProxy: WalletStoreProxy, addressCache: WalletAddressCache, layoutHolder: WalletLayoutHolder, callingQueue: NSOperationQueue) {
        self.storeProxy = storeProxy
        self.callingQueue = callingQueue
    }
    
}