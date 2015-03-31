//
//  TextField.swift
//  ledger-wallet-ios
//
//  Created by Nicolas Bigot on 20/01/2015.
//  Copyright (c) 2015 Ledger. All rights reserved.
//

import UIKit

@IBDesignable

class TextField: UITextField {

    // MARK: - Style management
    
    override var text: String! {
        didSet {
            ViewStylist.stylizeView(self)
        }
    }
    
    override var placeholder: String? {
        didSet {
            ViewStylist.stylizeView(self)
        }
    }
    
    // MARK: - Localization
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        self.text = localizedString(self.text ?? "")
        self.placeholder = localizedString(self.placeholder ?? "")
    }
    
}
