//
//  DeviceManager.swift
//  ledger-wallet-ios
//
//  Created by Nicolas Bigot on 20/01/2015.
//  Copyright (c) 2015 Ledger. All rights reserved.
//

import Foundation
import AudioToolbox

final class DeviceManager: SharableObject {
    
    enum HeightClass {
        case Small
        case Medium
        case Large
    }
    
    var screenSize: CGSize {
        return UIScreen.mainScreen().bounds.size
    }
    
    var screenScale: CGFloat {
        return UIScreen.mainScreen().scale
    }
    
    var screenHeightClass: HeightClass {
        switch screenSize.height {
        case 480.0: return HeightClass.Small
        case 568.0: return HeightClass.Medium
        default: return HeightClass.Large
        }
    }
    
    var deviceName: String {
        return UIDevice.currentDevice().name
    }
    
    func vibrate() {
        AudioServicesPlaySystemSound(SystemSoundID(kSystemSoundID_Vibrate))
    }
    
}
