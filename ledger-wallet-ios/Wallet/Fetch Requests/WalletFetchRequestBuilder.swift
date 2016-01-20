//
//  WalletFetchRequestBuilder.swift
//  ledger-wallet-ios
//
//  Created by Nicolas Bigot on 15/01/2016.
//  Copyright © 2016 Ledger. All rights reserved.
//

import Foundation

final class WalletFetchRequestBuilder {
    
    private let storeProxy: WalletStoreProxy
    
    // MARK: Fetch request management
    
    func accountsFetchRequestWithIncrementSize(incrementSize: Int, order: WalletFetchRequestOrder, completion: (WalletFetchRequest<WalletVisibleAccountsFetchRequestProvider>?) -> Void) {
        let provider = WalletVisibleAccountsFetchRequestProvider(storeProxy: storeProxy)
        fetchRequestWithProvider(provider, incrementSize: incrementSize, order: order, completion: completion)
    }
    
    func accountOperationsFetchRequestForAccountAtIndex(index: Int?, incrementSize: Int, order: WalletFetchRequestOrder, completion: (WalletFetchRequest<WalletVisibleAccountOperationsFetchRequestProvider>?) -> Void) {
        let provider = WalletVisibleAccountOperationsFetchRequestProvider(accountIndex: index, storeProxy: storeProxy)
        fetchRequestWithProvider(provider, incrementSize: incrementSize, order: order, completion: completion)
    }
    
    private func fetchRequestWithProvider<T: WalletFetchRequestProviderType>(provider: T, incrementSize: Int, order: WalletFetchRequestOrder, completion: (WalletFetchRequest<T>?) -> Void) {
        // fetch objects count
        provider.countNumberOfObjectsFromStoreWithCompletion() { count in
            // if we succeeded to count results
            guard let count = count else {
                completion(nil)
                return
            }
            
            let fetchRequest = WalletFetchRequest(provider: provider, incrementSize: incrementSize, order: order, numberOfObjects: count)
            completion(fetchRequest)
        }
    }
    
    // MARK: Initialization
    
    init(storeProxy: WalletStoreProxy) {
        self.storeProxy = storeProxy
    }
    
}