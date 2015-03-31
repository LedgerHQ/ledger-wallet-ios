//
//  ViewStylist.swift
//  ledger-wallet-ios
//
//  Created by Nicolas Bigot on 12/01/2015.
//  Copyright (c) 2015 Ledger. All rights reserved.
//

import UIKit

class ViewStylist {
    
    class func stylizeView(view: UIView) {
        switch view {
        case is Label:
            relookLabel(view as Label)
        case is Button:
            relookButton(view as Button)
        case is TextField:
            relookTextField(view as TextField)
        default:
            relookView(view)
        }
    }
    
    private class func relookView(view: UIView) {
        if let allure = view.allure {
            // apply allure if present
            if let styleClosure = VisualTheme.viewAllures[allure] {
                styleClosure(view)
            }
            else {
                println("ViewStylist: Unable to find view style: \(allure)")
            }
        }
    }
    
    private class func relookLabel(label: Label) {
        if let allure = label.allure {
            // apply allure if present
            if let allureClosure = VisualTheme.labelAllures[allure] {
                allureClosure(label)
            }
            else {
                println("ViewStylist: Unable to find label allure: \(allure)")
            }
        }
    }
    
    private class func relookButton(button: Button) {
        if let allure = button.allure {
            // apply allure if present
            if let allureClosure = VisualTheme.buttonAllures[allure] {
                allureClosure(button)
            }
            else {
                println("ViewStylist: Unable to find button allure: \(allure)")
            }
        }
    }
    
    private class func relookTextField(textField: TextField) {
        if let allure = textField.allure {
            // apply allure if present
            if let allureClosure = VisualTheme.textFieldAllures[allure] {
                allureClosure(textField)
            }
            else {
                println("ViewStylist: Unable to find textField allure: \(allure)")
            }
        }
    }

}