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
        if let styleName = allureStyleName(view) {
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
            console("ViewStylist: Cannot apply allure \"\(allureStyleName(view))\" to view \(view)")
        }
    }
    
    private class func allureStyleName(view: UIView) -> String? {
        if let allure = view.allure {
            if allure.hasPrefix("_") {
                return allure.stringByReplacingCharactersInRange(allure.startIndex...allure.startIndex, withString: "")
            }
            return allureClassName(view) + "." + allure
        }
        return nil
    }
    
    private class func allureClassName(view: UIView) -> String {
        var className = view.className().stringByReplacingOccurrencesOfString("UI", withString: "")
        className.replaceRange(className.startIndex...className.startIndex, with: String(className[className.startIndex]).lowercaseString)
        return className
    }

}