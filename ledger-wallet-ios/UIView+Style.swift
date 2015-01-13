//
//  UIView+Style.swift
//  ledger-wallet-ios
//
//  Created by Nicolas Bigot on 12/01/2015.
//  Copyright (c) 2015 Ledger. All rights reserved.
//

import UIKit

private var styleKey = "style"

extension UIView {
    
    //MARK: Styles
    
    @IBInspectable var style: String? {
        get {
            return objc_getAssociatedObject(self, &styleKey) as? String
        }
        set {
            objc_setAssociatedObject(self, &styleKey, newValue, objc_AssociationPolicy(OBJC_ASSOCIATION_RETAIN_NONATOMIC))
            ViewStylist.stylizeView(self)
        }
    }
    
    convenience init(style: String) {
        self.init(frame: CGRectZero)
        self.style = style
    }
    
}
