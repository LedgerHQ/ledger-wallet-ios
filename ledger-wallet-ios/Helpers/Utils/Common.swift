//
//  Common.swift
//  ledger-wallet-ios
//
//  Created by Nicolas Bigot on 28/01/2015.
//  Copyright (c) 2015 Ledger. All rights reserved.
//

import Foundation

// URLs
let LedgerWebSocketBaseURL = "wss://ws.ledgerwallet.com"
let LedgerAPIBaseURL = "https://api.ledgerwallet.com"
let LedgerHelpCenterURL = "http://support.ledgerwallet.com"

// Attestation keys
//let LedgerDongleAttestationBase16Key = "04e69fd3c044865200e66f124b5ea237c918503931bee070edfcab79a00a25d6b5a09afbee902b4b763ecf1f9c25f82d6b0cf72bce3faf98523a1066948f1a395f" // beta
let LedgerDongleAttestationBase16Key = "04c370d4013107a98dfef01d6db5bb3419deb9299535f0be47f05939a78b314a3c29b51fcaa9b3d46fa382c995456af50cd57fb017c0ce05e4a31864a79b8fbfd6" // production
let LedgerDongleAttestationKeyData = Crypto.Encode.dataFromBase16String(LedgerDongleAttestationBase16Key)!