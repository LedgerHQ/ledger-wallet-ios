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

    // MARK: Border radius
    
    var borderRadius: CGFloat = VisualFactory.Metrics.defaultBorderRadius {
        didSet {
            setNeedsDisplay()
        }
    }
    
    // MARK: Fill color
    
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
    
    // MARK: Drawing invalidation
    
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
    
    // MARK: Drawing
    
    override func drawRect(rect: CGRect) {
        let fillPath = UIBezierPath(roundedRect: self.bounds, cornerRadius: self.borderRadius)
        fillColorForState(self.state).setFill()
        fillPath.fill()
        super.drawRect(rect)
    }
    
    // MARK: Layout
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        imageView?.frame = CGRectMake(
            contentEdgeInsets.left + imageEdgeInsets.left,
            (self.bounds.size.height - (self.imageView?.bounds.size.height ?? 0)) / 2,
            (imageView?.bounds.size.width ?? 0),
            (imageView?.bounds.size.height ?? 0))
        titleLabel?.frame = CGRectMake(
            self.bounds.size.width - (titleLabel?.bounds.size.width ?? 0) - contentEdgeInsets.right - titleEdgeInsets.right,
            (self.bounds.size.height - (self.titleLabel?.bounds.size.height ?? 0)) / 2,
            (titleLabel?.bounds.size.width ?? 0),
            (titleLabel?.bounds.size.height ?? 0))
    }
    
    // MARK: Content size
    
    override func intrinsicContentSize() -> CGSize {
        var width: CGFloat = contentEdgeInsets.left + contentEdgeInsets.right
        var height: CGFloat = contentEdgeInsets.top + contentEdgeInsets.bottom
        var contentHeight: CGFloat = 0
        var contentWidth: CGFloat = 0
        
        if let imageSize = currentImage?.size {
            contentWidth += imageSize.width
            contentWidth += imageEdgeInsets.left + imageEdgeInsets.right
            contentHeight = max(contentHeight, imageSize.height + imageEdgeInsets.top + imageEdgeInsets.bottom)
        }
        if let labelAttributes = currentAttributedTitle?.attributesAtIndex(0, effectiveRange: nil) {
            if let labelText = currentAttributedTitle?.string {
                let labelTextAsNSString = labelText as NSString
                let labelSize = labelTextAsNSString.sizeWithAttributes(labelAttributes)
                contentWidth += ceil(labelSize.width)
                contentWidth += titleEdgeInsets.left + titleEdgeInsets.right
                contentHeight = max(contentHeight, ceil(labelSize.height) + titleEdgeInsets.top + titleEdgeInsets.bottom)
            }
        }
        return CGSize(width: width + contentWidth, height: height + contentHeight)
    }
    
}
