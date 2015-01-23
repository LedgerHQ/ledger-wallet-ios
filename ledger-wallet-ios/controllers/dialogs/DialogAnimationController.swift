//
//  DialogAnimationController.swift
//  ledger-wallet-ios
//
//  Created by Nicolas Bigot on 22/01/2015.
//  Copyright (c) 2015 Ledger. All rights reserved.
//

import UIKit

class DialogAnimationController: NSObject {
    
    private var dimmingView: UIView!
    private var backgroundView: UIView!
    lazy private var dialogLayoutMargins: UIEdgeInsets = UIEdgeInsetsMake(VisualFactory.Metrics.Paddings.medium, VisualFactory.Metrics.Paddings.medium, VisualFactory.Metrics.Paddings.medium, VisualFactory.Metrics.Paddings.medium)
    
}

extension DialogAnimationController: UIViewControllerAnimatedTransitioning {
    
    //MARK: Transition
    
    func animateTransition(transitionContext: UIViewControllerContextTransitioning) {
        let toViewController = transitionContext.viewControllerForKey(UITransitionContextToViewControllerKey)!
        
        if (toViewController.isBeingPresented()) {
            let containerView = transitionContext.containerView()
            
            // create dimming view
            dimmingView = UIView()
            dimmingView.backgroundColor = VisualFactory.Colors.black.colorWithAlphaComponent(0.3)
            dimmingView.frame = containerView.bounds
            dimmingView.alpha = 0.0
            containerView.addSubview(dimmingView)
            
            // create background view
            let contentView = toViewController.view
            contentView.setNeedsLayout()
            contentView.layoutIfNeeded()
            let contentViewSize = (toViewController as DialogViewController).dialogContentSize
            let backgroundViewSize = CGSizeMake(contentViewSize.width + dialogLayoutMargins.left + dialogLayoutMargins.right, contentViewSize.height + dialogLayoutMargins.top + dialogLayoutMargins.bottom)
            backgroundView = UIView()
            backgroundView.backgroundColor = contentView.backgroundColor
            backgroundView.layer.cornerRadius = VisualFactory.Metrics.defaultBorderRadius
            backgroundView.layer.shadowColor = UIColor.blackColor().CGColor
            backgroundView.layer.shadowOffset = CGSizeZero
            backgroundView.layer.shadowRadius = VisualFactory.Metrics.Paddings.almostSmall
            backgroundView.layer.shadowOpacity = 0.2
            backgroundView.frame = CGRectMake((dimmingView.bounds.size.width - backgroundViewSize.width) / 2.0, dimmingView.bounds.size.height, backgroundViewSize.width, backgroundViewSize.height)
            dimmingView.addSubview(backgroundView)
            
            // create content view
            contentView.frame = CGRectMake(dialogLayoutMargins.left, dialogLayoutMargins.top, contentViewSize.width, contentViewSize.height)
            backgroundView.addSubview(contentView)
            
            // animate
            UIView.animateWithDuration(transitionDuration(transitionContext), delay: 0, usingSpringWithDamping: 1.0, initialSpringVelocity: 1.0, options: UIViewAnimationOptions(0), animations: {
                self.dimmingView.alpha = 1.0
                self.backgroundView.center = self.dimmingView.center
            }, completion: { finished in
                transitionContext.completeTransition(finished)
            })
        }
        else {
            // animate
            UIView.animateWithDuration(transitionDuration(transitionContext), delay: 0, usingSpringWithDamping: 1.0, initialSpringVelocity: 1.0, options: UIViewAnimationOptions(0), animations: {
                self.dimmingView.alpha = 0.0
                self.backgroundView.center = CGPointMake(self.dimmingView.center.x, self.dimmingView.bounds.size.height + self.backgroundView.bounds.size.height / 2.0)
            }, completion: { finished in
                transitionContext.completeTransition(finished)
            })
        }
    }
    
    func transitionDuration(transitionContext: UIViewControllerContextTransitioning) -> NSTimeInterval {
        if (transitionContext.isAnimated()) {
            return VisualFactory.Metrics.Durations.Animations.long
        }
        return 0
    }
    
}