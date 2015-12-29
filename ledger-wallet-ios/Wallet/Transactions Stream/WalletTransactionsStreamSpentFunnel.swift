//
//  WalletTransactionsStreamSpentFunnel.swift
//  ledger-wallet-ios
//
//  Created by Nicolas Bigot on 17/12/2015.
//  Copyright © 2015 Ledger. All rights reserved.
//

import Foundation

final class WalletTransactionsStreamSpentFunnel: WalletTransactionsStreamFunnelType {
    
    func process(context: WalletTransactionsStreamContext, completion: (Bool) -> Void) {
        completion(true)
    }

    // MARK: Initialization
    
    init(store: SQLiteStore, callingQueue: NSOperationQueue) {
        
    }
    
}