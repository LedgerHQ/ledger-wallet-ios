//
//  WalletVisibleAccountsFetchRequestProvider.swift
//  ledger-wallet-ios
//
//  Created by Nicolas Bigot on 15/01/2016.
//  Copyright © 2016 Ledger. All rights reserved.
//

import Foundation

final class WalletVisibleAccountsFetchRequestProvider: WalletFetchRequestProviderType {
    
    private weak var storeProxy: WalletStoreProxy?
    private let delegateQueue: NSOperationQueue
    
    func fetchObjectsFromStoreFrom(from: Int, size: Int, order: WalletFetchRequestOrder, completion: ([WalletAccount]?) -> Void) {
        storeProxy?.fetchVisibleAccountsFrom(from, size: size, order: order, completionQueue: delegateQueue, completion: completion)
    }
    
    func countNumberOfObjectsFromStoreWithCompletion(completion: (Int?) -> Void) {
        storeProxy?.countVisibleAccounts(delegateQueue, completion: completion)
    }
    
    // MARK: Initialization
    
    init(storeProxy: WalletStoreProxy, delegateQueue: NSOperationQueue) {
        self.storeProxy = storeProxy
        self.delegateQueue = delegateQueue
    }
    
}