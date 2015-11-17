//
//  PairingAddViewController.swift
//  ledger-wallet-ios
//
//  Created by Nicolas Bigot on 15/01/2015.
//  Copyright (c) 2015 Ledger. All rights reserved.
//

import UIKit

protocol PairingAddViewControllerDelegate: class {
    
    func pairingAddViewController(pairingAddViewController: PairingAddViewController, didCompleteWithOutcome outcome: PairingProtocolManager.PairingOutcome, pairingItem: PairingKeychainItem?)
    
}

final class PairingAddViewController: BaseViewController {

    @IBOutlet private weak var containerView: UIView!
    @IBOutlet private weak var stepNumberLabel: Label!
    @IBOutlet private weak var stepIndicationLabel: Label!
    @IBOutlet private weak var bottomInsetConstraint: NSLayoutConstraint!
    
    weak var delegate: PairingAddViewControllerDelegate? = nil
    private var pairingProtocolManager: PairingProtocolManager? = nil
    private var currentStepViewController: PairingAddBaseStepViewController? = nil
    
    // MARK: - Interface
    
    func updateView() {
        navigationItem.leftBarButtonItem?.customView?.hidden = !currentStepViewController!.cancellable
        navigationItem.rightBarButtonItem?.customView?.hidden = !currentStepViewController!.finalizable
        stepNumberLabel?.text = "\(currentStepViewController!.stepNumber)."
        stepIndicationLabel?.text = currentStepViewController!.stepIndication
    }
    
    override func configureView() {
        super.configureView()
        
        // go to first step
        navigateToStep(PairingAddScanStepViewController.self, dataToPass: nil, completion: nil)
    }
    
    // MARK: - View lifecycle
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        observeKeyboardNotifications(true)
        ApplicationManager.sharedInstance.disablesIdleTimer = true
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        
        observeKeyboardNotifications(false)
        ApplicationManager.sharedInstance.disablesIdleTimer = false
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        updateView()
        
        // configure pairing manager
        pairingProtocolManager = PairingProtocolManager()
        pairingProtocolManager?.delegate = self
    }
    
    // MARK: - Layout
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        currentStepViewController?.view.frame = containerView.bounds
    }
    
}

extension PairingAddViewController {
    
    // MARK: - Steps management
    
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
            transition.duration = VisualFactory.Durations.Animation.Default
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
                // connect to websocket
                self.pairingProtocolManager?.connectToRoomWithId(object as! String)
            }
        }
        else if (stepViewController is PairingAddCodeStepViewController) {
            // go to finalize
            navigateToStep(PairingAddFinalizeStepViewController.self, dataToPass: nil) { finished in
                // send challenge response
                self.pairingProtocolManager?.sendChallengeResponse(object as! String)
            }
        }
        else if (stepViewController is PairingAddNameStepViewController) {
            // save pairing item
            let name = object as! String
            if let item = pairingProtocolManager?.createNewPairingItemNamed(name) {
                // register remote notifications
                RemoteNotificationsManager.sharedInstance.registerForRemoteNotifications()
                
                // complete
                completeWithOutcome(PairingProtocolManager.PairingOutcome.DeviceSucceeded, pairingItem: item)
            }
            else {
                // complete
                completeWithOutcome(PairingProtocolManager.PairingOutcome.DeviceFailed, pairingItem: nil)
            }
        }
    }

}

extension PairingAddViewController: PairingProtocolManagerDelegate {
    
    // MARK: - PairingProtocolManager delegate
    
    func pairingProtocolManager(pairingProtocolManager: PairingProtocolManager, didReceiveChallenge challenge: String) {
        // go to code
        navigateToStep(PairingAddCodeStepViewController.self, dataToPass: challenge, completion: nil)
    }
    
    func pairingProtocolManager(pairingProtocolManager: PairingProtocolManager, didTerminateWithOutcome outcome: PairingProtocolManager.PairingOutcome) {
        if (outcome == PairingProtocolManager.PairingOutcome.DongleSucceeded) {
            // go to name
            navigateToStep(PairingAddNameStepViewController.self, dataToPass: nil, completion: nil)
        }
        else {
            // notify delegate
            completeWithOutcome(outcome, pairingItem: nil)
        }
    }
    
}

extension PairingAddViewController: KeyboardObservable {
    
    // MARK: - Keyboard management
    
    func keyboardWillHide(notification: NSNotification) {
        let duration = (valueFromKeyboardNotification(notification, forKey: UIKeyboardAnimationDurationUserInfoKey) as! NSNumber).doubleValue
        let options = UIViewAnimationOptions(rawValue: UInt((valueFromKeyboardNotification(notification, forKey: UIKeyboardAnimationCurveUserInfoKey) as! NSNumber).integerValue << 16))
        adjustContentInset(0, duration: duration, options: options, animated: true)
    }
    
    func keyboardWillShow(notification: NSNotification) {
        let duration = (valueFromKeyboardNotification(notification, forKey: UIKeyboardAnimationDurationUserInfoKey) as! NSNumber).doubleValue
        let options = UIViewAnimationOptions(rawValue: UInt((valueFromKeyboardNotification(notification, forKey: UIKeyboardAnimationCurveUserInfoKey) as! NSNumber).integerValue << 16))
        let keyboardFrame = valueFromKeyboardNotification(notification, forKey: UIKeyboardFrameEndUserInfoKey).CGRectValue
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
    
}

extension PairingAddViewController: CompletionResultable {
    
    @IBAction func complete() {
        // complete current step view controller
        (currentStepViewController as? CompletionResultable)?.complete()
    }
    
    @IBAction func cancel() {
        // cancel current step view controller
        (currentStepViewController as? CompletionResultable)?.cancel()
        
        // complete
        completeWithOutcome(PairingProtocolManager.PairingOutcome.DeviceTerminated, pairingItem: nil)
    }
    
    private func completeWithOutcome(outcome: PairingProtocolManager.PairingOutcome, pairingItem: PairingKeychainItem?) {
        // terminate pairing manager
        pairingProtocolManager?.delegate = nil
        pairingProtocolManager?.terminate()
        
        // notify delegate
        delegate?.pairingAddViewController(self, didCompleteWithOutcome: outcome, pairingItem: pairingItem)
    }
    
}

extension PairingAddViewController {
    
    // MARK: - CATransition delegate
    
    override func animationDidStop(anim: CAAnimation, finished flag: Bool) {
        // remove previous view controller view
        let previousStepViewController = anim.valueForKey("previousStepViewController") as? PairingAddBaseStepViewController
        previousStepViewController?.view.removeFromSuperview()
        
        // call completion block
        let completionBlock = anim.valueForKey("completionBlock") as? CompletionBlockWrapper
        completionBlock?.closure(flag)
    }
    
}
