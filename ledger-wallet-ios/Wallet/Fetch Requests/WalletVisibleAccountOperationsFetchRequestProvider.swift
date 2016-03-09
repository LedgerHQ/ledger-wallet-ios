//
//  WalletVisibleAccountOperationsFetchRequestProvider.swift
//  ledger-wallet-ios
//
//  Created by Nicolas Bigot on 19/01/2016.
//  Copyright © 2016 Ledger. All rights reserved.
//

import Foundation

final class WalletVisibleAccountOperationsFetchRequestProvider: WalletFetchRequestProviderType {
    
    let accountIndex: Int?
    private weak var storeProxy: WalletStoreProxy?
    private let delegateQueue: NSOperationQueue
    
    func fetchObjectsFromStoreFrom(from: Int, size: Int, order: WalletFetchRequestOrder, completion: ([WalletAccountOperationContainer]?) -> Void) {
        storeProxy?.fetchVisibleAccountOperationsForAccountAtIndex(accountIndex, from: from, size: size, order: order, completionQueue: delegateQueue, completion: completion)
    }
    
    func countNumberOfObjectsFromStoreWithCompletion(completion: (Int?) -> Void) {
        storeProxy?.countVisibleAccountOperationsForAccountAtIndex(accountIndex, completionQueue: delegateQueue, completion: completion)
    }
    
    // MARK: Initialization
    
    init(accountIndex: Int?, storeProxy: WalletStoreProxy, delegateQueue: NSOperationQueue) {
        self.accountIndex = accountIndex
        self.storeProxy = storeProxy
        self.delegateQueue = delegateQueue
    }
    
}