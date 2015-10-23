//
//  DeviceManager.swift
//  ledger-wallet-ios
//
//  Created by Nicolas Bigot on 20/01/2015.
//  Copyright (c) 2015 Ledger. All rights reserved.
//

import Foundation
import AudioToolbox

final class DeviceManager {
    
    enum HeightClass {
        case Small
        case Medium
        case Large
    }
    
    static let sharedInstance = DeviceManager()
    var deviceName: String { return UIDevice.currentDevice().name }
    var screenSize: CGSize { return UIScreen.mainScreen().bounds.size }
    var screenScale: CGFloat { return UIScreen.mainScreen().scale }
    var screenHeightClass: HeightClass {
        switch screenSize.height {
        case 480.0: return HeightClass.Small
        case 568.0: return HeightClass.Medium
        default: return HeightClass.Large
        }
    }

    func vibrate() {
        AudioServicesPlaySystemSound(SystemSoundID(kSystemSoundID_Vibrate))
    }
    
    // MARK: Initialization
    
    private init() {
        
    }
    
}
