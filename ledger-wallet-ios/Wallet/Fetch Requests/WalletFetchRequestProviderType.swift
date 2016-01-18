//
//  WalletFetchRequestProviderType.swift
//  ledger-wallet-ios
//
//  Created by Nicolas Bigot on 15/01/2016.
//  Copyright © 2016 Ledger. All rights reserved.
//

import Foundation

protocol WalletFetchRequestProviderType {
    
    typealias ModelType: SQLiteFetchableModel
    
    func fetchObjectsFromStoreFrom(from: Int, size: Int, order: WalletFetchRequestOrder, completion: ([ModelType]?) -> Void)
    func countNumberOfObjectsFromStoreWithCompletion(completion: (Int?) -> Void)
    
    init(storeProxy: WalletStoreProxy)
    
}