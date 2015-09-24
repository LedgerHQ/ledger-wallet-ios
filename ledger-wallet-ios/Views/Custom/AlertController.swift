//
//  AlertController.swift
//  ledger-wallet-ios
//
//  Created by Nicolas Bigot on 16/02/2015.
//  Copyright (c) 2015 Ledger. All rights reserved.
//

import UIKit

final class AlertController: NSObject {
    
    enum Style {
        case Alert
        case ActionSheet
        
        @available(iOS 8.0, *)
        var systemAlertControllerStyle: UIAlertControllerStyle {
            switch self {
            case .ActionSheet: return .ActionSheet
            default: return .Alert
            }
        }
    }
    
    let style: Style
    let title: String?
    let message: String?
    private var actions: [AlertAction] = []
    private var alertController: UIViewController! = nil
    private var alertView: UIAlertView! = nil
    private static var sharedControllers: [UIAlertView: AlertController] = [:]
    
    func addAction(action: AlertAction) {
        actions.append(action)
    }
    
    func presentFromViewController(viewController: BaseViewController, animated: Bool) {
        if #available(iOS 8.0, *) {
            alertController = UIAlertController(title: title, message: message, preferredStyle: style.systemAlertControllerStyle)
            let localAlertController = alertController as! UIAlertController
            for action in actions {
                let alertAction = UIAlertAction(title: action.title, style: action.style.systemAlertActionStyle) { handler in
                    action.handler?(action)
                }
                localAlertController.addAction(alertAction)
            }
            viewController.presentViewController(localAlertController, animated: animated, completion: nil)
        }
        else {
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
    
    // MARK - Initialization
    
    init(title: String?, message: String?) {
        self.title = title
        self.message = message
        self.style = .Alert
    }
   
    convenience init(alert: String) {
        self.init(title: nil, message: alert)
        addAction(AlertAction(title: localizedString("OK"), style: .Default, handler: nil))
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

class AlertAction {
    
    enum Style {
        case Default
        case Destructive
        case Cancel
        
        @available(iOS 8.0, *)
        var systemAlertActionStyle: UIAlertActionStyle {
            switch self {
            case .Cancel: return .Cancel
            case .Destructive: return .Destructive
            default: return .Default
            }
        }
    }
    
    typealias Handler = (AlertAction) -> Void
    let title: String
    let style: Style
    private let handler: Handler?
    
    init(title: String, style: Style, handler: Handler?) {
        self.title = title
        self.style = style
        self.handler = handler
    }
    
}