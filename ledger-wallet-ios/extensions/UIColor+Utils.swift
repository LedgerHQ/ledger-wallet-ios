//
//  UIColor+Init.swift
//  ledger-wallet-ios
//
//  Created by Nicolas Bigot on 09/01/2015.
//  Copyright (c) 2015 Ledger. All rights reserved.
//

import UIKit

extension UIColor {
    
    // MARK: - Hex initialization
    
    convenience init(red: Int, green: Int, blue: Int) {
        assert(red >= 0 && red <= 255, "Invalid red component")
        assert(green >= 0 && green <= 255, "Invalid green component")
        assert(blue >= 0 && blue <= 255, "Invalid blue component")
        self.init(red: CGFloat(red) / 255.0, green: CGFloat(green) / 255.0, blue: CGFloat(blue) / 255.0, alpha: 1.0)
    }
    
    convenience init(hex: Int) {
        self.init(red:(hex >> 16) & 0xFF, green:(hex >> 8) & 0xFF, blue:hex & 0xFF)
    }
    
    // MARK: - Darker and Lighter
    
    func brighterColor(factor: CGFloat = VisualFactory.Metrics.defaultDarkenFactor) -> UIColor {
        var h:CGFloat = 0.0, s:CGFloat = 0.0, b:CGFloat = 0.0, a:CGFloat = 0.0
        if (self.getHue(&h, saturation: &s, brightness: &b, alpha: &a)) {
            return UIColor(hue: h, saturation: s, brightness: min(b * (1.0 + factor), CGFloat(1.0)), alpha: a)
        }
        return self
    }
    
    func darkerColor(factor: CGFloat = VisualFactory.Metrics.defaultDarkenFactor) -> UIColor {
        var h:CGFloat = 0.0, s:CGFloat = 0.0, b:CGFloat = 0.0, a:CGFloat = 0.0
        if (self.getHue(&h, saturation: &s, brightness: &b, alpha: &a)) {
            return UIColor(hue: h, saturation: s, brightness: b * (1.0 - factor), alpha: a)
        }
        return self
    }
    
}