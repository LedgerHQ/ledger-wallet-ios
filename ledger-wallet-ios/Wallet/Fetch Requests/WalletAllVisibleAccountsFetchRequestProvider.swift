//
//  WalletAllVisibleAccountsFetchRequestProvider.swift
//  ledger-wallet-ios
//
//  Created by Nicolas Bigot on 15/01/2016.
//  Copyright © 2016 Ledger. All rights reserved.
//

import Foundation

final class WalletAllVisibleAccountsFetchRequestProvider: WalletFetchRequestProviderType {
    
    private weak var storeProxy: WalletStoreProxy?
    
    func fetchObjectsFromStoreFrom(from: Int, size: Int, order: WalletFetchRequestOrder, completion: ([WalletAccount]?) -> Void) {
        storeProxy?.fetchAllVisibleAccountsFrom(from, size: size, order: order, completionQueue: NSOperationQueue.mainQueue(), completion: completion)
    }
    
    func countNumberOfObjectsFromStoreWithCompletion(completion: (Int?) -> Void) {
        storeProxy?.countAllVisibleAccounts(NSOperationQueue.mainQueue(), completion: completion)
    }
    
    // MARK: Initialization
    
    init(storeProxy: WalletStoreProxy) {
        self.storeProxy = storeProxy
    }
    
}