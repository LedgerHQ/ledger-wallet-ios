//
//  Localization.swift
//  ledger-wallet-ios
//
//  Created by Nicolas Bigot on 12/01/2015.
//  Copyright (c) 2015 Ledger. All rights reserved.
//

import Foundation

func localizedString(key: String) -> String {
    if key.hasPrefix("_") {
        return key
    }

    // get localization
    var string = NSLocalizedString(key, comment: "")
    
    // if localization is not found
    if string == key && ApplicationManager.sharedInstance.currentLocale != ApplicationManager.sharedInstance.developmentLocale {
        string = ApplicationManager.sharedInstance.developmentLocalizationBundle.localizedStringForKey(key, value: nil, table: nil)
    }
    return string
}