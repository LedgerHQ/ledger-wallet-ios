//
//  Common.swift
//  ledger-wallet-ios
//
//  Created by Nicolas Bigot on 28/01/2015.
//  Copyright (c) 2015 Ledger. All rights reserved.
//

import Foundation

// URLs
let LedgerWebSocketBaseURL = "wss://ws02.ledgerwallet.com" //"ws://192.168.2.107:8080"
let LedgerAPIBaseURL = "https://api02.ledgerwallet.com"
let LedgerHelpCenterURL = "http://support.ledgerwallet.com"

// Attestation keys
let LedgerDongleAttestationBase16Key = "04e69fd3c044865200e66f124b5ea237c918503931bee070edfcab79a00a25d6b5a09afbee902b4b763ecf1f9c25f82d6b0cf72bce3faf98523a1066948f1a395f"
let LedgerDongleAttestationKeyData = Crypto.Encode.dataFromBase16String(LedgerDongleAttestationBase16Key)