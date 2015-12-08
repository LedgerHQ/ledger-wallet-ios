//
//  BaseWalletManager.swift
//  ledger-wallet-ios
//
//  Created by Nicolas Bigot on 02/12/2015.
//  Copyright © 2015 Ledger. All rights reserved.
//

import Foundation

let WalletManagerDidStartRefreshingLayoutNotification = "WalletManagerDidStartRefreshingLayoutNotification"
let WalletManagerDidStopRefreshingLayoutNotification = "WalletManagerDidStopRefreshingLayoutNotification"

protocol BaseWalletManager: class {
    
    var uniqueIdentifier: String { get }
    var isRefreshingLayout: Bool { get }
    
    init(uniqueIdentifier: String)
    func startRefreshingLayout()
    func stopRefreshingLayout()
    func startListeningTransactions()
    func stopListeningTransactions()
    func startAllServices()
    func stopAllServices()
    
}