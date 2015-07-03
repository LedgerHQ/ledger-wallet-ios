//
//  VisualFactory.swift
//  ledger-wallet-ios
//
//  Created by Nicolas Bigot on 07/01/2015.
//  Copyright (c) 2015 Ledger. All rights reserved.
//

import UIKit

final class VisualFactory {
    
    typealias TextAttribute = [NSObject: AnyObject]
    
    struct TextAttributes {
    
        static let PageTitle = [
            NSForegroundColorAttributeName: Colors.White,
            NSKernAttributeName: -Fonts.Kerning.Small,
            NSFontAttributeName: Fonts.semiboldFontWithSize(Fonts.Size.AlmostLarge)
        ]
        
        static let LargePageTitle = [
            NSForegroundColorAttributeName: Colors.White,
            NSKernAttributeName: -Fonts.Kerning.Large,
            NSFontAttributeName: Fonts.regularFontWithSize(Fonts.Size.AlmostUltraLarge)
        ]
        
        static let NavigationBarText = [
            NSForegroundColorAttributeName: Colors.LightGrey,
            NSKernAttributeName: -Fonts.Kerning.VerySmall,
            NSFontAttributeName: Fonts.regularFontWithSize(Fonts.Size.Small)
        ]
        
        static let NavigationBarWhiteText = [
            NSForegroundColorAttributeName: Colors.White,
            NSKernAttributeName: -Fonts.Kerning.VerySmall,
            NSFontAttributeName: Fonts.semiboldFontWithSize(Fonts.Size.Small)
        ]
        
        static let Medium = [
            NSForegroundColorAttributeName: Colors.Black,
            NSKernAttributeName: -Fonts.Kerning.VerySmall,
            NSFontAttributeName: Fonts.regularFontWithSize(Fonts.Size.Medium),
            NSParagraphStyleAttributeName: {
                let paragraph = NSMutableParagraphStyle()
                paragraph.lineSpacing = Metrics.LineSpacing.Small
                return paragraph
            }()
        ]
        
        static let MediumCentered: TextAttribute = TextAttributes.extend(Medium, withAttributes: [
            NSParagraphStyleAttributeName: {
                let paragraph = (Medium[NSParagraphStyleAttributeName] as! NSParagraphStyle).mutableCopy() as! NSMutableParagraphStyle
                paragraph.alignment = NSTextAlignment.Center
                return paragraph
                }()
            ]
        )
        
        static let MediumGrey: TextAttribute = TextAttributes.extend(Medium, withAttributes: [
                NSForegroundColorAttributeName: Colors.DarkGrey
            ]
        )
        
        static let MediumSoftGrey: TextAttribute = TextAttributes.extend(Medium, withAttributes: [
                NSForegroundColorAttributeName: Colors.SoftGrey
            ]
        )
        
        static let Small = [
            NSForegroundColorAttributeName: Colors.Black,
            NSKernAttributeName: -Fonts.Kerning.VerySmall,
            NSFontAttributeName: Fonts.regularFontWithSize(Fonts.Size.Small),
            NSParagraphStyleAttributeName: {
                let paragraph = NSMutableParagraphStyle()
                paragraph.lineSpacing = Metrics.LineSpacing.Large
                return paragraph
                }()
        ]
        
        static let SmallCentered: TextAttribute = TextAttributes.extend(Small, withAttributes: [
            NSParagraphStyleAttributeName: {
                let paragraph = (Small[NSParagraphStyleAttributeName] as! NSParagraphStyle).mutableCopy() as! NSMutableParagraphStyle
                paragraph.alignment = NSTextAlignment.Center
                return paragraph
                }()
            ]
        )
        
        static let SmallGrey: TextAttribute = TextAttributes.extend(Small, withAttributes: [
                NSForegroundColorAttributeName: Colors.DarkGrey
            ]
        )
        
        static let SmallGreyCentered: TextAttribute = TextAttributes.extend(SmallGrey, withAttributes: [
            NSParagraphStyleAttributeName: {
                let paragraph = (SmallGrey[NSParagraphStyleAttributeName] as! NSParagraphStyle).mutableCopy() as! NSMutableParagraphStyle
                paragraph.alignment = NSTextAlignment.Center
                return paragraph
                }()
            ]
        )
        
        static let SmallSoftGrey: TextAttribute = TextAttributes.extend(SmallGrey, withAttributes: [
                NSForegroundColorAttributeName: Colors.SoftGrey
            ]
        )
        
