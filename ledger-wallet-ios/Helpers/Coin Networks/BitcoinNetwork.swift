//
//  BitcoinNetwork.swift
//  ledger-wallet-ios
//
//  Created by Nicolas Bigot on 08/01/2016.
//  Copyright © 2016 Ledger. All rights reserved.
//

import Foundation

struct BitcoinNetwork: CoinNetworkType {
    
    let identifier = "btc-mainnet"
    let name = "Bitcoin Mainnet"
    let isTest = false
    let BIP44Index = 0
    let acronym = "btc"
    let extendedPublicKeyVersionData = BTCDataFromHex("0488B21E")!

}