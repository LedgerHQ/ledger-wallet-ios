//
//  Label.swift
//  ledger-wallet-ios
//
//  Created by Nicolas Bigot on 13/01/2015.
//  Copyright (c) 2015 Ledger. All rights reserved.
//

import UIKit

class Label: UILabel {
    
    //MARK: Style management
    
    override var text: String? {
        didSet {
            ViewStylist.stylizeView(self)
        }
    }

    //MARK: Localization
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.text = localizedString(self.text ?? "")
    }
    
}
