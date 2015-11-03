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
        
        private var systemAlertControllerStyle: UIAlertControllerStyle {
            switch self {
            case .ActionSheet: return .ActionSheet
            case .Alert: return .Alert
            }
        }
    }
    
    let style: Style
    let title: String?
    let message: String?
    private var actions: [AlertAction] = []
    private var alertController: UIAlertController! = nil
    private static var sharedControllers: [UIAlertView: AlertController] = [:]
    
    func addAction(action: AlertAction) {
        actions.append(action)
    }
    
    func presentFromViewController(viewController: BaseViewController, animated: Bool) {
        alertController = UIAlertController(title: title, message: message, preferredStyle: style.systemAlertControllerStyle)
        for action in actions {
            let alertAction = UIAlertAction(title: action.title, style: action.style.systemAlertActionStyle) { handler in
                action.handler?(action)
            }
            alertController.addAction(alertAction)
        }
        viewController.presentViewController(alertController, animated: animated, completion: nil)
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

class AlertAction {
    
    enum Style {
        case Default
        case Destructive
        case Cancel
        
        private var systemAlertActionStyle: UIAlertActionStyle {
            switch self {
            case .Cancel: return .Cancel
            case .Destructive: return .Destructive
            case .Default: return .Default
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