//
//  NotificationsManager.swift
//  ledger-wallet-ios
//
//  Created by Nicolas Bigot on 12/02/2015.
//  Copyright (c) 2015 Ledger. All rights reserved.
//

import Foundation

class NotificationsManager: BaseManager {
    
    func registerForRemoteNotifications() {
        let application = UIApplication.sharedApplication()
        if (application.respondsToSelector("isRegisteredForRemoteNotifications"))
        {
            // iOS 8 Notifications
            application.registerUserNotificationSettings(UIUserNotificationSettings(forTypes: (.Badge | .Sound | .Alert), categories: nil));
            application.registerForRemoteNotifications()
        }
        else
        {
            // iOS < 8 Notifications
            application.registerForRemoteNotificationTypes(.Badge | .Sound | .Alert)
        }
    }
    
    func handleNewDeviceToken(token: NSData) {
        registerDeviceTokenToPairedDongles(token)
    }
    
    func registerDeviceTokenToPairedDongles(token: NSData) {
        // loop through all pairing keychain items
        let allItems = PairingKeychainItem.fetchAll() as! [PairingKeychainItem]
        for item in allItems {
            // if pairing item has no (or outdated) device token
            if item.deviceToken == nil || item.deviceToken! != token {
                RemoteNotificationsRestClient.sharedInstance().registerDeviceToken(token, toPairingId: item.pairingId!, completion: { success in
                    if (success) {
                        item.deviceToken = token
                    }
                })
            }
        }
    }
    
    func unregisterDeviceTokenFromPairedDongle(pairingItem: PairingKeychainItem) {
        // if pairing item already registered a device token
        if (pairingItem.deviceToken != nil) {
            RemoteNotificationsRestClient.sharedInstance().unregisterDeviceToken(pairingItem.deviceToken!, fromPairingId: pairingItem.pairingId!, completion: nil)
        }
    }
    
}