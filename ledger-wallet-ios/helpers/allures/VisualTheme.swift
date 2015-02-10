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
            view.backgroundColor = VisualFactory.Colors.backgroundColor
        },
        "view.nightBlue": { view in
            view.backgroundColor = VisualFactory.Colors.nightBlue
        },
        "view.transparent": { view in
            view.backgroundColor = VisualFactory.Colors.transparent
            view.opaque = false
        },
        "actionBar.grey": { view in
            let actionBar = view as! ActionBarView
            actionBar.backgroundColor = VisualFactory.Colors.extraLightGrey
            actionBar.borderColor = VisualFactory.Colors.veryLightGrey
        },
        "tableView.transparent": { view in
            let tableView = view as! TableView
            tableView.backgroundColor = VisualFactory.Colors.transparent
            tableView.separatorColor = VisualFactory.Colors.lightGrey
            tableView.separatorInset = UIEdgeInsetsMake(0, VisualFactory.Metrics.Paddings.small, 0, VisualFactory.Metrics.Paddings.small)
        },
        "tableViewCell.transparent": { view in
            let tableViewCell = view as! TableViewCell
            tableViewCell.contentView.backgroundColor = VisualFactory.Colors.transparent
            tableViewCell.backgroundColor = VisualFactory.Colors.transparent
        },
        "navigationBar.nightBlue": { view in
            let navigationBar = view as! NavigationBar
            navigationBar.translucent = false
            navigationBar.shadowImage = UIImage()
            navigationBar.barTintColor = VisualFactory.Colors.nightBlue
            navigationBar.setBackgroundImage(UIImage(), forBarMetrics: UIBarMetrics.Default)
        },
        "pinCodeView.grey": { view in
            let pinCodeView = view as! PinCodeView
            pinCodeView.boxSize = CGSizeMake(55.0, 75.0)
            pinCodeView.highlightedColor = VisualFactory.Colors.invalidRed
            pinCodeView.filledColor = VisualFactory.Colors.darkGrey
            pinCodeView.boxSpacing = VisualFactory.Metrics.Paddings.verySmall
            pinCodeView.boxColor = VisualFactory.Colors.white
            pinCodeView.borderWidth = 1.0
            pinCodeView.dotRadius = 15.0
        },
        "loadingIndicator.grey": { view in
            let loadingIndicator = view as! LoadingIndicator
            loadingIndicator.dotsHighlightedColor = VisualFactory.Colors.darkGreyBlue
            loadingIndicator.dotsNormalColor = VisualFactory.Colors.lightGrey
            loadingIndicator.animationDuration = VisualFactory.Metrics.Durations.Animations.veryShort
            loadingIndicator.dotsSize = 3.5
            loadingIndicator.preferredWidth = 44.0
            loadingIndicator.dotsCount = 9
        }
    ]
    
    // MARK: - Label allures
    
    static let labelAllures: [String: LabelAllure] = [
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
        "medium.centered": { label in
            label.attributedText = NSAttributedString(string: label.readableText(), attributes: VisualFactory.TextAttributes.mediumCentered)
        },
        "medium.grey": { label in
            label.attributedText = NSAttributedString(string: label.readableText(), attributes: VisualFactory.TextAttributes.mediumGrey)
        },
        "medium.softGrey": { label in
            label.attributedText = NSAttributedString(string: label.readableText(), attributes: VisualFactory.TextAttributes.mediumSoftGrey)
        },
        "small": { label in
            label.attributedText = NSAttributedString(string: label.readableText(), attributes: VisualFactory.TextAttributes.small)
        },
        "small.centered": { label in
            label.attributedText = NSAttributedString(string: label.readableText(), attributes: VisualFactory.TextAttributes.smallCentered)
        },
        "small.grey": { label in
            label.attributedText = NSAttributedString(string: label.readableText(), attributes: VisualFactory.TextAttributes.smallGrey)
        },
        "small.grey.centered": { label in
            label.attributedText = NSAttributedString(string: label.readableText(), attributes: VisualFactory.TextAttributes.smallGreyCentered)
        },
        "small.softGrey": { label in
            label.attributedText = NSAttributedString(string: label.readableText(), attributes: VisualFactory.TextAttributes.smallSoftGrey)
        },
        "small.softGrey.centered": { label in
            label.attributedText = NSAttributedString(string: label.readableText(), attributes: VisualFactory.TextAttributes.smallSoftGreyCentered)
        },
        "largeIndication": { label in
            label.attributedText = NSAttributedString(string: label.readableText(), attributes: VisualFactory.TextAttributes.largeIndication)
        },
        "largeIndication.grey": { label in
            label.attributedText = NSAttributedString(string: label.readableText(), attributes: VisualFactory.TextAttributes.largeIndicationGrey)
        },
        "largeIndication.grey.centered": { label in
            label.attributedText = NSAttributedString(string: label.readableText(), attributes: VisualFactory.TextAttributes.largeIndicationGreyCentered)
        },
        "largeTitle": { label in
            label.attributedText = NSAttributedString(string: label.readableText(), attributes: VisualFactory.TextAttributes.largeTitle)
        },
        "hugeNumber.grey": { label in
            label.attributedText = NSAttributedString(string: label.readableText(), attributes: VisualFactory.TextAttributes.hugeNumberGrey)
        },
        "sectionTitle": { label in
            label.attributedText = NSAttributedString(string: label.readableText(), attributes: VisualFactory.TextAttributes.sectionTitle)
        },
        "huge": { label in
            label.attributedText = NSAttributedString(string: label.readableText(), attributes: VisualFactory.TextAttributes.huge)
        }

    ]
    
    // MARK: - Button allures
    
    static let buttonAllures: [String: ButtonAllure] = [
        "navigationBar.grey": { button in
            var hightlightedStyle = VisualFactory.TextAttributes.navigationBarText
            hightlightedStyle.updateValue((hightlightedStyle[NSForegroundColorAttributeName] as! UIColor).darkerColor(factor: VisualFactory.Metrics.Factors.Darken.ultraStrong), forKey: NSForegroundColorAttributeName)
            button.setAttributedTitle(NSAttributedString(string: button.readableTitleForState(UIControlState.Normal), attributes: VisualFactory.TextAttributes.navigationBarText), forState: UIControlState.Normal)
            button.setAttributedTitle(NSAttributedString(string: button.readableTitleForState(UIControlState.Normal), attributes: hightlightedStyle), forState: UIControlState.Highlighted)
        },
        "navigationBar.white": { button in
            var hightlightedStyle = VisualFactory.TextAttributes.navigationBarWhiteText
            hightlightedStyle.updateValue((hightlightedStyle[NSForegroundColorAttributeName] as! UIColor).darkerColor(factor: VisualFactory.Metrics.Factors.Darken.ultraStrong), forKey: NSForegroundColorAttributeName)
            button.setAttributedTitle(NSAttributedString(string: button.readableTitleForState(UIControlState.Normal), attributes: VisualFactory.TextAttributes.navigationBarWhiteText), forState: UIControlState.Normal)
            button.setAttributedTitle(NSAttributedString(string: button.readableTitleForState(UIControlState.Normal), attributes: hightlightedStyle), forState: UIControlState.Highlighted)
        },
        "icon": { button in
            button.adjustsImageWhenHighlighted = false
        },
        "icon.grey": { button in
            VisualTheme.buttonAllures["icon"]?(button)
            button.setTintedImages(button.imageForState(UIControlState.Normal)!, tintColor: VisualFactory.Colors.lightGrey, darkenFactor: VisualFactory.Metrics.Factors.Darken.veryStrong)
        },
        "small.softGrey": { button in
            var hightlightedStyle = VisualFactory.TextAttributes.smallSoftGrey
            hightlightedStyle.updateValue((hightlightedStyle[NSForegroundColorAttributeName] as! UIColor).darkerColor(factor: VisualFactory.Metrics.Factors.Darken.extraStrong), forKey: NSForegroundColorAttributeName)
            button.setAttributedTitle(NSAttributedString(string: button.readableTitleForState(UIControlState.Normal), attributes: VisualFactory.TextAttributes.smallSoftGrey), forState: UIControlState.Normal)
            button.setAttributedTitle(NSAttributedString(string: button.readableTitleForState(UIControlState.Highlighted), attributes: hightlightedStyle), forState: UIControlState.Highlighted)
        },
        "rounded": { button in
            let roundedButton = button as! RoundedButton
            roundedButton.adjustsImageWhenHighlighted = false
            roundedButton.borderRadius = VisualFactory.Metrics.BordersRadii.medium
            roundedButton.setAttributedTitle(NSAttributedString(string: button.readableTitleForState(UIControlState.Normal), attributes: VisualFactory.TextAttributes.roundedButtonText), forState: UIControlState.Normal)
            roundedButton.contentEdgeInsets = UIEdgeInsets(top: VisualFactory.Metrics.Paddings.verySmall, left: VisualFactory.Metrics.Paddings.small, bottom: VisualFactory.Metrics.Paddings.verySmall, right: VisualFactory.Metrics.Paddings.small)
            if (roundedButton.imageForState(UIControlState.Normal) != nil) {
                roundedButton.setImage(roundedButton.imageForState(UIControlState.Normal)!.imageWithColor(VisualFactory.Colors.white), forState: UIControlState.Normal)
                roundedButton.imageEdgeInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: VisualFactory.Metrics.Paddings.verySmall)
            }
        },
        "rounded.green": { button in
            VisualTheme.buttonAllures["rounded"]?(button)
            let roundedButton = button as! RoundedButton
            roundedButton.setFillColor(VisualFactory.Colors.actionGreen, forState: UIControlState.Normal)
            roundedButton.setFillColor(VisualFactory.Colors.actionGreen.darkerColor(), forState: UIControlState.Highlighted)
        },
        "rounded.grey": { button in
            VisualTheme.buttonAllures["rounded"]?(button)
            let roundedButton = button as! RoundedButton
            roundedButton.setFillColor(VisualFactory.Colors.lightGrey, forState: UIControlState.Normal)
            roundedButton.setFillColor(VisualFactory.Colors.lightGrey.darkerColor(), forState: UIControlState.Highlighted)
        },
        "rounded.red": { button in
            VisualTheme.buttonAllures["rounded"]?(button)
            let roundedButton = button as! RoundedButton
            roundedButton.setFillColor(VisualFactory.Colors.invalidRed, forState: UIControlState.Normal)
            roundedButton.setFillColor(VisualFactory.Colors.invalidRed.darkerColor(), forState: UIControlState.Highlighted)
        }
    ]
    
    // MARK: - TextField allures
    
    static let textFieldAllures: [String: TextFieldAllure] = [
        "hugeName": { textField in
            var placeholderAttributes = VisualFactory.TextAttributes.huge
            placeholderAttributes.updateValue(VisualFactory.Colors.lightGrey, forKey: NSForegroundColorAttributeName)
            textField.attributedText = NSAttributedString(string: textField.readableText(), attributes: VisualFactory.TextAttributes.huge)
            textField.attributedPlaceholder = NSAttributedString(string: textField.readablePlaceholder(), attributes: placeholderAttributes)
            textField.tintColor = VisualFactory.Colors.black
            textField.borderStyle = UITextBorderStyle.None
            textField.adjustsFontSizeToFitWidth = false
        }
    ]
    
}
