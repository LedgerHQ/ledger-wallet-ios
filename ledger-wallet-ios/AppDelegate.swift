//
//  AppDelegate.swift
//  ledger-wallet-ios
//
//  Created by Nicolas Bigot on 07/01/2015.
//  Copyright (c) 2015 Ledger. All rights reserved.
//

import UIKit
import CoreData

class AppDelegate: UIResponder, UIApplicationDelegate {
    
    // MARK: - States management
    
    var window: UIWindow?

    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        // handle app launch
        ApplicationManager.sharedInstance.handleLaunchWithOptions(launchOptions)

        // switch to root view controller
        let servicesProvider = LedgerServicesProvider(coinNetwork: BitcoinNetwork())
        window = UIWindow(frame: UIScreen.mainScreen().bounds)
        let rootViewController = WalletTestViewController.instantiateFromMainStoryboard()
        rootViewController.walletManager = WalletAPIManager(uniqueIdentifier: "identifier", servicesProvider: servicesProvider)
        window?.rootViewController = Navigator.embedViewController(rootViewController)
        window?.makeKeyAndVisible()
        return true
    }

//    func applicationDidBecomeActive(application: UIApplication) {
//        // register remote notifications
//        RemoteNotificationsManager.sharedInstance.registerForRemoteNotifications()
//    }
//    
//    // MARK: - Remote notifications
//    
//    func application(application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: NSData) {
//        // refresh device token
//        RemoteNotificationsManager.sharedInstance.handleNewDeviceToken(deviceToken)
//    }

}

