//
//  CoinNetworkType.swift
//  ledger-wallet-ios
//
//  Created by Nicolas Bigot on 08/01/2016.
//  Copyright © 2016 Ledger. All rights reserved.
//

import Foundation

protocol CoinNetworkType {
    
    var name: String { get }
    var identifier: String { get }
    var isTest: Bool { get }
    
}