        static let SmallSoftGreyCentered: TextAttribute = TextAttributes.extend(SmallSoftGrey, withAttributes: [
            NSParagraphStyleAttributeName: {
                let paragraph = (SmallSoftGrey[NSParagraphStyleAttributeName] as! NSParagraphStyle).mutableCopy() as! NSMutableParagraphStyle
                paragraph.alignment = NSTextAlignment.Center
                return paragraph
                }()
            ]
        )
        
        static let LargeIndication = [
            NSForegroundColorAttributeName: Colors.Black,
            NSKernAttributeName: -Fonts.Kerning.Small,
            NSFontAttributeName: Fonts.lightFontWithSize(Fonts.Size.AlmostLarge),
            NSParagraphStyleAttributeName: {
                let paragraph = NSMutableParagraphStyle()
                paragraph.lineSpacing = Metrics.LineSpacing.Medium
                return paragraph
                }()
        ]
        
        static let LargeIndicationGrey: TextAttribute = TextAttributes.extend(LargeIndication, withAttributes: [
                NSForegroundColorAttributeName: Colors.DarkGrey
            ]
        )
        
        static let LargeIndicationGreyCentered: TextAttribute = TextAttributes.extend(LargeIndicationGrey, withAttributes: [
            NSParagraphStyleAttributeName: {
                let paragraph = (LargeIndicationGrey[NSParagraphStyleAttributeName] as! NSParagraphStyle).mutableCopy() as! NSMutableParagraphStyle
                paragraph.alignment = NSTextAlignment.Center
                return paragraph
                }()
            ]
        )
        
        static let HugeNumberGrey = [
            NSForegroundColorAttributeName: Colors.DarkGrey,
            NSKernAttributeName: -Fonts.Kerning.Small,
            NSFontAttributeName: Fonts.lightFontWithSize(40)
        ]
        
        static let LargeTitle = [
            NSForegroundColorAttributeName: Colors.Black,
            NSKernAttributeName: -Fonts.Kerning.Small,
            NSFontAttributeName: Fonts.regularFontWithSize(Fonts.Size.Large)
        ]
        
        static let RoundedButtonText = [
            NSForegroundColorAttributeName: Colors.White,
            NSKernAttributeName: -Fonts.Kerning.Small,
            NSFontAttributeName: Fonts.regularFontWithSize(Fonts.Size.AlmostLarge)
        ]
        
        static let Huge = [
            NSForegroundColorAttributeName: Colors.Black,
            NSKernAttributeName: -Fonts.Kerning.Large,
            NSFontAttributeName: Fonts.regularFontWithSize(Fonts.Size.MegaLarge)
        ]
        
        static let HugeLight: TextAttribute = TextAttributes.extend(Huge, withAttributes: [
                NSFontAttributeName: Fonts.lightFontWithSize((Huge[NSFontAttributeName] as! UIFont).pointSize)
            ]
        )
        
        static let SectionTitle = [
            NSForegroundColorAttributeName: Colors.Black,
            NSKernAttributeName: -Fonts.Kerning.Small,
            NSFontAttributeName: Fonts.semiboldFontWithSize(Fonts.Size.AlmostLarge)
        ]
        
        static let LargeIconGrey = [
            NSForegroundColorAttributeName: Colors.LightGrey,
            NSFontAttributeName: Fonts.iconFontWithSize(Fonts.Size.MegaLarge)
        ]
        
        private static func extend(textAttribute: TextAttribute, withAttributes attributes: TextAttribute) -> TextAttribute {
            var newAttributes = textAttribute
            newAttributes.merge(attributes)
            return newAttributes
        }
        
    }
    
    struct Colors {
        
        static let Transparent = UIColor.clearColor()
        static let Black = UIColor(hex: 0x000000)
        static let White = UIColor(hex: 0xffffff)
        static let BackgroundColor = UIColor(hex: 0xf9f9f9)
        static let NightBlue = UIColor(hex: 0x1d2028)
        static let LightGreyBlue = UIColor(hex: 0xcccff0)
        static let DarkGreyBlue = UIColor(hex: 0x333745)
        static let GreyBlue = UIColor(hex: 0x71737d)
        static let InvalidRed = UIColor(hex: 0xea2e49)
        static let ValidGreen = UIColor(hex: 0x3fb34f)
        static let ActionGreen = UIColor(hex: 0x41ccb4)
        static let ActionPurple = UIColor(hex: 0x596799)
        static let ExtraDarkGrey = UIColor(hex: 0x333333)
        static let DarkGrey = UIColor(hex: 0x666666)
        static let SoftGrey = UIColor(hex: 0x999999)
        static let LightGrey = UIColor(hex: 0xcccccc)
        static let VeryLightGrey = UIColor(hex: 0xeeeeee)
        static let ExtraLightGrey = UIColor(hex: 0xf4f4f4)
        
    }
    
