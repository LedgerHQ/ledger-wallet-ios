//
//  VisualTheme.swift
//  ledger-wallet-ios
//
//  Created by Nicolas Bigot on 12/01/2015.
//  Copyright (c) 2015 Ledger. All rights reserved.
//

import UIKit

struct VisualTheme {
    
    typealias ViewAllure = (UIView) -> ()
    typealias LabelAllure = (Label) -> ()
    typealias ButtonAllure = (Button) -> ()
    typealias TextFieldAllure = (TextField) -> ()


    // MARK: - View allures
    
    static let viewAllures: [String: ViewAllure] = [
        "view.background": { view in
            view.backgroundColor = VisualFactory.Colors.BackgroundColor
        },
        "view.nightBlue": { view in
            view.backgroundColor = VisualFactory.Colors.NightBlue
        },
        "view.transparent": { view in
            view.backgroundColor = VisualFactory.Colors.Transparent
            view.opaque = false
        },
        "actionBar.grey": { view in
            let actionBar = view as! ActionBarView
            actionBar.backgroundColor = VisualFactory.Colors.ExtraLightGrey
            actionBar.borderColor = VisualFactory.Colors.VeryLightGrey
        },
        "tableView.transparent": { view in
            let tableView = view as! TableView
            tableView.backgroundColor = VisualFactory.Colors.Transparent
            tableView.separatorColor = VisualFactory.Colors.LightGrey
            tableView.separatorInset = UIEdgeInsetsMake(0, VisualFactory.Metrics.Padding.Small, 0, VisualFactory.Metrics.Padding.Small)
        },
        "tableViewCell.transparent": { view in
            let tableViewCell = view as! TableViewCell
            tableViewCell.contentView.backgroundColor = VisualFactory.Colors.Transparent
            tableViewCell.backgroundColor = VisualFactory.Colors.Transparent
        },
        "navigationBar.nightBlue": { view in
            let navigationBar = view as! NavigationBar
            navigationBar.translucent = false
            navigationBar.shadowImage = UIImage()
            navigationBar.barTintColor = VisualFactory.Colors.NightBlue
            navigationBar.setBackgroundImage(UIImage(), forBarMetrics: UIBarMetrics.Default)
        },
        "pinCodeView.grey": { view in
            let pinCodeView = view as! PinCodeView
            pinCodeView.boxSize = CGSizeMake(55.0, 75.0)
            pinCodeView.highlightedColor = VisualFactory.Colors.InvalidRed
            pinCodeView.filledColor = VisualFactory.Colors.DarkGrey
            pinCodeView.boxSpacing = VisualFactory.Metrics.Padding.VerySmall
            pinCodeView.boxColor = VisualFactory.Colors.White
            pinCodeView.borderWidth = 1.0
            pinCodeView.dotRadius = 15.0
        },
        "loadingIndicator.grey": { view in
            let loadingIndicator = view as! LoadingIndicator
            loadingIndicator.dotsHighlightedColor = VisualFactory.Colors.DarkGreyBlue
            loadingIndicator.dotsNormalColor = VisualFactory.Colors.LightGrey
            loadingIndicator.animationDuration = VisualFactory.Durations.Animation.VeryShort
            loadingIndicator.dotsSize = 3.5
            loadingIndicator.preferredWidth = 44.0
            loadingIndicator.dotsCount = 9
        }
    ]
    
    // MARK: - Label allures
    
