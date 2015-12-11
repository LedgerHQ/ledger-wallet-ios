//
//  WalletManagerType.swift
//  ledger-wallet-ios
//
//  Created by Nicolas Bigot on 02/12/2015.
//  Copyright © 2015 Ledger. All rights reserved.
//

import Foundation

let WalletManagerDidStartRefreshingLayoutNotification = "WalletManagerDidStartRefreshingLayoutNotification"
let WalletManagerDidStopRefreshingLayoutNotification = "WalletManagerDidStopRefreshingLayoutNotification"
let WalletManagerDidStartListeningTransactionsNotification = "WalletManagerDidStartListeningTransactionsNotification"
let WalletManagerDidStopListeningTransactionsNotification = "WalletManagerDidStopListeningTransactionsNotification"

protocol WalletManagerType: class {
    
    var uniqueIdentifier: String { get }
    var isRefreshingLayout: Bool { get }
    var isListeningTransactions: Bool { get }
    
    func startRefreshingLayout()
    func stopRefreshingLayout()
    func startListeningTransactions()
    func stopListeningTransactions()
    func startAllServices()
    func stopAllServices()
    func registerAccount(account: WalletAccountModel)
    
    init(uniqueIdentifier: String)
    
}