//
//  Navigation.swift
//  ledger-wallet-ios
//
//  Created by Nicolas Bigot on 10/02/2015.
//  Copyright (c) 2015 Ledger. All rights reserved.
//

import UIKit

class Navigator {
    
    // MARK: - Utilities
    
    class func viewControllerOfClass<T: BaseViewController>(viewControllerClass: T.Type, storyboard: UIStoryboard) -> T {
        let viewController = viewControllerClass.instantiateFromStoryboard(storyboard) as T
        return viewController
    }
    
    class func embedViewControllerInNavigationController<T: BaseViewController>(viewController: T) -> BaseNavigationController {
        let navigationController = BaseNavigationController.new()
        navigationController.viewControllers = [viewController]
        return navigationController
    }
    
    // MARK: - Presentation
    
    class func presentViewControllerOfClass<T: BaseViewController>(viewControllerClass: T.Type, fromViewController: T, animated: Bool = true, completion: (() -> Void)? = nil, configuration: ((T) -> Void)? = nil) {
        if let storyboard = fromViewController.rootStoryboard {
            let viewController = viewControllerOfClass(viewControllerClass, storyboard: storyboard)
            configuration?(viewController)
            fromViewController.presentViewController(viewController, animated: animated, completion: completion)
        }
    }
    
    class func presentEmbeddedViewControllerOfClass<T: BaseViewController>(viewControllerClass: T.Type, fromViewController: T, animated: Bool = true, completion: (() -> Void)? = nil, configuration: ((T, BaseNavigationController) -> Void)? = nil) {
        if let storyboard = fromViewController.rootStoryboard {
            let viewController = viewControllerOfClass(viewControllerClass, storyboard: storyboard)
            let navigationController = embedViewControllerInNavigationController(viewController)
            configuration?(viewController, navigationController)
            fromViewController.presentViewController(navigationController, animated: animated, completion: completion)
        }
    }
    
    class Pairing {
        
        // MARK: - Pairing navigation
        
        class func presentAddViewController(#fromViewController: BaseViewController, delegate: PairingAddViewControllerDelegate) {
            Navigator.presentEmbeddedViewControllerOfClass(PairingAddViewController.self, fromViewController: fromViewController, configuration: { viewController, navigationController in
                (viewController as! PairingAddViewController).delegate = delegate
            })
        }
        
        class func presentListViewController(#fromViewController: BaseViewController) {
            Navigator.presentEmbeddedViewControllerOfClass(PairingListViewController.self, fromViewController: fromViewController)
        }
        
    }
}