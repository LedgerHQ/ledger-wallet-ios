//
//  UIView+Allure.swift
//  ledger-wallet-ios
//
//  Created by Nicolas Bigot on 12/01/2015.
//  Copyright (c) 2015 Ledger. All rights reserved.
//

import UIKit

private var allureKey = "allure"

extension UIView {
    
    // MARK: - Allure
    
    @IBInspectable var allure: String? {
        get {
            return objc_getAssociatedObject(self, &allureKey) as? String
        }
        set {
            objc_setAssociatedObject(self, &allureKey, newValue, objc_AssociationPolicy(OBJC_ASSOCIATION_RETAIN_NONATOMIC))
            ViewStylist.stylizeView(self)
        }
    }
    
    var allureStyleName: String? {
        if let allure = allure {
            if allure.hasPrefix("_") {
                return allure.stringByReplacingCharactersInRange(allure.startIndex...allure.startIndex, withString: "")
            }
            return allureClassName + "." + allure
        }
        return nil
    }
    
    private var allureClassName: String {
        var className = self.className().stringByReplacingOccurrencesOfString("UI", withString: "")
        className.replaceRange(className.startIndex...className.startIndex, with: String(className[className.startIndex]).lowercaseString)
        return className
    }
    
}
