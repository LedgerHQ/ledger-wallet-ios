//
//  Log.swift
//  ledger-wallet-ios
//
//  Created by Nicolas Bigot on 21/07/15.
//  Copyright (c) 2015 Ledger. All rights reserved.
//

import Foundation

func console<T: CustomStringConvertible>(value: T) {
    console(value.description)
}

func console(value: String) {
    if NSThread.currentThread() == NSThread.mainThread() {
        print(value)
    }
    else {
        dispatchAsyncOnMainQueue() {
            print(value)
        }
    }
}