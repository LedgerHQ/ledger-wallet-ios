//
//  CompletionResultable.swift
//  ledger-wallet-ios
//
//  Created by Nicolas Bigot on 23/09/15.
//  Copyright © 2015 Ledger. All rights reserved.
//

import Foundation

protocol CompletionResultable {
    
    func complete()
    func cancel()
    
}

extension CompletionResultable {
    
    func complete() {}
    func cancel() {}
    
}