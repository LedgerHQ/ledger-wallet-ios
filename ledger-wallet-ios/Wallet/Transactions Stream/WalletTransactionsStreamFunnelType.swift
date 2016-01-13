//
//  WalletTransactionsStreamFunnelType.swift
//  ledger-wallet-ios
//
//  Created by Nicolas Bigot on 16/12/2015.
//  Copyright © 2015 Ledger. All rights reserved.
//

import Foundation

protocol WalletTransactionsStreamFunnelType: class {
    
    func process(context: WalletTransactionsStreamContext, workingQueue: NSOperationQueue, completion: (Bool) -> Void)
    
}