    static let labelAllures: [String: LabelAllure] = [
        "navigationBar.title": { label in
            label.attributedText = NSAttributedString(string: label.readableText(), attributes: VisualFactory.TextAttributes.PageTitle)
        },
        "navigationBar.largeTitle": { label in
            label.attributedText = NSAttributedString(string: label.readableText(), attributes: VisualFactory.TextAttributes.LargePageTitle)
        },
        "navigationBar.text": { label in
            label.attributedText = NSAttributedString(string: label.readableText(), attributes: VisualFactory.TextAttributes.NavigationBarText)
        },
        "medium": { label in
            label.attributedText = NSAttributedString(string: label.readableText(), attributes: VisualFactory.TextAttributes.Medium)
        },
        "medium.centered": { label in
            label.attributedText = NSAttributedString(string: label.readableText(), attributes: VisualFactory.TextAttributes.MediumCentered)
        },
        "medium.grey": { label in
            label.attributedText = NSAttributedString(string: label.readableText(), attributes: VisualFactory.TextAttributes.MediumGrey)
        },
        "medium.softGrey": { label in
            label.attributedText = NSAttributedString(string: label.readableText(), attributes: VisualFactory.TextAttributes.MediumSoftGrey)
        },
        "small": { label in
            label.attributedText = NSAttributedString(string: label.readableText(), attributes: VisualFactory.TextAttributes.Small)
        },
        "small.centered": { label in
            label.attributedText = NSAttributedString(string: label.readableText(), attributes: VisualFactory.TextAttributes.SmallCentered)
        },
        "small.grey": { label in
            label.attributedText = NSAttributedString(string: label.readableText(), attributes: VisualFactory.TextAttributes.SmallGrey)
        },
        "small.grey.centered": { label in
            label.attributedText = NSAttributedString(string: label.readableText(), attributes: VisualFactory.TextAttributes.SmallGreyCentered)
        },
        "small.softGrey": { label in
            label.attributedText = NSAttributedString(string: label.readableText(), attributes: VisualFactory.TextAttributes.SmallSoftGrey)
        },
        "small.softGrey.centered": { label in
            label.attributedText = NSAttributedString(string: label.readableText(), attributes: VisualFactory.TextAttributes.SmallSoftGreyCentered)
        },
        "largeIndication": { label in
            label.attributedText = NSAttributedString(string: label.readableText(), attributes: VisualFactory.TextAttributes.LargeIndication)
        },
        "largeIndication.grey": { label in
            label.attributedText = NSAttributedString(string: label.readableText(), attributes: VisualFactory.TextAttributes.LargeIndicationGrey)
        },
        "largeIndication.grey.centered": { label in
            label.attributedText = NSAttributedString(string: label.readableText(), attributes: VisualFactory.TextAttributes.LargeIndicationGreyCentered)
        },
        "largeTitle": { label in
            label.attributedText = NSAttributedString(string: label.readableText(), attributes: VisualFactory.TextAttributes.LargeTitle)
        },
        "hugeNumber.grey": { label in
            label.attributedText = NSAttributedString(string: label.readableText(), attributes: VisualFactory.TextAttributes.HugeNumberGrey)
        },
        "sectionTitle": { label in
            label.attributedText = NSAttributedString(string: label.readableText(), attributes: VisualFactory.TextAttributes.SectionTitle)
        },
        "huge": { label in
            label.attributedText = NSAttributedString(string: label.readableText(), attributes: VisualFactory.TextAttributes.Huge)
        },
        "huge.light": { label in
            label.attributedText = NSAttributedString(string: label.readableText(), attributes: VisualFactory.TextAttributes.HugeLight)
        }

    ]
    
    // MARK: - Button allures
    
