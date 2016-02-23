//
//  ApplicationTabBarController.swift
//  ledger-wallet-ios
//
//  Created by Nicolas Bigot on 19/02/2016.
//  Copyright © 2016 Ledger. All rights reserved.
//

import Foundation

final class ApplicationTabBarController: UITabBarController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        dispatchAfterOnMainQueue(0.5) {
            let completeBlock: () -> Bool = {
                if let context = ApplicationContextManager.sharedInstance.getActiveContext(), viewControllers = self.viewControllers {
                    for viewController in viewControllers where viewController is ApplicationNavigationController && (viewController as! ApplicationNavigationController).topViewController is ApplicationViewController {
                        ((viewController as! ApplicationNavigationController).topViewController as! ApplicationViewController).context = context
                    }
                    return true
                }
                return false
            }
            
            if !completeBlock() {
                let remoteViewController = ApplicationRemoteDeviceViewController.instantiateFromMainStoryboard()
                remoteViewController.deviceCommunicator = ApplicationContextManager.sharedInstance.vendRemoteDeviceCommunicator()
                remoteViewController.completionBlock = { success, deviceCommunicator, identifier in
                    guard let identifier = identifier, deviceCommunicator = deviceCommunicator where success else { return }
                    guard ApplicationContextManager.sharedInstance.persistActiveContext(identifier, deviceCommunicator: deviceCommunicator) else { return }
                    guard completeBlock() else { return }
                }
                self.presentViewController(remoteViewController, animated: true, completion: nil)
            }
        }
    
    }
    
}