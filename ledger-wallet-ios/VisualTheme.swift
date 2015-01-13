//
//  VisualTheme.swift
//  ledger-wallet-ios
//
//  Created by Nicolas Bigot on 12/01/2015.
//  Copyright (c) 2015 Ledger. All rights reserved.
//

import UIKit

struct VisualTheme {
    
    typealias ViewStyle = (UIView) -> ()
    typealias LabelStyle = (UILabel) -> ()
    typealias ButtonStyle = (UIButton) -> ()
    typealias NavigationBarStyle = (UINavigationBar) -> ()

    //MARK: View Styles
    
    static let viewStyles: [String: ViewStyle] = [
        "background": { view in
            view.backgroundColor = VisualFactory.Colors.backgroundColor
        }
    ]
    
    //MARK: Label Styles
    
    static let labelStyles: [String: LabelStyle] = [
        "pageTitle": { label in
            label.attributedText = NSAttributedString(string: label.localizedValue, attributes: VisualFactory.TextAttributes.pageTitle)
        },
        "largePageTitle": { label in
            label.attributedText = NSAttributedString(string: label.localizedValue, attributes: VisualFactory.TextAttributes.largePageTitle)
        },
        "regularText": { label in
            label.attributedText = NSAttributedString(string: label.localizedValue, attributes: VisualFactory.TextAttributes.regularText)
        },
        "regularGreyText": { label in
            label.attributedText = NSAttributedString(string: label.localizedValue, attributes: VisualFactory.TextAttributes.regularGreyText)
        },
        "navigationBarText": { label in
            label.attributedText = NSAttributedString(string: label.localizedValue, attributes: VisualFactory.TextAttributes.navigationBarText)
        }
    ]
    
    //MARK: Button Styles
    
    static let buttonStyles: [String: ButtonStyle] = [
        "navigationBarButton": { button in
            var hightlightedStyle = VisualFactory.TextAttributes.navigationBarText
            hightlightedStyle.updateValue((hightlightedStyle[NSForegroundColorAttributeName] as UIColor).darkerColor(), forKey: NSForegroundColorAttributeName)
            button.setAttributedTitle(NSAttributedString(string: button.localizedValue, attributes: VisualFactory.TextAttributes.navigationBarText), forState: UIControlState.Normal)
            button.setAttributedTitle(NSAttributedString(string: button.localizedValue, attributes: hightlightedStyle), forState: UIControlState.Highlighted)
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
