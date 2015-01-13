//
//  Button.swift
//  ledger-wallet-ios
//
//  Created by Nicolas Bigot on 13/01/2015.
//  Copyright (c) 2015 Ledger. All rights reserved.
//

import UIKit

class Button: UIButton {
    
    //MARK: Style management
    
    override func setTitle(title: String?, forState state: UIControlState) {
        super.setTitle(title, forState: state)
        ViewStylist.stylizeView(self)
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.setTitle(localizedString(self.titleForState(UIControlState.Normal) ?? ""), forState: UIControlState.Normal)
    }
    
}
