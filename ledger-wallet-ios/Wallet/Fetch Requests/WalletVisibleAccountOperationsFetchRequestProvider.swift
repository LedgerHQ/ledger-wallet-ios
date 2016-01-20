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
    
    func fetchObjectsFromStoreFrom(from: Int, size: Int, order: WalletFetchRequestOrder, completion: ([WalletAccountOperationContainer]?) -> Void) {
        storeProxy?.fetchVisibleAccountOperationsForAccountAtIndex(accountIndex, from: from, size: size, order: order, completionQueue: NSOperationQueue.mainQueue(), completion: completion)
    }
    
    func countNumberOfObjectsFromStoreWithCompletion(completion: (Int?) -> Void) {
        storeProxy?.countVisibleAccountOperationsForAccountAtIndex(accountIndex, completionQueue: NSOperationQueue.mainQueue(), completion: completion)
    }
    
    // MARK: Initialization
    
    init(accountIndex: Int?, storeProxy: WalletStoreProxy) {
        self.accountIndex = accountIndex
        self.storeProxy = storeProxy
    }
    
}