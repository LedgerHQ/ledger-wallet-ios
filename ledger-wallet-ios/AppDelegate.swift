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

    private var coreDataStack: CoreDataStack!
    
    // MARK: - States management
    
    var window: UIWindow?

    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        // handle app launch
        ApplicationManager.sharedInstance.handleLaunchWithOptions(launchOptions)
        
        // clear stale log files
        LogWriter.sharedInstance.cleanStaleLogFiles()
        
        // remove all tmp files
        ApplicationManager.sharedInstance.clearTemporaryDirectory()

        // create coredata stack
        coreDataStack = CoreDataStack(storeType: .Sqlite, modelName: LedgerCoreDataModelName) { success in
            // switch to root view controller
            let rootViewController = PairingHomeViewController.instantiateFromStoryboard(StoryboardFactory.storyboardWithIdentifier(.Pairing))
            self.window?.rootViewController = Navigator.embedViewController(rootViewController)
        }
        
        // create launch screen view controller
        window = UIWindow(frame: UIScreen.mainScreen().bounds)
        window?.rootViewController = LaunchScreenViewController.instantiateFromMainStoryboard()
        window?.makeKeyAndVisible()
        return true
    }

    func applicationDidBecomeActive(application: UIApplication) {
        // register remote notifications
        RemoteNotificationsManager.sharedInstance.registerForRemoteNotifications()
    }
    
    func applicationWillTerminate(application: UIApplication) {
        // save CoreData
        coreDataStack.saveAndWait(true)
    }
    
    func applicationWillResignActive(application: UIApplication) {
        // save CoreData
        coreDataStack.saveAndWait(true)
    }
    
    func applicationDidEnterBackground(application: UIApplication) {
        // save CoreData
        coreDataStack.saveAndWait(true)
    }
    
    // MARK: - Remote notifications
    
    func application(application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: NSData) {
        // refresh device token
        RemoteNotificationsManager.sharedInstance.handleNewDeviceToken(deviceToken)
    }

}

