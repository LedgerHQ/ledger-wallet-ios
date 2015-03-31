//
//  BaseManager.swift
//  ledger-wallet-ios
//
//  Created by Nicolas Bigot on 09/03/2015.
//  Copyright (c) 2015 Ledger. All rights reserved.
//

import Foundation

class BaseManager: SharableObject {
    
    var preferences: Preferences {
        if (_preferences == nil) {
            _preferences = Preferences(storeName: self.className())
        }
        return _preferences
    }
    private var _preferences: Preferences! = nil
    
}