//
//  PairingAddViewController.swift
//  ledger-wallet-ios
//
//  Created by Nicolas Bigot on 15/01/2015.
//  Copyright (c) 2015 Ledger. All rights reserved.
//

import UIKit

class PairingAddViewController: ViewController {

    @IBOutlet private weak var containerView: UIView!
    @IBOutlet private weak var stepNumberLabel: Label!
    @IBOutlet private weak var stepIndicationLabel: Label!
    @IBOutlet private weak var bottomInsetConstraint: NSLayoutConstraint!
    
    private let stepClasses: [PairingAddBaseStepViewController.Type] = [
        PairingAddScanStepViewController.self,
        PairingAddCodeStepViewController.self,
        PairingAddNameStepViewController.self
    ]
    private var currentStepNumber = -1
    private var currentStepViewController: PairingAddBaseStepViewController?
    
    // MARK: Steps management

    func navigateToNextStep() {
        navigateToStep(currentStepNumber + 1)
    }
    
    private func navigateToStep(stepNumber: Int) {
        // instantiate new view controller
        let newViewController = stepClasses[stepNumber].instantiateFromNib()
        addChildViewController(newViewController)
        newViewController.didMoveToParentViewController(self)
        newViewController.view.frame = containerView.bounds
        newViewController.view.setNeedsLayout()
        newViewController.view.layoutIfNeeded()
        containerView?.addSubview(newViewController.view)

        // animate slide to new view controller if there is already a view controller
        if let currentViewController = currentStepViewController {
            // create transision
            let transition = CATransition()
            transition.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseOut)
            transition.type = kCATransitionPush
            transition.subtype = kCATransitionFromRight
            transition.duration = VisualFactory.Metrics.defaultAnimationDuration
            transition.delegate = self
            transition.setValue(currentViewController, forKey: "stepViewController")
            
            // remove current view controller from children
            currentViewController.willMoveToParentViewController(nil)
            currentViewController.removeFromParentViewController()
            
            self.containerView?.layer.addAnimation(transition, forKey: nil)
        }

        
        // retain new view controller
        currentStepViewController = newViewController
        
        // update view
        updateView()
        
        // update current step
        currentStepNumber = stepNumber
    }
    
    // MARK: Actions
    
    override func complete() {
        // complete current step view controller
        currentStepViewController?.complete()
        
        // dimiss pairing
        self.presentingViewController?.dismissViewControllerAnimated(true, completion: nil)
    }
    
    override func cancel() {
        // cancel current step view controller
        currentStepViewController?.cancel()
        
        // dimiss pairing
        self.presentingViewController?.dismissViewControllerAnimated(true, completion: nil)
    }
    
    // MARK: Interface
    
    override func updateView() {
        super.updateView()
        
        navigationItem.rightBarButtonItem?.customView?.hidden = !currentStepViewController!.finalizesFlow
        stepNumberLabel?.text = "\(currentStepViewController!.stepNumber)."
        stepIndicationLabel?.text = currentStepViewController!.stepIndication
    }
    
    override func configureView() {
        super.configureView()
        
        navigateToNextStep()
    }
    
    private func adjustContentInset(height: CGFloat, duration: NSTimeInterval, options: UIViewAnimationOptions, animated: Bool) {
        bottomInsetConstraint?.constant = height
        view.setNeedsLayout()
        
        if (animated) {
            UIView.animateWithDuration(duration, delay: 0, usingSpringWithDamping: 1.0, initialSpringVelocity: 1.0, options: options, animations: {
                self.view.layoutIfNeeded()
            }, completion: nil)
        }
        else {
            view.layoutIfNeeded()
        }
    }
    
    // MARK: Keyboard management
    
    override func keyboardWillHide(userInfo: [NSObject : AnyObject]) {
        super.keyboardWillHide(userInfo)
        
        let duration = (userInfo[UIKeyboardAnimationDurationUserInfoKey] as NSNumber).doubleValue
        let options = UIViewAnimationOptions(UInt((userInfo[UIKeyboardAnimationCurveUserInfoKey] as NSNumber).integerValue << 16))
        adjustContentInset(0, duration: duration, options: options, animated: true)
    }
    
    override func keyboardWillShow(userInfo: [NSObject : AnyObject]) {
        super.keyboardWillShow(userInfo)
        
        let duration = (userInfo[UIKeyboardAnimationDurationUserInfoKey] as NSNumber).doubleValue
        let options = UIViewAnimationOptions(UInt((userInfo[UIKeyboardAnimationCurveUserInfoKey] as NSNumber).integerValue << 16))
        adjustContentInset(keyboardFrame.size.height, duration: duration, options: options, animated: true)
    }
    
    // MARK: Layout
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        currentStepViewController?.view.frame = containerView.bounds
    }
    
}

extension PairingAddViewController {
    
    // MARK: CATransition delegate
    
    override func animationDidStop(anim: CAAnimation!, finished flag: Bool) {
        // remove previous view controller view
        let stepViewController = anim.valueForKey("stepViewController") as? PairingAddBaseStepViewController
        stepViewController?.view.removeFromSuperview()
    }
    
}
