//
//  PairingAddViewController.swift
//  ledger-wallet-ios
//
//  Created by Nicolas Bigot on 15/01/2015.
//  Copyright (c) 2015 Ledger. All rights reserved.
//

import UIKit

protocol PairingAddViewControllerDelegate: class {
    
    func pairingAddViewController(pairingAddViewController: PairingAddViewController, didCompleteWithOutcome outcome: PairingProtocolManager.PairingOutcome)
    
}

class PairingAddViewController: BaseViewController {

    @IBOutlet private weak var containerView: UIView!
    @IBOutlet private weak var stepNumberLabel: Label!
    @IBOutlet private weak var stepIndicationLabel: Label!
    @IBOutlet private weak var bottomInsetConstraint: NSLayoutConstraint!
    
    weak var delegate: PairingAddViewControllerDelegate? = nil
    private var pairingProtocolManager: PairingProtocolManager? = nil
    private var currentStepViewController: PairingAddBaseStepViewController? = nil
    
    // MARK: -  Actions
    
    override func complete() {
        // complete current step view controller
        currentStepViewController?.complete()
    }
    
    override func cancel() {
        // cancel current step view controller
        currentStepViewController?.cancel()
        
        // complete
        completeWithOutcome(PairingProtocolManager.PairingOutcome.DeviceTerminated)
    }
    
    private func completeWithOutcome(outcome: PairingProtocolManager.PairingOutcome) {
        // terminate pairing manager
        pairingProtocolManager?.delegate = nil
        pairingProtocolManager?.terminate()
        
        // notify delegate
        delegate?.pairingAddViewController(self, didCompleteWithOutcome: outcome)
    }
    
    // MARK: -  Interface
    
    override func updateView() {
        super.updateView()
        
        navigationItem.rightBarButtonItem?.customView?.hidden = !currentStepViewController!.finalizesFlow
        stepNumberLabel?.text = "\(currentStepViewController!.stepNumber)."
        stepIndicationLabel?.text = currentStepViewController!.stepIndication
    }
    
    override func configureView() {
        super.configureView()
        
        // configure pairing manager
        pairingProtocolManager = PairingProtocolManager()
        pairingProtocolManager?.delegate = self
        
        // go to first step
        navigateToStep(PairingAddScanStepViewController.self, dataToPass: nil, completion: nil)
    }
    
    // MARK: -  Keyboard management
    
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
    
    // MARK: -  Layout
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        currentStepViewController?.view.frame = containerView.bounds
    }
    
}

extension PairingAddViewController {
    
    // MARK: -  Steps management
    
    private class CompletionBlockWrapper {
        let closure: (Bool) -> Void
        
        init(closure: (Bool) -> Void) {
            self.closure = closure
        }
    }
    
    private func navigateToStep(stepClass: PairingAddBaseStepViewController.Type, dataToPass data: AnyObject?, completion: ((Bool) -> Void)?) {
        // instantiate new view controller
        let newViewController = stepClass.instantiateFromNib()
        newViewController.data = data
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
            transition.setValue(currentViewController, forKey: "previousStepViewController")
            if completion != nil {
                transition.setValue(CompletionBlockWrapper(closure: completion!), forKey: "completionBlock")
            }
            
            // remove current view controller from children
            currentViewController.willMoveToParentViewController(nil)
            currentViewController.removeFromParentViewController()
            
            self.containerView?.layer.addAnimation(transition, forKey: nil)
        }
        else {
            completion?(true)
        }
        
        // retain new view controller
        currentStepViewController = newViewController
        
        // update view
        updateView()
    }
    
    func handleStepResult(object: AnyObject, stepViewController: PairingAddBaseStepViewController) {
        if (stepViewController is PairingAddScanStepViewController) {
            // go to connection
            navigateToStep(PairingAddConnectionStepViewController.self, dataToPass: nil) { finished in
                // join room
                self.pairingProtocolManager?.joinRoom(object as String)
                self.pairingProtocolManager?.sendPublicKey()
            }
        }
        else if (stepViewController is PairingAddCodeStepViewController) {
            // go to finialize
            navigateToStep(PairingAddFinalizeStepViewController.self, dataToPass: nil) { finished in
                // send challenge response
                (self.pairingProtocolManager?.sendChallengeResponse(object as String))!
            }
        }
        else if (stepViewController is PairingAddNameStepViewController) {
            // save pairing item
            let name = object as String
            if let canSave = pairingProtocolManager?.canCreatePairingItemNamed(name) {
                let succeeded = pairingProtocolManager?.createNewPairingItemNamed(name)
                if succeeded != nil && succeeded! == true {
                    completeWithOutcome(PairingProtocolManager.PairingOutcome.DeviceSucceeded)
                }
                else {
                    completeWithOutcome(PairingProtocolManager.PairingOutcome.DeviceFailed)
                }
            }
            else {
                completeWithOutcome(PairingProtocolManager.PairingOutcome.DeviceFailed)
            }
        }
    }
    
}

extension PairingAddViewController: PairingProtocolManagerDelegate {
    
    // MARK: -  PairingProtocolManager delegate
    
    func pairingProtocolManager(pairingProtocolManager: PairingProtocolManager, didReceiveChallenge challenge: String) {
        // go to code
        navigateToStep(PairingAddCodeStepViewController.self, dataToPass: nil, completion: nil)
    }
    
    func pairingProtocolManager(pairingProtocolManager: PairingProtocolManager, didTerminateWithOutcome outcome: PairingProtocolManager.PairingOutcome) {
        if (outcome == PairingProtocolManager.PairingOutcome.DongleSucceeded) {
            // go to name
            navigateToStep(PairingAddNameStepViewController.self, dataToPass: nil, completion: nil)
        }
        else {
            // notify delegate
            completeWithOutcome(outcome)
        }
    }
    
}

extension PairingAddViewController {
    
    // MARK: -  CATransition delegate
    
    override func animationDidStop(anim: CAAnimation!, finished flag: Bool) {
        // remove previous view controller view
        let previousStepViewController = anim.valueForKey("previousStepViewController") as? PairingAddBaseStepViewController
        previousStepViewController?.view.removeFromSuperview()
        
        // call completion block
        let completionBlock = anim.valueForKey("completionBlock") as? CompletionBlockWrapper
        completionBlock?.closure(flag)
    }
    
}
