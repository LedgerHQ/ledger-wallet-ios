//
//  KeyboardObserver.swift
//  ledger-wallet-ios
//
//  Created by Nicolas Bigot on 22/09/15.
//  Copyright © 2015 Ledger. All rights reserved.
//

import Foundation

protocol KeyboardObservable: class {

    func keyboardWillShow(notification: NSNotification)
    func keyboardWillHide(notification: NSNotification)

}

extension KeyboardObservable {

    func observeKeyboardNotifications(observe: Bool) {
        if (observe) {
            NSNotificationCenter.defaultCenter().addObserver(self, selector: "keyboardWillShow:", name: UIKeyboardWillShowNotification, object: nil)
            NSNotificationCenter.defaultCenter().addObserver(self, selector: "keyboardWillHide:", name: UIKeyboardWillHideNotification, object: nil)
        }
        else {
            NSNotificationCenter.defaultCenter().removeObserver(self, name: UIKeyboardWillShowNotification, object: nil)
            NSNotificationCenter.defaultCenter().removeObserver(self, name: UIKeyboardWillHideNotification, object: nil)
        }
    }
    
    func valueFromKeyboardNotification(notification: NSNotification, forKey key: String) -> AnyObject {
        return notification.userInfo![key]!
    }
    
}