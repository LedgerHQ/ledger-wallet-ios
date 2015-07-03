//
//  Blocks.swift
//  ledger-wallet-ios
//
//  Created by Nicolas Bigot on 22/01/2015.
//  Copyright (c) 2015 Ledger. All rights reserved.
//

import Foundation

func deferOnMainQueue(closure: () -> ()) {
    delayOnMainQueue(0, closure)
}

func delayOnMainQueue(delay: Double, closure: () -> ()) {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, Int64(delay * Double(NSEC_PER_SEC))), dispatch_get_main_queue(), closure)
}

func dispatchAsyncOnMainQueue(closure: () -> ()) {
    dispatch_async(dispatch_get_main_queue(), closure)
}

func dispatchSyncOnMainQueue(closure: () -> ()) {
    dispatch_sync(dispatch_get_main_queue(), closure)
}