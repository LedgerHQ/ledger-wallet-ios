//
//  DeviceManager.swift
//  ledger-wallet-ios
//
//  Created by Nicolas Bigot on 20/01/2015.
//  Copyright (c) 2015 Ledger. All rights reserved.
//

import Foundation
import AudioToolbox

class DeviceManager: BaseManager {
    
    enum HeightClass {
        case Small
        case Medium
        case Large
    }
    
    class func screenSize() -> CGSize {
        return UIScreen.mainScreen().bounds.size
    }
    
    class func screenScale() -> CGFloat {
        return UIScreen.mainScreen().scale
    }
    
    class func screenHeightClass() -> HeightClass {
        switch screenSize().height {
        case 480.0: return HeightClass.Small
        case 568.0: return HeightClass.Medium
        default: return HeightClass.Large
        }
    }
    
    class func vibrate() {
        AudioServicesPlaySystemSound(SystemSoundID(kSystemSoundID_Vibrate))
    }
    
}
