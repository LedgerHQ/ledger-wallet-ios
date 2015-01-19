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
    
    private let stepClasses: [PairingAddBaseStepViewController.Type] = [
        PairingAddScanStepViewController.self,
        PairingAddCodeStepViewController.self,
        PairingAddNameStepViewController.self
    ]
    private var currentStepNumber = -1
    private var currentStepViewController: PairingAddBaseStepViewController?
    
    //MARK: Steps management
    
    func navigateToNextStep() {
        navigateToStep(currentStepNumber + 1)
    }
    
    private func navigateToStep(stepNumber: Int) {
        // instantiate new view controller
        let newViewController = stepClasses[stepNumber].instantiateFromNib()
        addChildViewController(newViewController)
        newViewController.didMoveToParentViewController(self)
        newViewController.view.frame = containerView.bounds
        containerView.addSubview(newViewController.view)

        // slide to new view controller
        if let currentViewController = currentStepViewController {
            currentViewController.view.removeFromSuperview()
            currentViewController.willMoveToParentViewController(nil)
            currentViewController.removeFromParentViewController()
            
            // animate
            let transition = CATransition()
            transition.type = kCATransitionReveal
            transition.subtype = kCATransitionFromRight
            transition.duration = VisualFactory.Metrics.defaultAnimationDuration
            self.containerView.layer.addAnimation(transition, forKey: nil)
        }
        
        // retain new view controller
        currentStepViewController = newViewController
        
        // update view
        updateView()
        
        // update current step
        currentStepNumber = stepNumber
    }
    
    //MARK: /Users/nicolas/devel/ledger-wallet-ios/ledger-wallet-ios/views/ActionBarView.swiftInterface
    
    override func updateView() {
        super.updateView()
        
        navigationItem.rightBarButtonItem?.customView?.hidden = !currentStepViewController!.finalizesFlow
        stepNumberLabel.text = "\(currentStepViewController!.stepNumber)."
        stepIndicationLabel.text = currentStepViewController!.stepIndication
    }
    
    override func configureView() {
        super.configureView()
        
        navigateToNextStep()
    }
    
    //MARK: Layout
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        currentStepViewController?.view.frame = containerView.bounds
    }
    
}
