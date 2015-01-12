//
//  VisualTheme.swift
//  ledger-wallet-ios
//
//  Created by Nicolas Bigot on 12/01/2015.
//  Copyright (c) 2015 Ledger. All rights reserved.
//

import UIKit

struct VisualTheme {
    
    typealias LabelStyle = (UILabel) -> ()
    typealias ButtonStyle = (UIButton) -> ()
    typealias NavigationBarStyle = (UINavigationBar) -> ()

    //MARK: Label Styles

    static let labelStyles: [String: LabelStyle] = [
        "pageTitle": { label in
            label.attributedText = NSAttributedString(string: label.localizedValue, attributes: VisualFactory.TextAttributes.pageTitle)
        }
    ]
    
    //MARK: Button Styles
    
    static let buttonStyles: [String: ButtonStyle] = [
        "roundedGreen": { button in
            
        }
    ]
    
    //MARK: Navigation bar Styles
    
    static let navigationBarStyles: [String: NavigationBarStyle] = [
        "nightBlue": { navigationBar in
            navigationBar.translucent = false
            navigationBar.shadowImage = UIImage()
            navigationBar.barTintColor = VisualFactory.Colors.nightBlue
            navigationBar.setBackgroundImage(UIImage(), forBarMetrics: UIBarMetrics.Default)
        }
    ]
    
}
