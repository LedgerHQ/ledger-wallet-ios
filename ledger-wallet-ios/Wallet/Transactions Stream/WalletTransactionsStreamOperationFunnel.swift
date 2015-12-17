//
//  WalletTransactionsStreamOperationFunnel.swift
//  ledger-wallet-ios
//
//  Created by Nicolas Bigot on 17/12/2015.
//  Copyright © 2015 Ledger. All rights reserved.
//

import Foundation

final class WalletTransactionsStreamOperationFunnel: WalletTransactionsStreamFunnelType {
    
    func process(context: WalletTransactionsStreamContext, completion: (Bool) -> Void) {
        
    }
    
    func flush() {
        
    }
    
    // MARK: Initialization
    
    init(store: SQLiteStore, callingQueue: NSOperationQueue) {
        
    }
    
}