//
//  UIView+Init.swift
//  ledger-wallet-ios
//
//  Created by Nicolas Bigot on 13/01/2015.
//  Copyright (c) 2015 Ledger. All rights reserved.
//

import UIKit

extension UIView {
    
    convenience init(localizableValue: String, style: String) {
        self.init(frame: CGRectZero)
        self.style = style
        self.localizableValue = localizableValue
    }
    
}