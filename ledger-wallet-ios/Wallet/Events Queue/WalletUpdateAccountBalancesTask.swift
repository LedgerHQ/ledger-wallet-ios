//
//  WalletUpdateAccountBalancesTask.swift
//  ledger-wallet-ios
//
//  Created by Nicolas Bigot on 14/01/2016.
//  Copyright © 2016 Ledger. All rights reserved.
//

import Foundation

struct WalletUpdateAccountBalancesTask: WalletTaskType {
    
    let identifier = "WalletUpdateAccountBalancesTask"
    private weak var balanceUpdater: WalletBalanceUpdater?
    
    func process(completionQueue: NSOperationQueue, completion: () -> Void) {
        guard let balanceUpdater = balanceUpdater else {
            completion()
            return
        }
        balanceUpdater.updateAccountBalances()
        completion()
    }
    
    // MARK: Initialization
    
    init(balanceUpdater: WalletBalanceUpdater) {
        self.balanceUpdater = balanceUpdater
    }
    
}