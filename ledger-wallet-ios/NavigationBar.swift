//
//  NavigationBar.swift
//  ledger-wallet-ios
//
//  Created by Nicolas Bigot on 07/01/2015.
//  Copyright (c) 2015 Ledger. All rights reserved.
//

import UIKit

class NavigationBar: UINavigationBar {
    
    override func intrinsicContentSize() -> CGSize {
        return CGSize(width: UIViewNoIntrinsicMetric, height: 80)
    }
    
}