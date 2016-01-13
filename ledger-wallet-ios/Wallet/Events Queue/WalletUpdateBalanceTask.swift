//
//  WalletUpdateBalanceTask.swift
//  ledger-wallet-ios
//
//  Created by Nicolas Bigot on 12/01/2016.
//  Copyright © 2016 Ledger. All rights reserved.
//

import Foundation

struct WalletUpdateBalanceTask: WalletTaskType {
    
    private let balanceUpdater: WalletBalanceUpdater
    
    func process(completionQueue: NSOperationQueue, completion: () -> Void) {
        balanceUpdater.updateAccountBalances()
        completion()
    }
    
    // MARK: Initialization
    
    init(balanceUpdater: WalletBalanceUpdater) {
        self.balanceUpdater = balanceUpdater
    }
    
}