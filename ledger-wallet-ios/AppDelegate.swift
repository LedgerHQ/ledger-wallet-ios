//
//  AppDelegate.swift
//  ledger-wallet-ios
//
//  Created by Nicolas Bigot on 07/01/2015.
//  Copyright (c) 2015 Ledger. All rights reserved.
//

import UIKit

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
        coreDataStack = CoreDataStack(storeType: .Sqlite, modelName: LedgerModelName)
        
        // handle root view controller
        window = UIWindow(frame: UIScreen.mainScreen().bounds)
        let rootViewController = Navigator.embedViewController(StoryboardFactory.storyboardWithIdentifier(.Pairing).instantiateInitialViewController()!)
        window?.rootViewController = rootViewController
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

