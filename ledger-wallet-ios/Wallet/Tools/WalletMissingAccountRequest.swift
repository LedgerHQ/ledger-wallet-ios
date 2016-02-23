//
//  WalletMissingAccountRequest.swift
//  ledger-wallet-ios
//
//  Created by Nicolas Bigot on 22/02/2016.
//  Copyright © 2016 Ledger. All rights reserved.
//

import Foundation

final class WalletMissingAccountRequest {
    
    let accountIndex: Int
    private let continueBlock: (WalletAccount?) -> Void
    
    func completeWithAccount(account: WalletAccount?) {
        continueBlock(account)
    }
    
    // MARK: Initialization
    
    init(accountIndex: Int, continueBlock: (WalletAccount?) -> Void) {
        self.accountIndex = accountIndex
        self.continueBlock = continueBlock
    }
    
}