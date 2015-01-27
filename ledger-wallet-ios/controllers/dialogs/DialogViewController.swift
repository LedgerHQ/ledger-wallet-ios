//
//  DialogViewController.swift
//  ledger-wallet-ios
//
//  Created by Nicolas Bigot on 22/01/2015.
//  Copyright (c) 2015 Ledger. All rights reserved.
//

import UIKit

class DialogViewController: BaseViewController {
    
    private lazy var dialogAnimationController = DialogAnimationController()
    var dialogContentPadding: UIEdgeInsets {
        return UIEdgeInsetsMake(VisualFactory.Metrics.Paddings.medium, VisualFactory.Metrics.Paddings.medium, VisualFactory.Metrics.Paddings.medium, VisualFactory.Metrics.Paddings.medium)
    }
    var dialogContainerMargin: UIEdgeInsets {
        return UIEdgeInsetsMake(VisualFactory.Metrics.Paddings.small, VisualFactory.Metrics.Paddings.small, VisualFactory.Metrics.Paddings.small, VisualFactory.Metrics.Paddings.small)
    }
    var dialogContentDistance: UIEdgeInsets {
        return UIEdgeInsetsMake(dialogContentPadding.top + dialogContainerMargin.top, dialogContentPadding.left + dialogContainerMargin.left, dialogContentPadding.bottom + dialogContainerMargin.bottom, dialogContentPadding.right + dialogContainerMargin.right)
    }
    
    // MARK: Content size
    
    func dialogLayoutSize(constraintedSize size: CGSize) -> CGSize {
        let contentSize = view.systemLayoutSizeFittingSize(UILayoutFittingCompressedSize)
        return CGSizeMake(contentSize.width + dialogContentPadding.left + dialogContentPadding.right, contentSize.height + dialogContentPadding.top + dialogContentPadding.bottom)
    }
    
    // MARK: Initialization
    
    private func initialize() {
        transitioningDelegate = self
        modalPresentationStyle = UIModalPresentationStyle.Custom
    }
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: NSBundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        
        initialize()
    }
    
    override init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        initialize()
    }
    
}

extension DialogViewController: UIViewControllerTransitioningDelegate {
    
    // MARK: Transitioning delegate
    
    func animationControllerForPresentedController(presented: UIViewController, presentingController presenting: UIViewController, sourceController source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return dialogAnimationController
    }
    
    func animationControllerForDismissedController(dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return dialogAnimationController
    }
    
}

