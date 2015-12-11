//
//  RemoteNotificationsManager.swift
//  ledger-wallet-ios
//
//  Created by Nicolas Bigot on 12/02/2015.
//  Copyright (c) 2015 Ledger. All rights reserved.
//

import Foundation

final class RemoteNotificationsManager {
    
    static let sharedInstance = RemoteNotificationsManager()
    private let restClient = RemoteNotificationsAPIClient(delegateQueue: NSOperationQueue.mainQueue())

    // MARK: Common
    
    func registerForRemoteNotifications() {
        let application = UIApplication.sharedApplication()
        application.registerUserNotificationSettings(UIUserNotificationSettings(forTypes: ([.Badge, .Sound, .Alert]), categories: nil));
        application.registerForRemoteNotifications()
    }
    
    func handleNewDeviceToken(token: NSData) {
        registerDeviceTokenToPairedDongles(token)
    }
    
    // MARK: Pairing
    
    func registerDeviceTokenToPairedDongles(token: NSData) {
        // loop through all pairing keychain items
        guard let allItems = PairingKeychainItem.fetchAll() as? [PairingKeychainItem] else { return }
        for item in allItems {
            // if pairing item has no (or outdated) device token
            if item.deviceToken == nil || item.deviceToken! != token {
                restClient.registerDeviceToken(token, toPairingId: item.pairingId!) { success in
                    if (success) {
                        item.deviceToken = token
                    }
                }
            }
        }
    }
    
    func unregisterDeviceTokenFromPairedDongleWithId(pairingId: String) {
        // if pairing item already registered a device token
        restClient.unregisterDeviceTokenFromPairingId(pairingId) { _ in }
    }
    
    // MARK: Initialization
    
    private init() {
        
    }
    
}