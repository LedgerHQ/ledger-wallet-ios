//
//  LoadingIndicator.swift
//  ledger-wallet-ios
//
//  Created by Nicolas Bigot on 28/01/2015.
//  Copyright (c) 2015 Ledger. All rights reserved.
//

import UIKit

class LoadingIndicator: View {
    
    var dotsCount: Int = 12 {
        didSet {
            generateLayers()
        }
    }
    var dotsSize: CGFloat = 4.0 {
        didSet {
            layer.setNeedsLayout()
        }
    }
    var animating: Bool { return timer != nil }
    var animationDuration: NSTimeInterval = 0.15 {
        didSet {
            if animating {
                stopAnimating()
                timer?.invalidate()
                timer = scheduledTimer()
                startAnimating()
            }
        }
    }
    var preferredWidth: CGFloat = 50 {
        didSet {
            invalidateIntrinsicContentSize()
        }
    }
    var dotsNormalColor: UIColor = UIColor.blackColor() {
        didSet {
            
        }
    }
    var dotsHighlightedColor: UIColor = UIColor.redColor() {
        didSet {
            
        }
    }
    var autoStartAnimating = true
    private var timer: NSTimer? = nil
    private var highlightedLayerIndex = -1
    
    // MARK: - Animation
    
    func startAnimating() {
        if (animating) {
            return
        }
        
        timer = scheduledTimer()
    }
    
    func stopAnimating() {
        if (!animating) {
            return
        }

        timer?.invalidate()
        timer = nil
    }
    
    private func scheduledTimer() -> NSTimer {
        return NSTimer.scheduledTimerWithTimeInterval(animationDuration, target: self, selector: "timerFired", userInfo: nil, repeats: true)
    }
    
    dynamic private func timerFired() {
        let oldIndex = highlightedLayerIndex
        highlightedLayerIndex++
        if (highlightedLayerIndex >= layer.sublayers.count) {
            highlightedLayerIndex = 0
            if (highlightedLayerIndex >= layer.sublayers.count) {
                return
            }
        }
        
        if (oldIndex >= 0) {
            if let layer = layer.sublayers[oldIndex] as? CALayer {
                CATransaction.begin()
                CATransaction.setAnimationDuration(0.25)
                layer.backgroundColor = dotsNormalColor.CGColor
                CATransaction.commit()
            }
        }
        if let layer = layer.sublayers[highlightedLayerIndex] as? CALayer {
            CATransaction.begin()
            CATransaction.setDisableActions(true)
            layer.backgroundColor = dotsHighlightedColor.CGColor
            CATransaction.commit()
        }
    }
    
    // MARK: - Layers
    
    private func generateLayers() {
        removeLayers()
        highlightedLayerIndex = -1
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        for _ in 0..<dotsCount {
            let layer = CALayer()
            layer.contentsScale = DeviceManager.sharedInstance().screenScale
            layer.bounds = CGRectZero
            layer.allowsEdgeAntialiasing = true
            layer.backgroundColor = dotsNormalColor.CGColor
            self.layer.addSublayer(layer)
        }
        CATransaction.commit()
        layer.setNeedsLayout()
    }
    
    private func removeLayers() {
        iterateThroughLayers() { layer in
            layer.removeFromSuperlayer()
        }
    }
    
    private func iterateThroughLayers(closure: (CALayer) -> Void) {
        if (layer.sublayers == nil) {
            return
        }
        for layer in self.layer.sublayers as! [CALayer] {
            closure(layer)
        }
    }
    
    // MARK: - Layout
    
    override func layoutSublayersOfLayer(layer: CALayer!) {
        super.layoutSublayersOfLayer(layer)
        
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        let increment = CGFloat(M_PI * 2.0) / CGFloat(dotsCount)
        var angle: CGFloat = 0.0
        let radius = (layer.bounds.size.width - dotsSize) / 2.0
        iterateThroughLayers() { sublayer in
            let center = CGPointMake(CGRectGetMidX(layer.bounds), CGRectGetMidY(layer.bounds))
            sublayer.bounds = CGRectMake(0, 0, self.dotsSize, self.dotsSize)
            sublayer.position = CGPointMake(center.x + radius * cos(angle), center.y + radius * sin(angle))
            sublayer.transform = CATransform3DMakeRotation(angle, 0, 0, 1)
            angle += increment
        }
        CATransaction.commit()
    }
    
    override func intrinsicContentSize() -> CGSize {
        return CGSizeMake(preferredWidth, preferredWidth)
    }
    
    // MARK: - Initialization
    
    override func didMoveToSuperview() {
        super.didMoveToSuperview()
        
        if (superview == nil) {
            stopAnimating()
        }
        else if autoStartAnimating {
            startAnimating()
        }
    }
    
    private func initialize() {
        backgroundColor = UIColor.clearColor()
        generateLayers()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        initialize()
    }
    
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        initialize()
    }
    
}
