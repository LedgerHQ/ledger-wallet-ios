//
//  RoundedButton.swift
//  ledger-wallet-ios
//
//  Created by Nicolas Bigot on 14/01/2015.
//  Copyright (c) 2015 Ledger. All rights reserved.
//

import UIKit

class RoundedButton: Button {
    
    private var fillColors: [UInt: UIColor] = [:]

    //MARK: Border radius
    
    var borderRadius: CGFloat = VisualFactory.Metrics.defaultBorderRadius {
        didSet {
            setNeedsDisplay()
        }
    }
    
    //MARK: Fill color
    
    func setFillColor(color: UIColor, forState state: UIControlState) {
        fillColors.updateValue(color, forKey: state.rawValue)
        setNeedsDisplay()
    }
    
    func fillColorForState(state: UIControlState) -> UIColor {
        if let color = self.fillColors[state.rawValue] {
            return color
        }
        if let color = self.fillColors[UIControlState.Normal.rawValue] {
            return color
        }
        return UIColor.clearColor()
    }
    
    //MARK: Drawing invalidation
    
    override var selected: Bool {
        didSet {
            setNeedsDisplay()
        }
    }
    override  var highlighted: Bool {
        didSet {
            setNeedsDisplay()
        }
    }
    
    //MARK: Drawing
    
    override func drawRect(rect: CGRect) {
        fillColorForState(self.state).setFill()
        let fillPath = UIBezierPath(roundedRect: self.bounds, cornerRadius: self.borderRadius)
        fillPath.fill()
        super.drawRect(rect)
    }
    
}
