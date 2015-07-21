//
//  Log.swift
//  ledger-wallet-ios
//
//  Created by Nicolas Bigot on 21/07/15.
//  Copyright (c) 2015 Ledger. All rights reserved.
//

import Foundation

func console<T: Printable>(value: T) {
    console(value.description)
}

func console(value: String) {
    dispatchAsyncOnMainQueue() {
        println(value)
    }
}