//
//  Log.swift
//  ledger-wallet-ios
//
//  Created by Nicolas Bigot on 21/07/15.
//  Copyright (c) 2015 Ledger. All rights reserved.
//

import Foundation

func console(value: Any) {
    dispatchAsyncOnMainQueue() {
        print(value)
    }
}