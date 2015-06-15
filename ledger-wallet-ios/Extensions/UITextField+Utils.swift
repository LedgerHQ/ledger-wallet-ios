//
//  UITextField+Utils.swift
//  ledger-wallet-ios
//
//  Created by Nicolas Bigot on 20/01/2015.
//  Copyright (c) 2015 Ledger. All rights reserved.
//

import UIKit

extension UITextField {
    
    func readableText() -> String {
        return text ?? ""
    }
    
    func readablePlaceholder() -> String {
        return placeholder ?? ""
    }
    
}
