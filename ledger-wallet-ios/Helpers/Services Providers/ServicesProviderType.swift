//
//  ServicesProviderType.swift
//  ledger-wallet-ios
//
//  Created by Nicolas Bigot on 08/01/2016.
//  Copyright © 2016 Ledger. All rights reserved.
//

import Foundation

protocol ServicesProviderType {
    
    var name: String { get }
    var coinNetwork: CoinNetworkType { get }
    
    // Base URLs
    var websocketBaseURL: NSURL { get }
    var APIBaseURL: NSURL { get }
    var supportBaseURL: NSURL { get }
    
    // Endpoint URLs
    var walletEventsWebsocketURL: NSURL { get }
    var m2FAChannelsWebsocketURL: NSURL { get }
    func walletTransactionsURLForAddresses(addresses: [String]) -> NSURL
    func m2FAPushTokensURLForPairingId(pairingId: String) -> NSURL

    // Attestation keys
    var attestationKeys: [AttestationKey] { get }
    
    // HTTP headers
    var httpHeaders: [String: String] { get }
    
    init(coinNetwork: CoinNetworkType)
    
}