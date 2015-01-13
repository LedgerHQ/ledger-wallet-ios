//
//  UIButton+Utils.swift
//  ledger-wallet-ios
//
//  Created by Nicolas Bigot on 13/01/2015.
//  Copyright (c) 2015 Ledger. All rights reserved.
//

import Foundation

import UIKit

extension UIButton {
    
    func readableTitleForState(state: UIControlState) -> String {
        return self.titleForState(state) ?? ""
    }
    
}