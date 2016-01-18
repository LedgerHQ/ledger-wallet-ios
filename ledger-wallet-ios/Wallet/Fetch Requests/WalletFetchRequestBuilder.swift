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
    
    func accountsFetchRequestWithIncrementSize(incrementSize: Int, order: WalletFetchRequestOrder, completion: (WalletFetchRequest<WalletAllVisibleAccountsFetchRequestProvider>?) -> Void) {
        fetchRequestWithIncrementSize(incrementSize, order: order, completion: completion)
    }
    
    private func fetchRequestWithIncrementSize<T: WalletFetchRequestProviderType>(incrementSize: Int, order: WalletFetchRequestOrder, completion: (WalletFetchRequest<T>?) -> Void) {
        // fetch objects count
        let provider = T.init(storeProxy: storeProxy)
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