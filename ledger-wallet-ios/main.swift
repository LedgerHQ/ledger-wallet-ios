//
//  main.swift
//  ledger-wallet-ios
//
//  Created by Nicolas Bigot on 19/11/2015.
//  Copyright © 2015 Ledger. All rights reserved.
//

import UIKit

#if TEST
    UIApplicationMain(Process.argc, Process.unsafeArgv, NSStringFromClass(UIApplication), NSStringFromClass(TestAppDelegate))
#else
    UIApplicationMain(Process.argc, Process.unsafeArgv, NSStringFromClass(UIApplication), NSStringFromClass(AppDelegate))
#endif
