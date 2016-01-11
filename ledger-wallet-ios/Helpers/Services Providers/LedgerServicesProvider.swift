//
//  LedgerServicesProvider.swift
//  ledger-wallet-ios
//
//  Created by Nicolas Bigot on 08/01/2016.
//  Copyright © 2016 Ledger. All rights reserved.
//

import Foundation

private enum LedgerAPIHeaderFields: String {
    
    case Platform = "X-Ledger-Platform"
    case Environment = "X-Ledger-Environment"
    case Locale = "X-Ledger-Locale"
    
}

final class LedgerServicesProvider: ServicesProviderType {
    
    let name = "Ledger Services Provider"
    let coinNetwork: CoinNetworkType
    
    // MARK: Base URLs
    
    let websocketBaseURL = NSURL(string: "wss://ws.ledgerwallet.com")!
    let APIBaseURL = NSURL(string: "https://api.ledgerwallet.com")!
    let supportBaseURL = NSURL(string: "http://support.ledgerwallet.com")!
    
    // MARK: Endpoint URLs
    
    var walletEventsWebsocketURL: NSURL {
        let path = "/blockchain/\(coinNetwork.identifier)/ws"
        return NSURL(string: path, relativeToURL: websocketBaseURL)!
    }
    
    var m2FAChannelsWebsocketURL: NSURL {
        return NSURL(string: "/2fa/channels", relativeToURL: websocketBaseURL)!
    }

    func walletTransactionsURLForAddresses(addresses: [String]) -> NSURL {
        let path = "/blockchain/\(coinNetwork.identifier)/addresses/\(addresses.joinWithSeparator(","))/transactions"
        return NSURL(string: path, relativeToURL: APIBaseURL)!
    }
    
    func m2FAPushTokensURLForPairingId(pairingId: String) -> NSURL {
        let path = "/2fa/pairings/\(pairingId)/push_token"
        return NSURL(string: path, relativeToURL: APIBaseURL)!
    }
    
    // Attestation keys
    
    let attestationKeys = [
        AttestationKey(batchID: 0x00, derivationID: 0x01, publicKey: "04e69fd3c044865200e66f124b5ea237c918503931bee070edfcab79a00a25d6b5a09afbee902b4b763ecf1f9c25f82d6b0cf72bce3faf98523a1066948f1a395f"),     // beta
        AttestationKey(batchID: 0x01, derivationID: 0x01, publicKey: "04223314cdffec8740150afe46db3575fae840362b137316c0d222a071607d61b2fd40abb2652a7fea20e3bb3e64dc6d495d59823d143c53c4fe4059c5ff16e406"),     // production (pre 1.4.11)
        AttestationKey(batchID: 0x02, derivationID: 0x01, publicKey: "04c370d4013107a98dfef01d6db5bb3419deb9299535f0be47f05939a78b314a3c29b51fcaa9b3d46fa382c995456af50cd57fb017c0ce05e4a31864a79b8fbfd6")      // production (post 1.4.11)
    ]
    
    // HTTP headers
    
    var httpHeaders: [String: String] {
        var headers: [String: String] = [
            LedgerAPIHeaderFields.Platform.rawValue: "ios",
            LedgerAPIHeaderFields.Locale.rawValue: NSLocale.currentLocale().localeIdentifier
        ]
        #if DEBUG
            headers[LedgerAPIHeaderFields.Environment.rawValue] = "dev"
        #else
            headers[LedgerAPIHeaderFields.Environment.rawValue] = "prod"
        #endif
        return headers
    }
    
    init(coinNetwork: CoinNetworkType) {
        self.coinNetwork = coinNetwork
    }

}