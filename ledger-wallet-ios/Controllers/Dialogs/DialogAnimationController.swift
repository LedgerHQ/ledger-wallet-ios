//
//  DialogAnimationController.swift
//  ledger-wallet-ios
//
//  Created by Nicolas Bigot on 22/01/2015.
//  Copyright (c) 2015 Ledger. All rights reserved.
//

import UIKit

class DialogAnimationController: NSObject, UIViewControllerAnimatedTransitioning {
    
    private var dimmingView: UIView!
    private var backgroundView: UIView!
    private var contentView: UIView!
    private var containerView: UIView!
    private var yConstraint: NSLayoutConstraint!
    
    // MARK: Transition
    
    func animateTransition(transitionContext: UIViewControllerContextTransitioning) {
        let toViewController = transitionContext.viewControllerForKey(UITransitionContextToViewControllerKey)!
        
        if toViewController.isBeingPresented() {
            guard let containerView = transitionContext.containerView() else {
                transitionContext.completeTransition(false)
                return
            }
            
            self.containerView = containerView
            
            // create dimming view
            dimmingView = UIView()
            dimmingView.translatesAutoresizingMaskIntoConstraints = true
            dimmingView.backgroundColor = VisualFactory.Colors.Black.colorWithAlphaComponent(0.3)
            dimmingView.frame = containerView.bounds
            dimmingView.alpha = 0.0
            containerView.addSubview(dimmingView)

            // content view
            contentView = toViewController.view
            contentView.translatesAutoresizingMaskIntoConstraints = false
            let padding = (toViewController as! DialogViewController).contentPadding
            let margin = (toViewController as! DialogViewController).containerMargin
            
            // create background view
            backgroundView = UIView()
            backgroundView.translatesAutoresizingMaskIntoConstraints = false
            backgroundView.backgroundColor = contentView.backgroundColor
            backgroundView.layer.cornerRadius = VisualFactory.Metrics.BordersRadius.Large
            backgroundView.layer.shadowColor = UIColor.blackColor().CGColor
            backgroundView.layer.shadowOffset = CGSizeZero
            backgroundView.layer.shadowRadius = VisualFactory.Metrics.Padding.AlmostSmall
            backgroundView.layer.shadowOpacity = 0.15
            dimmingView.addSubview(backgroundView)
            backgroundView.addSubview(contentView)
            
            // constraints
            dimmingView.addConstraint(NSLayoutConstraint(
                item: backgroundView, attribute: .CenterX, relatedBy: .Equal,
                toItem: dimmingView, attribute: .CenterX, multiplier: 1.0, constant: 0.0
            ))
            yConstraint = NSLayoutConstraint(
                item: backgroundView, attribute: .CenterY, relatedBy: .Equal,
                toItem: dimmingView, attribute: .CenterY, multiplier: 1.0, constant: 0.0
            )
            dimmingView.addConstraint(yConstraint)
            dimmingView.addConstraint(NSLayoutConstraint(
                item: backgroundView, attribute: .Leading, relatedBy: .GreaterThanOrEqual,
                toItem: dimmingView, attribute: .Leading, multiplier: 1.0, constant: margin.left
            ))
            dimmingView.addConstraint(NSLayoutConstraint(
                item: dimmingView, attribute: .Trailing, relatedBy: .GreaterThanOrEqual,
                toItem: backgroundView, attribute: .Trailing, multiplier: 1.0, constant: margin.right
            ))
            backgroundView.addConstraint(NSLayoutConstraint(
                item: contentView, attribute: .Leading, relatedBy: .Equal,
                toItem: backgroundView, attribute: .Leading, multiplier: 1.0, constant: padding.left
            ))
            backgroundView.addConstraint(NSLayoutConstraint(
                item: backgroundView, attribute: .Trailing, relatedBy: .Equal,
                toItem: contentView, attribute: .Trailing, multiplier: 1.0, constant: padding.right
            ))
            backgroundView.addConstraint(NSLayoutConstraint(
                item: contentView, attribute: .Top, relatedBy: .Equal,
                toItem: backgroundView, attribute: .Top, multiplier: 1.0, constant: padding.top
            ))
            backgroundView.addConstraint(NSLayoutConstraint(
                item: backgroundView, attribute: .Bottom, relatedBy: .Equal,
                toItem: contentView, attribute: .Bottom, multiplier: 1.0, constant: padding.bottom
            ))
            
            // force layout
            containerView.setNeedsLayout()
            containerView.layoutIfNeeded()
            yConstraint.constant = (containerView.bounds.size.height + backgroundView.bounds.size.height) / 2.0
            containerView.setNeedsLayout()
            containerView.layoutIfNeeded()
            
            // animate
            UIView.animateWithDuration(transitionDuration(transitionContext), delay: 0, usingSpringWithDamping: 1.0, initialSpringVelocity: 1.0, options: UIViewAnimationOptions(rawValue: 0), animations: {
                self.dimmingView.alpha = 1.0
                self.yConstraint.constant = 0
                containerView.setNeedsLayout()
                containerView.layoutIfNeeded()
            }, completion: { finished in
                transitionContext.completeTransition(!transitionContext.transitionWasCancelled())
            })
        }
        else {
            // animate
            UIView.animateWithDuration(transitionDuration(transitionContext), delay: 0, usingSpringWithDamping: 1.0, initialSpringVelocity: 1.0, options: UIViewAnimationOptions(rawValue: 0), animations: {
                self.dimmingView.alpha = 0.0
                self.yConstraint.constant = (self.containerView.bounds.size.height + self.backgroundView.bounds.size.height) / 2.0
                self.containerView.setNeedsLayout()
                self.containerView.layoutIfNeeded()
            }, completion: { finished in
                transitionContext.completeTransition(!transitionContext.transitionWasCancelled())
            })
        }
    }
    
    func transitionDuration(transitionContext: UIViewControllerContextTransitioning?) -> NSTimeInterval {
        if let transitionContext = transitionContext where transitionContext.isAnimated() {
            return VisualFactory.Durations.Animation.Long
        }
        return 0
    }
    
}