    static let buttonAllures: [String: ButtonAllure] = [
        "navigationBar.grey": { button in
            var hightlightedStyle = VisualFactory.TextAttributes.NavigationBarText
            hightlightedStyle.updateValue((hightlightedStyle[NSForegroundColorAttributeName] as! UIColor).darkerColor(factor: VisualFactory.Factors.Darken.UltraStrong), forKey: NSForegroundColorAttributeName)
            button.setAttributedTitle(NSAttributedString(string: button.readableTitleForState(UIControlState.Normal), attributes: VisualFactory.TextAttributes.NavigationBarText), forState: UIControlState.Normal)
            button.setAttributedTitle(NSAttributedString(string: button.readableTitleForState(UIControlState.Normal), attributes: hightlightedStyle), forState: UIControlState.Highlighted)
        },
        "navigationBar.white": { button in
            var hightlightedStyle = VisualFactory.TextAttributes.NavigationBarWhiteText
            hightlightedStyle.updateValue((hightlightedStyle[NSForegroundColorAttributeName] as! UIColor).darkerColor(factor: VisualFactory.Factors.Darken.UltraStrong), forKey: NSForegroundColorAttributeName)
            button.setAttributedTitle(NSAttributedString(string: button.readableTitleForState(UIControlState.Normal), attributes: VisualFactory.TextAttributes.NavigationBarWhiteText), forState: UIControlState.Normal)
            button.setAttributedTitle(NSAttributedString(string: button.readableTitleForState(UIControlState.Normal), attributes: hightlightedStyle), forState: UIControlState.Highlighted)
        },
        "icon": { button in
            button.adjustsImageWhenHighlighted = false
        },
        "icon.grey": { button in
            VisualTheme.buttonAllures["icon"]?(button)
            button.setTintedImages(button.imageForState(UIControlState.Normal)!, tintColor: VisualFactory.Colors.LightGrey, darkenFactor: VisualFactory.Factors.Darken.VeryStrong)
        },
        "small.softGrey": { button in
            var hightlightedStyle = VisualFactory.TextAttributes.SmallSoftGrey
            hightlightedStyle.updateValue((hightlightedStyle[NSForegroundColorAttributeName] as! UIColor).darkerColor(factor: VisualFactory.Factors.Darken.ExtraStrong), forKey: NSForegroundColorAttributeName)
            button.setAttributedTitle(NSAttributedString(string: button.readableTitleForState(UIControlState.Normal), attributes: VisualFactory.TextAttributes.SmallSoftGrey), forState: UIControlState.Normal)
            button.setAttributedTitle(NSAttributedString(string: button.readableTitleForState(UIControlState.Highlighted), attributes: hightlightedStyle), forState: UIControlState.Highlighted)
        },
        "rounded": { button in
            let roundedButton = button as! RoundedButton
            roundedButton.adjustsImageWhenHighlighted = false
            roundedButton.borderRadius = VisualFactory.Metrics.BordersRadius.Medium
            roundedButton.setAttributedTitle(NSAttributedString(string: button.readableTitleForState(UIControlState.Normal), attributes: VisualFactory.TextAttributes.RoundedButtonText), forState: UIControlState.Normal)
            roundedButton.contentEdgeInsets = UIEdgeInsets(top: VisualFactory.Metrics.Padding.VerySmall, left: VisualFactory.Metrics.Padding.Small, bottom: VisualFactory.Metrics.Padding.VerySmall, right: VisualFactory.Metrics.Padding.Small)
            if (roundedButton.imageForState(UIControlState.Normal) != nil) {
                roundedButton.setImage(roundedButton.imageForState(UIControlState.Normal)!.imageWithColor(VisualFactory.Colors.White), forState: UIControlState.Normal)
                roundedButton.imageEdgeInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: VisualFactory.Metrics.Padding.VerySmall)
            }
        },
        "rounded.green": { button in
            VisualTheme.buttonAllures["rounded"]?(button)
            let roundedButton = button as! RoundedButton
            roundedButton.setFillColor(VisualFactory.Colors.ActionGreen, forState: UIControlState.Normal)
            roundedButton.setFillColor(VisualFactory.Colors.ActionGreen.darkerColor(), forState: UIControlState.Highlighted)
        },
        "rounded.grey": { button in
            VisualTheme.buttonAllures["rounded"]?(button)
            let roundedButton = button as! RoundedButton
            roundedButton.setFillColor(VisualFactory.Colors.LightGrey, forState: UIControlState.Normal)
            roundedButton.setFillColor(VisualFactory.Colors.LightGrey.darkerColor(), forState: UIControlState.Highlighted)
        },
        "rounded.red": { button in
            VisualTheme.buttonAllures["rounded"]?(button)
            let roundedButton = button as! RoundedButton
            roundedButton.setFillColor(VisualFactory.Colors.InvalidRed, forState: UIControlState.Normal)
            roundedButton.setFillColor(VisualFactory.Colors.InvalidRed.darkerColor(), forState: UIControlState.Highlighted)
        }
    ]
    
    // MARK: - TextField allures
    
    static let textFieldAllures: [String: TextFieldAllure] = [
        "huge.light": { textField in
            var placeholderAttributes = VisualFactory.TextAttributes.HugeLight
            placeholderAttributes.updateValue(VisualFactory.Colors.LightGrey, forKey: NSForegroundColorAttributeName)
            textField.attributedText = NSAttributedString(string: textField.readableText(), attributes: VisualFactory.TextAttributes.HugeLight)
            textField.attributedPlaceholder = NSAttributedString(string: textField.readablePlaceholder(), attributes: placeholderAttributes)
            textField.tintColor = VisualFactory.Colors.Black
            textField.borderStyle = UITextBorderStyle.None
            textField.adjustsFontSizeToFitWidth = false
        }
    ]
    
}
