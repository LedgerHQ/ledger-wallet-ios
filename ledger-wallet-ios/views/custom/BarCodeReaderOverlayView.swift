//
//  BarCodeReaderOverlayView.swift
//  ledger-wallet-ios
//
//  Created by Nicolas Bigot on 19/01/2015.
//  Copyright (c) 2015 Ledger. All rights reserved.
//

import UIKit

class BarCodeReaderOverlayView: View {

    // MARK: - Drawing
    
    override func drawRect(rect: CGRect) {
        super.drawRect(rect)
        
        let context = UIGraphicsGetCurrentContext()
        let squareWidth = bounds.size.width * 0.6
        let squareRect = CGRectMake((bounds.size.width - squareWidth) / 2.0, (bounds.size.height - squareWidth) / 2.0, squareWidth, squareWidth)
        let roundedPath = UIBezierPath(roundedRect: squareRect, cornerRadius: VisualFactory.Metrics.BordersRadii.medium)
        let handlesWidth:CGFloat = 7
        let handlesSize:CGFloat = 40
        
        // overlay
        CGContextSaveGState(context)
        UIColor.blackColor().colorWithAlphaComponent(0.3).setFill()
        CGContextFillRect(context, bounds)
        roundedPath.fillWithBlendMode(kCGBlendModeClear, alpha: 1.0)
        CGContextRestoreGState(context)
        
        // handles
        CGContextSaveGState(context)
        UIColor.whiteColor().colorWithAlphaComponent(0.75).setFill()
        roundedPath.fill()
        UIBezierPath(roundedRect: CGRectInset(squareRect, handlesWidth, handlesWidth), cornerRadius: VisualFactory.Metrics.BordersRadii.medium).fillWithBlendMode(kCGBlendModeClear, alpha: 1.0)
        UIBezierPath(roundedRect: CGRectInset(squareRect, handlesSize, 0), cornerRadius: 0).fillWithBlendMode(kCGBlendModeClear, alpha: 1.0)
        UIBezierPath(roundedRect: CGRectInset(squareRect, 0, handlesSize), cornerRadius: 0).fillWithBlendMode(kCGBlendModeClear, alpha: 1.0)
        CGContextRestoreGState(context)
    }
    
    // MARK: - Initialization
    
    private func initialize() {
        backgroundColor = UIColor.clearColor()
        opaque = false
    }
    
    override init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        initialize()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        initialize()
    }
    
}