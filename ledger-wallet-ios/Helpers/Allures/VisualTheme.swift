//
//  VisualTheme.swift
//  ledger-wallet-ios
//
//  Created by Nicolas Bigot on 12/01/2015.
//  Copyright (c) 2015 Ledger. All rights reserved.
//

import UIKit

struct VisualTheme {
    
    static let allureBlocks: [String: ViewStylist.AllureBlock] = [
        
        // MARK: - View allures
        
        "view.background": ViewStylist.wrapAllureBlock({ (view: UIView) in
            view.backgroundColor = VisualFactory.Colors.BackgroundColor
        }),
        "view.nightBlue": ViewStylist.wrapAllureBlock({ (view: UIView) in
            view.backgroundColor = VisualFactory.Colors.NightBlue
        }),
        "view.transparent": ViewStylist.wrapAllureBlock({ (view: UIView) in
            view.backgroundColor = VisualFactory.Colors.Transparent
            view.opaque = false
        }),
        "actionBarView.grey": ViewStylist.wrapAllureBlock({ (actionBarView: ActionBarView) in
            actionBarView.backgroundColor = VisualFactory.Colors.ExtraLightGrey
            actionBarView.borderColor = VisualFactory.Colors.VeryLightGrey
        }),
        "tableView.transparent": ViewStylist.wrapAllureBlock({ (tableView: TableView) in
            tableView.backgroundColor = VisualFactory.Colors.Transparent
            tableView.separatorColor = VisualFactory.Colors.LightGrey
            tableView.separatorInset = UIEdgeInsetsMake(0, VisualFactory.Metrics.Padding.Small, 0, VisualFactory.Metrics.Padding.Small)
        }),
        "tableViewCell.transparent": ViewStylist.wrapAllureBlock({ (tableViewCell: TableViewCell) in
            tableViewCell.contentView.backgroundColor = VisualFactory.Colors.Transparent
            tableViewCell.backgroundColor = VisualFactory.Colors.Transparent
        }),
        "navigationBar.nightBlue": ViewStylist.wrapAllureBlock({ (navigationBar: NavigationBar) in
            navigationBar.translucent = false
            navigationBar.shadowImage = UIImage()
            navigationBar.barTintColor = VisualFactory.Colors.NightBlue
            navigationBar.setBackgroundImage(UIImage(), forBarMetrics: UIBarMetrics.Default)
        }),
        "pinCodeView.grey": ViewStylist.wrapAllureBlock({ (pinCodeView: PinCodeView) in
            pinCodeView.boxSize = CGSizeMake(55.0, 75.0)
            pinCodeView.highlightedColor = VisualFactory.Colors.InvalidRed
            pinCodeView.filledColor = VisualFactory.Colors.DarkGrey
            pinCodeView.boxSpacing = VisualFactory.Metrics.Padding.VerySmall
            pinCodeView.boxColor = VisualFactory.Colors.White
            pinCodeView.borderWidth = 1.0
            pinCodeView.dotRadius = 15.0
        }),
        "loadingIndicator.grey": ViewStylist.wrapAllureBlock({ (loadingIndicator: LoadingIndicator) in
            loadingIndicator.dotsHighlightedColor = VisualFactory.Colors.DarkGreyBlue
            loadingIndicator.dotsNormalColor = VisualFactory.Colors.LightGrey
            loadingIndicator.animationDuration = VisualFactory.Durations.Animation.VeryShort
            loadingIndicator.dotsSize = 3.5
            loadingIndicator.preferredWidth = 44.0
            loadingIndicator.dotsCount = 9
        }),
        
        // MARK: - Label allures
        
        "label.navigationBar.title": ViewStylist.wrapAllureBlock({ (label: UILabel) in
            label.attributedText = NSAttributedString(string: label.readableText(), attributes: VisualFactory.TextAttributes.PageTitle)
        }),
        "label.navigationBar.largeTitle": ViewStylist.wrapAllureBlock({ (label: UILabel) in
            label.attributedText = NSAttributedString(string: label.readableText(), attributes: VisualFactory.TextAttributes.LargePageTitle)
        }),
        "label.navigationBar.text": ViewStylist.wrapAllureBlock({ (label: UILabel) in
            label.attributedText = NSAttributedString(string: label.readableText(), attributes: VisualFactory.TextAttributes.NavigationBarText)
        }),
        "label.medium": ViewStylist.wrapAllureBlock({ (label: UILabel) in
            label.attributedText = NSAttributedString(string: label.readableText(), attributes: VisualFactory.TextAttributes.Medium)
        }),
        "label.medium.centered": ViewStylist.wrapAllureBlock({ (label: UILabel) in
            label.attributedText = NSAttributedString(string: label.readableText(), attributes: VisualFactory.TextAttributes.MediumCentered)
        }),
        "label.medium.grey": ViewStylist.wrapAllureBlock({ (label: UILabel) in
            label.attributedText = NSAttributedString(string: label.readableText(), attributes: VisualFactory.TextAttributes.MediumGrey)
        }),
        "label.medium.softGrey": ViewStylist.wrapAllureBlock({ (label: UILabel) in
            label.attributedText = NSAttributedString(string: label.readableText(), attributes: VisualFactory.TextAttributes.MediumSoftGrey)
        }),
        "label.small": ViewStylist.wrapAllureBlock({ (label: UILabel) in
            label.attributedText = NSAttributedString(string: label.readableText(), attributes: VisualFactory.TextAttributes.Small)
        }),
        "label.small.centered": ViewStylist.wrapAllureBlock({ (label: UILabel) in
            label.attributedText = NSAttributedString(string: label.readableText(), attributes: VisualFactory.TextAttributes.SmallCentered)
        }),
        "label.small.grey": ViewStylist.wrapAllureBlock({ (label: UILabel) in
            label.attributedText = NSAttributedString(string: label.readableText(), attributes: VisualFactory.TextAttributes.SmallGrey)
        }),
        "label.small.grey.centered": ViewStylist.wrapAllureBlock({ (label: UILabel) in
            label.attributedText = NSAttributedString(string: label.readableText(), attributes: VisualFactory.TextAttributes.SmallGreyCentered)
        }),
        "label.small.softGrey": ViewStylist.wrapAllureBlock({ (label: UILabel) in
            label.attributedText = NSAttributedString(string: label.readableText(), attributes: VisualFactory.TextAttributes.SmallSoftGrey)
        }),
        "label.small.softGrey.centered": ViewStylist.wrapAllureBlock({ (label: UILabel) in
            label.attributedText = NSAttributedString(string: label.readableText(), attributes: VisualFactory.TextAttributes.SmallSoftGreyCentered)
        }),
        "label.largeIndication": ViewStylist.wrapAllureBlock({ (label: UILabel) in
            label.attributedText = NSAttributedString(string: label.readableText(), attributes: VisualFactory.TextAttributes.LargeIndication)
        }),
        "label.largeIndication.grey": ViewStylist.wrapAllureBlock({ (label: UILabel) in
            label.attributedText = NSAttributedString(string: label.readableText(), attributes: VisualFactory.TextAttributes.LargeIndicationGrey)
        }),
        "label.largeIndication.grey.centered": ViewStylist.wrapAllureBlock({ (label: UILabel) in
            label.attributedText = NSAttributedString(string: label.readableText(), attributes: VisualFactory.TextAttributes.LargeIndicationGreyCentered)
        }),
        "label.largeTitle": ViewStylist.wrapAllureBlock({ (label: UILabel) in
            label.attributedText = NSAttributedString(string: label.readableText(), attributes: VisualFactory.TextAttributes.LargeTitle)
        }),
        "label.hugeNumber.grey": ViewStylist.wrapAllureBlock({ (label: UILabel) in
            label.attributedText = NSAttributedString(string: label.readableText(), attributes: VisualFactory.TextAttributes.HugeNumberGrey)
        }),
        "label.sectionTitle": ViewStylist.wrapAllureBlock({ (label: UILabel) in
            label.attributedText = NSAttributedString(string: label.readableText(), attributes: VisualFactory.TextAttributes.SectionTitle)
        }),
        "label.huge": ViewStylist.wrapAllureBlock({ (label: UILabel) in
            label.attributedText = NSAttributedString(string: label.readableText(), attributes: VisualFactory.TextAttributes.Huge)
        }),
        "label.huge.light": ViewStylist.wrapAllureBlock({ (label: UILabel) in
            label.attributedText = NSAttributedString(string: label.readableText(), attributes: VisualFactory.TextAttributes.HugeLight)
        }),

        // MARK: - Button allures
    
        "button.navigationBar.grey": ViewStylist.wrapAllureBlock({ (button: UIButton) in
            var hightlightedStyle = VisualFactory.TextAttributes.NavigationBarText
            hightlightedStyle.updateValue((hightlightedStyle[NSForegroundColorAttributeName] as! UIColor).darkerColor(factor: VisualFactory.Factors.Darken.UltraStrong), forKey: NSForegroundColorAttributeName)
            button.setAttributedTitle(NSAttributedString(string: button.readableTitleForState(UIControlState.Normal), attributes: VisualFactory.TextAttributes.NavigationBarText), forState: UIControlState.Normal)
            button.setAttributedTitle(NSAttributedString(string: button.readableTitleForState(UIControlState.Normal), attributes: hightlightedStyle), forState: UIControlState.Highlighted)
        }),
        "button.navigationBar.white": ViewStylist.wrapAllureBlock({ (button: UIButton) in
            var hightlightedStyle = VisualFactory.TextAttributes.NavigationBarWhiteText
            hightlightedStyle.updateValue((hightlightedStyle[NSForegroundColorAttributeName] as! UIColor).darkerColor(factor: VisualFactory.Factors.Darken.UltraStrong), forKey: NSForegroundColorAttributeName)
            button.setAttributedTitle(NSAttributedString(string: button.readableTitleForState(UIControlState.Normal), attributes: VisualFactory.TextAttributes.NavigationBarWhiteText), forState: UIControlState.Normal)
            button.setAttributedTitle(NSAttributedString(string: button.readableTitleForState(UIControlState.Normal), attributes: hightlightedStyle), forState: UIControlState.Highlighted)
        }),
        "button.icon": ViewStylist.wrapAllureBlock({ (button: UIButton) in
            button.adjustsImageWhenHighlighted = false
        }),
        "button.icon.grey": ViewStylist.wrapAllureBlock({ (button: Button) in
            VisualTheme.allureBlocks["button.icon"]?(button)
            button.setTintedImages(button.imageForState(UIControlState.Normal)!, tintColor: VisualFactory.Colors.LightGrey, darkenFactor: VisualFactory.Factors.Darken.VeryStrong)
        }),
        "button.small.softGrey": ViewStylist.wrapAllureBlock({ (button: UIButton) in
            var hightlightedStyle = VisualFactory.TextAttributes.SmallSoftGrey
            hightlightedStyle.updateValue((hightlightedStyle[NSForegroundColorAttributeName] as! UIColor).darkerColor(factor: VisualFactory.Factors.Darken.ExtraStrong), forKey: NSForegroundColorAttributeName)
            button.setAttributedTitle(NSAttributedString(string: button.readableTitleForState(UIControlState.Normal), attributes: VisualFactory.TextAttributes.SmallSoftGrey), forState: UIControlState.Normal)
            button.setAttributedTitle(NSAttributedString(string: button.readableTitleForState(UIControlState.Highlighted), attributes: hightlightedStyle), forState: UIControlState.Highlighted)
        }),
        "roundedButton": ViewStylist.wrapAllureBlock({ (roundedButton: RoundedButton) in
            roundedButton.adjustsImageWhenHighlighted = false
            roundedButton.borderRadius = VisualFactory.Metrics.BordersRadius.Medium
            roundedButton.setAttributedTitle(NSAttributedString(string: roundedButton.readableTitleForState(UIControlState.Normal), attributes: VisualFactory.TextAttributes.RoundedButtonText), forState: UIControlState.Normal)
            roundedButton.contentEdgeInsets = UIEdgeInsets(top: VisualFactory.Metrics.Padding.VerySmall, left: VisualFactory.Metrics.Padding.Small, bottom: VisualFactory.Metrics.Padding.VerySmall, right: VisualFactory.Metrics.Padding.Small)
            if (roundedButton.imageForState(UIControlState.Normal) != nil) {
                roundedButton.setImage(roundedButton.imageForState(UIControlState.Normal)!.imageWithColor(VisualFactory.Colors.White), forState: UIControlState.Normal)
                roundedButton.imageEdgeInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: VisualFactory.Metrics.Padding.VerySmall)
            }
        }),
        "roundedButton.green": ViewStylist.wrapAllureBlock({ (roundedButton: RoundedButton) in
            VisualTheme.allureBlocks["roundedButton"]?(roundedButton)
            roundedButton.setFillColor(VisualFactory.Colors.ActionGreen, forState: UIControlState.Normal)
            roundedButton.setFillColor(VisualFactory.Colors.ActionGreen.darkerColor(), forState: UIControlState.Highlighted)
        }),
        "roundedButton.grey": ViewStylist.wrapAllureBlock({ (roundedButton: RoundedButton) in
            VisualTheme.allureBlocks["roundedButton"]?(roundedButton)
            roundedButton.setFillColor(VisualFactory.Colors.LightGrey, forState: UIControlState.Normal)
            roundedButton.setFillColor(VisualFactory.Colors.LightGrey.darkerColor(), forState: UIControlState.Highlighted)
        }),
        "roundedButton.red": ViewStylist.wrapAllureBlock({ (roundedButton: RoundedButton) in
            VisualTheme.allureBlocks["roundedButton"]?(roundedButton)
            roundedButton.setFillColor(VisualFactory.Colors.InvalidRed, forState: UIControlState.Normal)
            roundedButton.setFillColor(VisualFactory.Colors.InvalidRed.darkerColor(), forState: UIControlState.Highlighted)
        }),

        // MARK: - TextField allures
    
        "textField.huge.light": ViewStylist.wrapAllureBlock({ (textField: UITextField) in
            var placeholderAttributes = VisualFactory.TextAttributes.HugeLight
            placeholderAttributes.updateValue(VisualFactory.Colors.LightGrey, forKey: NSForegroundColorAttributeName)
            textField.attributedText = NSAttributedString(string: textField.readableText(), attributes: VisualFactory.TextAttributes.HugeLight)
            textField.attributedPlaceholder = NSAttributedString(string: textField.readablePlaceholder(), attributes: placeholderAttributes)
            textField.tintColor = VisualFactory.Colors.Black
            textField.borderStyle = UITextBorderStyle.None
            textField.adjustsFontSizeToFitWidth = false
        })
    ]
    
}
