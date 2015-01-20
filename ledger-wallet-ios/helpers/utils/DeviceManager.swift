//
//  DeviceManager.swift
//  ledger-wallet-ios
//
//  Created by Nicolas Bigot on 20/01/2015.
//  Copyright (c) 2015 Ledger. All rights reserved.
//

import Foundation

class DeviceManager {
    
    enum HeightClass: CGFloat {
        case Small
        case Medium
        case Large
    }
    
    class func screenSize() -> CGSize {
        return UIScreen.mainScreen().bounds.size
    }
    
    class func screenHeightClass() -> HeightClass {
        switch screenSize().height {
        case 480.0: return HeightClass.Small
        case 568.0: return HeightClass.Medium
        default: return HeightClass.Large
        }
    }
    
}
