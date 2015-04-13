//
//  AlertController.swift
//  ledger-wallet-ios
//
//  Created by Nicolas Bigot on 16/02/2015.
//  Copyright (c) 2015 Ledger. All rights reserved.
//

import UIKit

class AlertController: NSObject {
    
    enum Style {
        case Alert
        case ActionSheet
    }
    
    class Action {
        
        enum Style {
            case Default
            case Destructive
            case Cancel
        }
        
        typealias Handler = (Action) -> Void
        let title: String
        let style: Style
        private let handler: Handler?
        
        init(title: String, style: Style, handler: Handler?) {
            self.title = title
            self.style = style
            self.handler = handler
        }
        
        private class func UIAlertActionForStyle(style: Style) -> UIAlertActionStyle {
            switch style {
            case .Cancel: return .Cancel
            case .Destructive: return .Destructive
            default: return .Default
            }
        }

    }
    
    let style: Style
    let title: String?
    let message: String?
    private var actions: [Action] = []
    private var alertController: UIAlertController! = nil
    private var alertView: UIAlertView! = nil
    private static var sharedControllers: [UIAlertView: AlertController] = [:]
    
    class func usesSystemAlertController() -> Bool {
        return NSClassFromString("UIAlertController") != nil
    }
    
    init(title: String?, message: String?) {
        self.title = title
        self.message = message
        self.style = .Alert
    }
    
    func addAction(action: Action) {
        actions.append(action)
    }
    
    func presentFromViewController(viewController: BaseViewController, animated: Bool) {
        if AlertController.usesSystemAlertController() {
            // ios >= 8
            alertController = UIAlertController(title: title, message: message, preferredStyle: AlertController.UIAlertControllerStyleForStyle(style))
            for action in actions {
                let alertAction = UIAlertAction(title: action.title, style: Action.UIAlertActionForStyle(action.style), handler: action.handler == nil ? nil : { _ in
                    (action.handler?(action))!
                })
                alertController.addAction(alertAction)
            }
            viewController.presentViewController(alertController, animated: animated, completion: nil)
        }
        else {
            // ios < 8
            alertView = UIAlertView()
            alertView.delegate = self
            alertView.title = title ?? ""
            alertView.message = message
            alertView.alertViewStyle = .Default
            for action in actions {
                alertView.addButtonWithTitle(action.title)
            }
            alertView.show()
            
            // add to shared pool
            AlertController.sharedControllers[alertView] = self
        }
    }
    
    private class func UIAlertControllerStyleForStyle(style: Style) -> UIAlertControllerStyle {
        switch style {
        case .ActionSheet: return .ActionSheet
        default: return .Alert
        }
    }
    
}

extension AlertController: UIAlertViewDelegate {
    
    // MARK: - UIAlertView delegate
    
    func alertView(alertView: UIAlertView, clickedButtonAtIndex buttonIndex: Int) {
        // call handler
        let alertController = AlertController.sharedControllers[alertView]
        let action = alertController?.actions[buttonIndex]
        action?.handler?(action!)
        
        // remove from shared pool
        AlertController.sharedControllers[alertView] = nil
    }
    
}
