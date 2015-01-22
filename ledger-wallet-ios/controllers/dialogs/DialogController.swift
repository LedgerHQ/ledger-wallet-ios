//
//  DialogController.swift
//  ledger-wallet-ios
//
//  Created by Nicolas Bigot on 22/01/2015.
//  Copyright (c) 2015 Ledger. All rights reserved.
//

import UIKit

class DialogController {
    
    var presented: Bool {
        return _presented
    }
    private var dialogViewController: DialogViewController!
    private var _presented = false
    private var dimmingView: UIView!
    private var backgroundView: UIView!
    lazy private var dialogLayoutMargins: UIEdgeInsets = UIEdgeInsetsMake(VisualFactory.Metrics.Paddings.medium, VisualFactory.Metrics.Paddings.medium, VisualFactory.Metrics.Paddings.medium, VisualFactory.Metrics.Paddings.medium)
    
    //MARK: Presentation
    
    func presentDialogFromView(view: UIView, animated: Bool, completion: ((Bool) -> Void)?) {
        if (_presented) {
            return
        }
        
        // create dimming view
        dimmingView = UIView()
        dimmingView.backgroundColor = VisualFactory.Colors.black.colorWithAlphaComponent(0.3)
        dimmingView.frame = view.bounds
        dimmingView.alpha = 0.0
        view.addSubview(dimmingView)

        // create background view
        let contentViewSize = dialogViewController.viewContentSize
        let backgroundViewSize = CGSizeMake(contentViewSize.width + dialogLayoutMargins.left + dialogLayoutMargins.right, contentViewSize.height + dialogLayoutMargins.top + dialogLayoutMargins.bottom)
        backgroundView = UIView()
        backgroundView.backgroundColor = UIColor.whiteColor()
        backgroundView.layer.cornerRadius = VisualFactory.Metrics.defaultBorderRadius
        backgroundView.layer.shadowColor = UIColor.blackColor().CGColor
        backgroundView.layer.shadowOffset = CGSizeZero
        backgroundView.layer.shadowRadius = VisualFactory.Metrics.Paddings.almostSmall
        backgroundView.layer.shadowOpacity = 0.2
        backgroundView.frame = CGRectMake((dimmingView.bounds.size.width - backgroundViewSize.width) / 2.0, dimmingView.bounds.size.height, backgroundViewSize.width, backgroundViewSize.height)
        dimmingView.addSubview(backgroundView)
        
        // create content view
        let contentView = dialogViewController.view
        contentView.frame = CGRectMake(dialogLayoutMargins.left, dialogLayoutMargins.top, contentViewSize.width, contentViewSize.height)
        backgroundView.addSubview(contentView)
        
        _presented = true
        
        // animate
        UIView.animateWithDuration(animated ? VisualFactory.Metrics.Durations.Animations.long : 0, delay: 0.0, usingSpringWithDamping: 1.0, initialSpringVelocity: 1.0, options: UIViewAnimationOptions(0), animations: {
            self.dimmingView.alpha = 1.0
            self.backgroundView.center = view.center
        }, completion: completion)
    }
    
    func dismissDialogAnimated(animated: Bool, completion: ((Bool) -> Void)?) {
        if (!_presented) {
            return
        }
        
        // animate
        UIView.animateWithDuration(animated ? VisualFactory.Metrics.Durations.Animations.long : 0, delay: 0.0, usingSpringWithDamping: 1.0, initialSpringVelocity: 1.0, options: UIViewAnimationOptions(0), animations: {
            self.dimmingView.alpha = 0.0
            self.backgroundView.center = CGPointMake(self.dimmingView.center.x, self.dimmingView.bounds.size.height + self.backgroundView.bounds.size.height / 2.0)
        }, completion: { finished in
            self.cleanUp()
            completion?(finished)
        })
        
    }

    private func cleanUp() {
        backgroundView?.removeFromSuperview()
        dimmingView?.removeFromSuperview()
        backgroundView = nil
        dimmingView = nil
        dialogViewController = nil
        _presented = false
    }
    
    //MARK: Initialization
    
    init(dialogViewController: DialogViewController) {
        self.dialogViewController = dialogViewController
    }
    
    deinit {
        cleanUp()
        
    }
    
}