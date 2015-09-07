//
//  AppDelegate.swift
//  ledger-wallet-ios
//
//  Created by Nicolas Bigot on 07/01/2015.
//  Copyright (c) 2015 Ledger. All rights reserved.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    // MARK: - States management
    
    var window: UIWindow?

    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        // print library path
        ApplicationManager.sharedInstance().printLibraryPathIfNeeded()
        
        // handle first app launch
        ApplicationManager.sharedInstance().handleFirstLaunch()
        
        // handle entry point without being embedded in a navigation controller
        if let viewController = window?.rootViewController as? BaseViewController {
            window?.rootViewController = Navigator.embedViewController(viewController)
        }
        return true
    }

    func applicationDidBecomeActive(application: UIApplication) {
        // register remote notifications
        RemoteNotificationsManager.sharedInstance().registerForRemoteNotifications()
        
        // clear stale log files
        LogWriter.sharedInstance().cleanStaleLogFiles()
    
        // remove all tmp files
        ApplicationManager.sharedInstance().clearTemporaryDirectory()
    }

    // MARK: - Remote notifications
    
    func application(application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: NSData) {
        // refresh device token
        RemoteNotificationsManager.sharedInstance().handleNewDeviceToken(deviceToken)
    }

}

