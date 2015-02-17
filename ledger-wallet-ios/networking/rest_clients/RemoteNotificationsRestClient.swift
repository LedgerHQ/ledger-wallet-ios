//
//  RemoteNotificationsRestClient.swift
//  ledger-wallet-ios
//
//  Created by Nicolas Bigot on 12/02/2015.
//  Copyright (c) 2015 Ledger. All rights reserved.
//

import Foundation

class RemoteNotificationsRestClient: BaseRestClient {
    
    // MARK: - Push token management
    
    func registerDeviceToken(token: NSData, toPairingId pairingId: String, completion: ((Bool) -> Void)?) {
        post("/2fa/pairings/push_token", parameters: ["pairing_id": pairingId, "push_token": Crypto.Encode.base16StringFromData(token)]) { data, request, response, error in
            completion?(error == nil && response != nil)
        }
    }
    
    func unregisterDeviceToken(token: NSData, fromPairingId pairingId: String, completion: ((Bool) -> Void)?) {
        delete("/2fa/pairings/\(pairingId)/push_token") { data, request, response, error in
            completion?(error == nil && response != nil)
        }
    }
    
}