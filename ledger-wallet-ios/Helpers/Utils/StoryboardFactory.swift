//
//  StoryboardFactory.swift
//  ledger-wallet-ios
//
//  Created by Nicolas Bigot on 15/07/15.
//  Copyright (c) 2015 Ledger. All rights reserved.
//

import Foundation

class StoryboardFactory {
    
    enum StoryboardIdentifier: String {
        case Main
        case Pairing
    }
    
    private static var storyboards: [StoryboardIdentifier: UIStoryboard] = [:]
    
    // MARK: Storyboards management
    
    class func storyboardWithIdentifier(identifier: StoryboardIdentifier) -> UIStoryboard {
        if let storyboard = self.storyboards[identifier] {
            return storyboard
        }
        let storyboard = UIStoryboard(name: identifier.rawValue, bundle: nil)
        storyboards[identifier] = storyboard
        return storyboard
    }
    
    class func destroyStoryboards() {
        storyboards = [:]
    }
}