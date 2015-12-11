//
//  MessageDialogViewController.swift
//  ledger-wallet-ios
//
//  Created by Nicolas Bigot on 30/10/2015.
//  Copyright © 2015 Ledger. All rights reserved.
//

import Foundation

enum MessageDialogActionType {
    
    case Positive
    case Neutral
    
    private func allureName() -> String {
        switch self {
        case .Positive: return "green"
        case .Neutral: return "grey"
        }
    }
    
}

final class MessageDialogAction {
    
    let type: MessageDialogActionType
    let title: String
    private let handler: (MessageDialogAction) -> Void
    
    init(type: MessageDialogActionType, title: String, handler: (MessageDialogAction) -> Void) {
        self.type = type
        self.title = title
        self.handler = handler
    }
    
    private dynamic func fire() {
        handler(self)
    }
    
}

enum MessageDialogType: String {
    
    case Error
    case Success
    case Confirmation
    
    private func imageName() -> String {
        return "icon_" + self.rawValue.lowercaseString
    }
    
}

class MessageDialogViewController: DialogViewController {

    var type: MessageDialogType = .Success
    var localizedTitle: String = ""
    var localizedMessage: String = ""
    private(set) lazy var actions: [MessageDialogAction] = []
    
    @IBOutlet private weak var iconImageView: UIImageView!
    @IBOutlet private weak var titleLabel: Label!
    @IBOutlet private weak var messageLabel: Label!
    @IBOutlet private weak var buttonsContainerView: UIView!
    
    // MARK: Interface
    
    override func configureView() {
        super.configureView()
        
        iconImageView?.image = UIImage(named: type.imageName())
        titleLabel?.text = localizedTitle
        messageLabel?.text = localizedMessage
        synthesizeActions()
    }
    
    // MARK: Actions
    
    func addAction(action: MessageDialogAction) {
        actions.append(action)
    }
    
    private func synthesizeActions() {
        var previousButton: UIButton? = nil
        for action in actions {
            // configure button
            let button = RoundedButton(type: .Custom)
            button.translatesAutoresizingMaskIntoConstraints = false
            button.setTitle(action.title, forState: .Normal)
            button.allure = action.type.allureName()
            button.addTarget(action, action: "fire", forControlEvents: .TouchUpInside)
            buttonsContainerView?.addSubview(button)
            
            // add constraints
            buttonsContainerView?.addConstraint(NSLayoutConstraint(
                item: button, attribute: .Top, relatedBy: .Equal,
                toItem: buttonsContainerView, attribute: .Top,
                multiplier: 1.0, constant: 0.0)
            )
            buttonsContainerView?.addConstraint(NSLayoutConstraint(
                item: button, attribute: .Bottom, relatedBy: .Equal,
                toItem: buttonsContainerView, attribute: .Bottom,
                multiplier: 1.0, constant: 0.0)
            )
            if let previousButton = previousButton {
                buttonsContainerView.addConstraint(NSLayoutConstraint(
                    item: button, attribute: .Leading, relatedBy: .Equal,
                    toItem: previousButton, attribute: .Trailing,
                    multiplier: 1.0, constant: VisualFactory.Metrics.Padding.VerySmall)
                )
            }
            else {
                buttonsContainerView.addConstraint(NSLayoutConstraint(
                    item: button, attribute: .Leading, relatedBy: .Equal,
                    toItem: buttonsContainerView, attribute: .Leading,
                    multiplier: 1.0, constant: 0.0)
                )
            }
            if actions.last === action {
                buttonsContainerView?.addConstraint(NSLayoutConstraint(
                    item: button, attribute: .Trailing, relatedBy: .Equal,
                    toItem: buttonsContainerView, attribute: .Trailing,
                    multiplier: 1.0, constant: 0.0)
                )
            }
            previousButton = button
        }
    }

}