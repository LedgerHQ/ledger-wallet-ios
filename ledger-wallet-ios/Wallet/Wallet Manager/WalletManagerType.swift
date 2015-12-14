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
let WalletManagerDidStartListeningTransactionsNotification = "WalletManagerDidStartListeningTransactionsNotification"
let WalletManagerDidStopListeningTransactionsNotification = "WalletManagerDidStopListeningTransactionsNotification"

protocol WalletManagerType: class {
    
    var uniqueIdentifier: String { get }
    var isRefreshingTransactions: Bool { get }
    var isListeningTransactions: Bool { get }
    
    func startRefreshingTransactions()
    func stopRefreshingTransactions()
    func startListeningTransactions()
    func stopListeningTransactions()
    func startAllServices()
    func stopAllServices()
    func registerAccount(account: WalletAccountModel)
    
    init(uniqueIdentifier: String)
    
}