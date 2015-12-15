//
//  RemoteNotificationsAPIClient.swift
//  ledger-wallet-ios
//
//  Created by Nicolas Bigot on 12/02/2015.
//  Copyright © 2015 Ledger. All rights reserved.
//

import Foundation

final class RemoteNotificationsAPIClient: LedgerAPIClient {
    
    private let logger = Logger.sharedInstance(name: "RemoteNotificationsAPIClient")
    
    // MARK: Push token management
    
    func registerDeviceToken(token: NSData, toPairingId pairingId: String, completion: (Bool) -> Void) {
        guard let tokenBase16String = BTCHexFromData(token) else {
            delegateQueue.addOperationWithBlock() { completion(false) }
            return
        }
        
        restClient.post("/2fa/pairings/\(pairingId)/push_token", parameters: ["push_token": tokenBase16String]) { [weak self] data, request, response, error in
            guard let strongSelf = self else { return }
            
            let success = error == nil && response != nil
            if !success {
                strongSelf.logger.error("Unable to register device token to pairing id \(pairingId)")
            }
            strongSelf.delegateQueue.addOperationWithBlock() { completion(success) }
        }
    }
    
    func unregisterDeviceTokenFromPairingId(pairingId: String, completion: (Bool) -> Void) {
        restClient.delete("/2fa/pairings/\(pairingId)/push_token") { [weak self] data, request, response, error in
            guard let strongSelf = self else { return }
            
            let success = error == nil && response != nil
            if !success {
                strongSelf.logger.error("Unable to unregister device token from pairing id \(pairingId)")
            }
            strongSelf.delegateQueue.addOperationWithBlock() { completion(success) }
        }
    }
    
}