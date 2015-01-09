//
//  BackgroundView.swift
//  ledger-wallet-ios
//
//  Created by Nicolas Bigot on 09/01/2015.
//  Copyright (c) 2015 Ledger. All rights reserved.
//

import UIKit

class BackgroundView: UIView {
    
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.configure()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.configure()
    }
    
    override func configure() {
        self.backgroundColor = VisualFactory.Colors.backgroundColor
    }
    
}
