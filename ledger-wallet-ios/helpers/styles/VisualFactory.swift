//
//  VisualFactory.swift
//  ledger-wallet-ios
//
//  Created by Nicolas Bigot on 07/01/2015.
//  Copyright (c) 2015 Ledger. All rights reserved.
//

import UIKit

struct VisualFactory {
    
    typealias TextAttribute = [NSObject: AnyObject]
    
    struct TextAttributes {
    
        static let pageTitle = [
            NSForegroundColorAttributeName: Colors.white,
            NSKernAttributeName: -0.5,
            NSFontAttributeName: Fonts.semiboldFontWithSize(15)
        ]
        
        static let largePageTitle = [
            NSForegroundColorAttributeName: Colors.white,
            NSKernAttributeName: -0.5,
            NSFontAttributeName: Fonts.regularFontWithSize(20)
        ]
        
        static let regularText = [
            NSForegroundColorAttributeName: Colors.black,
            NSKernAttributeName: -0.5,
            NSFontAttributeName: Fonts.regularFontWithSize(14)
        ]
        
        static let regularGreyText: TextAttribute = TextAttributes.extend(regularText, withAttributes: [
            NSForegroundColorAttributeName: Colors.darkGrey
        ])
        
        static let navigationBarText = [
            NSForegroundColorAttributeName: Colors.lightGrey,
            NSKernAttributeName: -0.5,
            NSFontAttributeName: Fonts.regularFontWithSize(12)
        ]
        
        private static func extend(textAttribute: TextAttribute, withAttributes attributes: TextAttribute) -> TextAttribute {
            var newAttributes = textAttribute
            newAttributes.merge(attributes)
            return newAttributes
        }
        
    }
    
    struct Colors {
        
        static let black = UIColor(hex: 0x000000)
        static let white = UIColor(hex: 0xffffff)
        static let backgroundColor = UIColor(hex: 0xf9f9f9)
        static let nightBlue = UIColor(hex: 0x1d2028)
        static let lightGreyBlue = UIColor(hex: 0xcccff0)
        static let darkGreyBlue = UIColor(hex: 0x333745)
        static let greyBlue = UIColor(hex: 0x71737d)
        static let invalidRed = UIColor(hex: 0xea2e49)
        static let validGreen = UIColor(hex: 0x3fb34f)
        static let actionGreen = UIColor(hex: 0x41ccb4)
        static let actionPurple = UIColor(hex: 0x596799)
        static let extraDarkGrey = UIColor(hex: 0x333333)
        static let darkGrey = UIColor(hex: 0x666666)
        static let softGrey = UIColor(hex: 0x999999)
        static let lightGrey = UIColor(hex: 0xcccccc)
        static let veryLightGrey = UIColor(hex: 0xeeeeee)
        static let extraLightGrey = UIColor(hex: 0xf4f4f4)
        
    }
    
    enum Fonts {
        
        private enum Names: String {
            case Light = "OpenSans-Light"
            case Regular = "OpenSans"
            case Semibold = "OpenSans-Semibold"
            case Bold = "OpenSans-Bold"
            case Extrabold = "OpenSans-Extrabold"
        }
        
        private static func fontWithName(name: String, size: CGFloat) -> UIFont {
            if let font = UIFont(name: name, size: size) {
                return font
            }
            return UIFont.systemFontOfSize(UIFont.systemFontSize())
        }
        
        static func lightFontWithSize(size: CGFloat) -> UIFont {
            return fontWithName(Names.Light.rawValue, size: size)
        }
        
        static func regularFontWithSize(size: CGFloat) -> UIFont {
            return fontWithName(Names.Regular.rawValue, size: size)
        }
        
        static func semiboldFontWithSize(size: CGFloat) -> UIFont {
            return fontWithName(Names.Semibold.rawValue, size: size)
        }
        
        static func boldFontWithSize(size: CGFloat) -> UIFont {
            return fontWithName(Names.Bold.rawValue, size: size)
        }
        
        static func extraboldFontWithSize(size: CGFloat) -> UIFont {
            return fontWithName(Names.Extrabold.rawValue, size: size)
        }
    }
    
    struct Metrics {
        
        static let defaultNavigationBarHeight = 60
        
    }

}