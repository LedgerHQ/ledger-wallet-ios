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
        "view.background": { view in
            view.backgroundColor = VisualFactory.Colors.backgroundColor
        },
        "view.nightBlue": { view in
            view.backgroundColor = VisualFactory.Colors.nightBlue
        },
        "actionBar.grey": { view in
            let actionBar = view as ActionBarView
            actionBar.backgroundColor = VisualFactory.Colors.extraLightGrey
            actionBar.borderColor = VisualFactory.Colors.veryLightGrey
        }
    ]
    
    //MARK: Label Styles
    
    static let labelStyles: [String: LabelStyle] = [
        "navigationBar.title": { label in
            label.attributedText = NSAttributedString(string: label.readableText(), attributes: VisualFactory.TextAttributes.pageTitle)
        },
        "navigationBar.largeTitle": { label in
            label.attributedText = NSAttributedString(string: label.readableText(), attributes: VisualFactory.TextAttributes.largePageTitle)
        },
        "navigationBar.text": { label in
            label.attributedText = NSAttributedString(string: label.readableText(), attributes: VisualFactory.TextAttributes.navigationBarText)
        },
        "medium": { label in
            label.attributedText = NSAttributedString(string: label.readableText(), attributes: VisualFactory.TextAttributes.medium)
        },
        "medium.grey": { label in
            label.attributedText = NSAttributedString(string: label.readableText(), attributes: VisualFactory.TextAttributes.mediumGrey)
        }
    ]
    
    //MARK: Button Styles
    
    static let buttonStyles: [String: ButtonStyle] = [
        "navigationBar.button": { button in
            var hightlightedStyle = VisualFactory.TextAttributes.navigationBarText
            hightlightedStyle.updateValue((hightlightedStyle[NSForegroundColorAttributeName] as UIColor).darkerColor(), forKey: NSForegroundColorAttributeName)
            button.setAttributedTitle(NSAttributedString(string: button.readableTitleForState(UIControlState.Normal), attributes: VisualFactory.TextAttributes.navigationBarText), forState: UIControlState.Normal)
            button.setAttributedTitle(NSAttributedString(string: button.readableTitleForState(UIControlState.Normal), attributes: hightlightedStyle), forState: UIControlState.Highlighted)
        },
        "rounded": { button in
            let roundedButton = button as RoundedButton
            roundedButton.borderRadius = VisualFactory.Metrics.defaultBorderRadius
            roundedButton.tintColor = VisualFactory.Colors.white
            roundedButton.adjustsImageWhenHighlighted = false
            roundedButton.imageEdgeInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: VisualFactory.Metrics.verySmallPadding)
            roundedButton.setAttributedTitle(NSAttributedString(string: button.readableTitleForState(UIControlState.Normal), attributes: VisualFactory.TextAttributes.roundedButtonText), forState: UIControlState.Normal)
            roundedButton.contentEdgeInsets = UIEdgeInsets(top: VisualFactory.Metrics.verySmallPadding, left: VisualFactory.Metrics.smallPadding, bottom: VisualFactory.Metrics.verySmallPadding, right: VisualFactory.Metrics.smallPadding)
        },
        "rounded.green": { button in
            VisualTheme.buttonStyles["rounded"]?(button)
            let roundedButton = button as RoundedButton
            roundedButton.setFillColor(VisualFactory.Colors.actionGreen, forState: UIControlState.Normal)
            roundedButton.setFillColor(VisualFactory.Colors.actionGreen.darkerColor(factor: VisualFactory.Metrics.strongDarkenFactor), forState: UIControlState.Highlighted)
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