    struct Fonts {
        
        private enum Name: String {
            case OpenSansLight = "OpenSans-Light"
            case OpenSansRegular = "OpenSans"
            case OpenSansSemibold = "OpenSans-Semibold"
            case OpenSansBold = "OpenSans-Bold"
            case OpenSansExtrabold = "OpenSans-Extrabold"
            case FontAwesome = "FontAwesome"
        }
        
        struct Size {
            static let Small:CGFloat = 12
            static let Medium:CGFloat = 14
            static let AlmostLarge:CGFloat = 15
            static let Large:CGFloat = 16
            static let ExtraLarge:CGFloat = 18
            static let AlmostUltraLarge:CGFloat = 19
            static let UltraLarge:CGFloat = 20
            static let MegaLarge:CGFloat = 24
            static let ExtraHuge:CGFloat = 27
            static let UltraHuge:CGFloat = 42
        }
        
        struct Kerning {
            static let VerySmall: CGFloat = 0.2
            static let Small: CGFloat = 0.5
            static let Medium: CGFloat = 0.9
            static let Large: CGFloat = 1.2
            static let VeryLarge: CGFloat = 1.5
        }
        
        private static func fontWithName(name: String, size: CGFloat) -> UIFont {
            if let font = UIFont(name: name, size: size) {
                return font
            }
            return UIFont.systemFontOfSize(UIFont.systemFontSize())
        }
        
        static func lightFontWithSize(size: CGFloat) -> UIFont {
            return fontWithName(Name.OpenSansLight.rawValue, size: size)
        }
        
        static func regularFontWithSize(size: CGFloat) -> UIFont {
            return fontWithName(Name.OpenSansRegular.rawValue, size: size)
        }
        
        static func semiboldFontWithSize(size: CGFloat) -> UIFont {
            return fontWithName(Name.OpenSansSemibold.rawValue, size: size)
        }
        
        static func boldFontWithSize(size: CGFloat) -> UIFont {
            return fontWithName(Name.OpenSansBold.rawValue, size: size)
        }
        
        static func extraboldFontWithSize(size: CGFloat) -> UIFont {
            return fontWithName(Name.OpenSansExtrabold.rawValue, size: size)
        }
        
        static func iconFontWithSize(size: CGFloat) -> UIFont {
            return fontWithName(Name.FontAwesome.rawValue, size: size)
        }
        
    }
    
    struct Metrics {
        
        struct View {
            
            struct NavigationBar {
                struct Height {
                    static let Default = Medium
                    static let Medium: CGFloat = 60
                    static let Small: CGFloat = 44
                }
            }
            
        }
        
        struct BordersRadius {
            static let Default = Medium
            static let Small:CGFloat = 3
            static let Medium:CGFloat = 5
            static let Large:CGFloat = 10
        }
        
        struct Padding {
            static let VerySmall:CGFloat = 10
            static let AlmostSmall:CGFloat = 15
            static let Small:CGFloat = 20
            static let AlmostMedium:CGFloat = 25
            static let Medium:CGFloat = 30
        }
        
        struct LineSpacing {
            static let Small:CGFloat = 4
            static let Medium:CGFloat = 6
            static let Large:CGFloat = 8
        }
        
    }
    
    struct Durations {
        
        struct Animation {
            static let Default = Medium
            static let VeryShort = 0.17
            static let Short = 0.25
            static let Medium = 0.32
            static let Long = 0.40
        }
        
    }

    struct Factors {
        
        struct Darken {
            static let Default = Strong
            static let Light:CGFloat = 0.03
            static let Medium:CGFloat = 0.05
            static let Strong:CGFloat = 0.08
            static let VeryStrong:CGFloat = 0.1
            static let ExtraStrong:CGFloat = 0.15
            static let UltraStrong:CGFloat = 0.20
        }
        
    }
    
}