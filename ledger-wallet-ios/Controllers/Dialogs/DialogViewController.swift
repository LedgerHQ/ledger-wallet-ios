//
//  DialogViewController.swift
//  ledger-wallet-ios
//
//  Created by Nicolas Bigot on 22/01/2015.
//  Copyright (c) 2015 Ledger. All rights reserved.
//

import UIKit

class DialogViewController: BaseViewController {
    
    lazy var contentPadding = UIEdgeInsetsMake(VisualFactory.Metrics.Padding.Medium, VisualFactory.Metrics.Padding.Medium, VisualFactory.Metrics.Padding.Medium, VisualFactory.Metrics.Padding.Medium)
    lazy var containerMargin = UIEdgeInsetsMake(VisualFactory.Metrics.Padding.Small, VisualFactory.Metrics.Padding.Small, VisualFactory.Metrics.Padding.Small, VisualFactory.Metrics.Padding.Small)
    private lazy var dialogAnimationController = DialogAnimationController()
    
    // MARK: - Initialization
    
    private func initialize() {
        transitioningDelegate = self
        modalPresentationStyle = UIModalPresentationStyle.Custom
    }
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: NSBundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        
        initialize()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        initialize()
    }
    
}

extension DialogViewController: UIViewControllerTransitioningDelegate {
    
    // MARK: - Transitioning delegate
    
    func animationControllerForPresentedController(presented: UIViewController, presentingController presenting: UIViewController, sourceController source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return dialogAnimationController
    }
    
    func animationControllerForDismissedController(dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return dialogAnimationController
    }
    
}

