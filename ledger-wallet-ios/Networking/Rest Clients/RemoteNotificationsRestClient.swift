//
//  RemoteNotificationsRestClient.swift
//  ledger-wallet-ios
//
//  Created by Nicolas Bigot on 12/02/2015.
//  Copyright (c) 2015 Ledger. All rights reserved.
//

import Foundation

final class RemoteNotificationsRestClient: APIRestClient {
    
    // MARK: - Push token management
    
    func registerDeviceToken(token: NSData, toPairingId pairingId: String, completion: ((Bool) -> Void)?) {
        if let tokenBase16String = Crypto.Encode.base16StringFromData(token) {
            post("/2fa/pairings/\(pairingId)/push_token", parameters: ["push_token": tokenBase16String], encoding: .JSON) { data, request, response, error in
                completion?(error == nil && response != nil)
            }
        }
    }
    
    func unregisterDeviceTokenFromPairingId(pairingId: String, completion: ((Bool) -> Void)?) {
        delete("/2fa/pairings/\(pairingId)/push_token") { data, request, response, error in
            completion?(error == nil && response != nil)
        }
    }
    
}