//
//  ViewStylist.swift
//  ledger-wallet-ios
//
//  Created by Nicolas Bigot on 12/01/2015.
//  Copyright (c) 2015 Ledger. All rights reserved.
//

import UIKit

final class ViewStylist {
    
    typealias AllureBlock = (UIView) -> Void
    
    class func stylizeView(view: UIView) {
        // check if full allure style name is present and apply it
        if let styleName = view.allureStyleName {
            if let allureBlock = VisualTheme.allureBlocks["\(styleName)"] {
                allureBlock(view)
                return
            }
            console("ViewStylist: Unable to find allure \"\(styleName)\" for view \(view)")
        }
    }
    
    class func wrapAllureBlock<T>(allureBlock: (T) -> Void) -> AllureBlock {
        return { view in
            // cast the view as the type desired by the allure block
            if let view = view as? T {
                allureBlock(view)
                return
            }
            console("ViewStylist: Cannot apply allure \"\(view.allureStyleName)\" to view \(view)")
        }
    }

}