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
        case is UILabel:
            relookLabel(view as UILabel)
        case is UIButton:
            relookButton(view as UIButton)
        case is UINavigationBar:
            relookNavigationBar(view as UINavigationBar)
        default:
            relookView(view)
        }
    }
    
    private class func relookView(view: UIView) {
        if let style = view.style {
            // apply style if present
            if let styleClosure = VisualTheme.viewStyles[style] {
                styleClosure(view)
            }
            else {
                println("ViewStylist: Unable to find view style: \(style)")
            }
        }
    }
    
    private class func relookLabel(label: UILabel) {
        if let style = label.style {
            // apply style if present
            if let styleClosure = VisualTheme.labelStyles[style] {
                styleClosure(label)
            }
            else {
                println("ViewStylist: Unable to find label style: \(style)")
            }
        }
    }
    
    private class func relookButton(button: UIButton) {
        if let style = button.style {
            // apply style if present
            if let styleClosure = VisualTheme.buttonStyles[style] {
                styleClosure(button)
            }
            else {
                println("ViewStylist: Unable to find button style: \(style)")
            }
        }
    }
    
    private class func relookNavigationBar(navigationBar:UINavigationBar) {
        if let style = navigationBar.style {
            // apply style if present
            if let styleClosure = VisualTheme.navigationBarStyles[style] {
                styleClosure(navigationBar)
            }
            else {
                println("ViewStylist: Unable to find navigation bar style: \(style)")
            }
        }
    }
    
}