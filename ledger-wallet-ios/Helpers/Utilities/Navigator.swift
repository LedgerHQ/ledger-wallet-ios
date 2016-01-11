//
//  Navigation.swift
//  ledger-wallet-ios
//
//  Created by Nicolas Bigot on 10/02/2015.
//  Copyright (c) 2015 Ledger. All rights reserved.
//

import UIKit

final class Navigator {
    
    // MARK: Utilities
    
    class func embedViewController(viewController: UIViewController) -> BaseNavigationController {
        let navigationController = BaseNavigationController.instantiateFromStoryboard(StoryboardFactory.storyboardWithIdentifier(.Main))
        navigationController.viewControllers = [viewController]
        return navigationController
    }
    
}

//// MARK: - Pairing navigation
//
//extension Navigator {
//    
//    final class Pairing {
//        
//        class func presentAddViewController(fromViewController fromViewController: UIViewController, delegate: PairingAddViewControllerDelegate) {
//            let viewController = PairingAddViewController.instantiateFromStoryboard(StoryboardFactory.storyboardWithIdentifier(.Pairing))
//            let navigationController = Navigator.embedViewController(viewController)
//            viewController.delegate = delegate
//            fromViewController.presentViewController(navigationController, animated: true, completion: nil)
//        }
//        
//        class func presentListViewController(fromViewController fromViewController: UIViewController) {
//            let viewController = PairingListViewController.instantiateFromStoryboard(StoryboardFactory.storyboardWithIdentifier(.Pairing))
//            let navigationController = Navigator.embedViewController(viewController)
//            fromViewController.presentViewController(navigationController, animated: true, completion: nil)
//        }
//        
//    }
//    
//}