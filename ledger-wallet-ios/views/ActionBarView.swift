//
//  ActionBarView.swift
//  ledger-wallet-ios
//
//  Created by Nicolas Bigot on 13/01/2015.
//  Copyright (c) 2015 Ledger. All rights reserved.
//

import UIKit

@IBDesignable

class ActionBarView: View {
    
    enum BorderPosition {
        case Top
        case Bottom
    }
    
    var borderPosition: BorderPosition = BorderPosition.Bottom {
        didSet {
            setNeedsDisplay()
        }
    }
    
    var borderWidth: CGFloat = 1.0 {
        didSet {
            setNeedsDisplay()
        }
    }
    
    var borderColor: UIColor? {
        didSet {
            setNeedsDisplay()
        }
    }

    override var backgroundColor: UIColor? {
        didSet {
            setNeedsDisplay()
        }
    }
    
    override func drawRect(rect: CGRect) {
        let context = UIGraphicsGetCurrentContext()
        
        self.backgroundColor?.setFill()
        CGContextFillRect(context, self.bounds)
        self.borderColor?.setFill()
        if (self.borderPosition == .Top) {
            CGContextFillRect(context, CGRectMake(0, 0, self.bounds.size.width, self.borderWidth))
        }
        else {
            CGContextFillRect(context, CGRectMake(0, self.bounds.size.height - self.borderWidth, self.bounds.size.width, self.borderWidth))
        }
    }
    
}
