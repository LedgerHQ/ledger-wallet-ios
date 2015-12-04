//
//  RemoteNotificationsRESTClient.swift
//  ledger-wallet-ios
//
//  Created by Nicolas Bigot on 12/02/2015.to pairing id \(pairingId)//  Copyright (c) 2015 Ledger. All rights reserved.
//

import Foundation

final class RemoteNotificationsRESTClient: LedgerAPIRESTClient {
    
    private let logger = Logger.sharedInstance(name: "RemoteNotificationsRESTClient")
    
    // MARK: - Push token management
    
    func registerDeviceToken(token: NSData, toPairingId pairingId: String, completion: (Bool) -> Void) {
        guard let tokenBase16String = BTCHexFromData(token) else {
            completion(false)
            return
        }
        
        post("/2fa/pairings/\(pairingId)/push_token", parameters: ["push_token": tokenBase16String]) { [weak self] data, request, response, error in
            guard let strongSelf = self else { return }
            
            let success = error == nil && response != nil
            if !success {
                strongSelf.logger.error("Unable to register device token to pairing id \(pairingId)")
            }
            dispatchAsyncOnMainQueue() { [weak self] in
                guard self != nil else { return }
                completion(success)
            }
        }
    }
    
    func unregisterDeviceTokenFromPairingId(pairingId: String, completion: (Bool) -> Void) {
        delete("/2fa/pairings/\(pairingId)/push_token") { [weak self] data, request, response, error in
            guard let strongSelf = self else { return }
            
            let success = error == nil && response != nil
            if !success {
                strongSelf.logger.error("Unable to unregister device token from pairing id \(pairingId)")
            }
            dispatchAsyncOnMainQueue() { [weak self] in
                guard self != nil else { return }
                completion(success)
            }
        }
    }
    
}