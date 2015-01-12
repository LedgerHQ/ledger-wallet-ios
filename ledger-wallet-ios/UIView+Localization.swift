//
//  UIView+Localization.swift
//  ledger-wallet-ios
//
//  Created by Nicolas Bigot on 12/01/2015.
//  Copyright (c) 2015 Ledger. All rights reserved.
//

import UIKit

private var localizationValueKey = "localizableValue"

extension UIView {
    
    //MARK: Localization
    
    @IBInspectable var localizableValue: String? {
        get {
            return objc_getAssociatedObject(self, &localizationValueKey) as? String
        }
        set {
            objc_setAssociatedObject(self, &localizationValueKey, newValue, objc_AssociationPolicy(OBJC_ASSOCIATION_RETAIN_NONATOMIC))
            ViewStylist.stylizeView(self)
        }
    }
    
    var localizedValue: String {
        if let value = localizableValue {
            return localizedString(value)
        }
        return ""
    }
    
}