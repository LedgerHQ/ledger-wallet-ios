//
//  WalletTransactionsManagerType.swift
//  ledger-wallet-ios
//
//  Created by Nicolas Bigot on 02/12/2015.
//  Copyright © 2015 Ledger. All rights reserved.
//

import Foundation

let WalletTransactionsManagerDidStartRefreshingTransactionsNotification = "WalletTransactionsManagerDidStartRefreshingTransactionsNotification"
let WalletTransactionsManagerDidStopRefreshingTransactionsNotification = "WalletTransactionsManagerDidStopRefreshingTransactionsNotification"
let WalletTransactionsManagerDidUpdateAccountsNotification = "WalletTransactionsManagerDidUpdateAccountsNotification"
let WalletTransactionsManagerDidUpdateOperationsNotification = "WalletTransactionsManagerDidUpdateOperationsNotification"
let WalletTransactionsManagerDidMissAccountNotification = "WalletTransactionsManagerDidMissAccountNotification"
let WalletTransactionsManagerMissingAccountRequestKey = "WalletTransactionsManagerMissingAccountRequestKey"

protocol WalletTransactionsManagerType: class {
    
    var isRefreshingTransactions: Bool { get }
    var fetchRequestBuilder: WalletFetchRequestBuilder { get }
    
    func refreshTransactions()
    func fetchLastReceiveAddress(amount: Int, completion: (String?) -> ())
    func collectUnspentOutputs(amount amount: Int64, completion: ([WalletTransactionOutput]?) -> ())
        
    init?(identifier: String, servicesProvider: ServicesProviderType)
    
}