//
//  CoinNetworkType.swift
//  ledger-wallet-ios
//
//  Created by Nicolas Bigot on 08/01/2016.
//  Copyright © 2016 Ledger. All rights reserved.
//

import Foundation

protocol CoinNetworkType {
    
    var identifier: String { get }
    var name: String { get }
    var acronym: String { get }
    
    var BIP44Index: Int { get }
    var extendedPublicKeyVersionData: NSData { get }
    var publicKeyHashPrefix: UInt8 { get }
    var scriptHashPrefix: UInt8 { get }
    
}

private let globalCoinNetworkTypes: [CoinNetworkType] = [
    BitcoinNetwork()
]

func coinNetworkTypeWithIdentifier(identifier: String) -> CoinNetworkType? {
    return globalCoinNetworkTypes.filter({ $0.identifier == identifier }).first
}