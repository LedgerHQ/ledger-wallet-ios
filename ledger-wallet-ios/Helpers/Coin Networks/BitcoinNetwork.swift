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
    let acronym = "btc"
    
    let BIP44Index = 0
    let extendedPublicKeyVersionData = BTCDataFromHex("0488B21E")!
    let publicKeyHashPrefix: UInt8 = 0x00
    let scriptHashPrefix: UInt8 = 0x05

}