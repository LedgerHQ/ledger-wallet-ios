//
//  WalletManagerType.swift
//  ledger-wallet-ios
//
//  Created by Nicolas Bigot on 02/12/2015.
//  Copyright © 2015 Ledger. All rights reserved.
//

import Foundation

let WalletManagerDidStartRefreshingTransactionsNotification = "WalletManagerDidStartRefreshingTransactionsNotification"
let WalletManagerDidStopRefreshingTransactionsNotification = "WalletManagerDidStopRefreshingTransactionsNotification"
let WalletManagerDidUpdateAccountsNotification = "WalletManagerDidUpdateAccountsNotification"
let WalletManagerDidUpdateOperationsNotification = "WalletManagerDidUpdateOperationsNotification"
let WalletManagerDidMissAccountNotification = "WalletManagerDidMissAccountNotification"

protocol WalletManagerType: class {
    
    var uniqueIdentifier: String { get }
    var isRefreshingTransactions: Bool { get }
    var fetchRequestBuilder: WalletFetchRequestBuilder! { get }
    
    func startRefreshingTransactions()
    func stopRefreshingTransactions()
    func stopAllServices()
        
    init?(uniqueIdentifier: String, servicesProvider: ServicesProviderType)
    
}