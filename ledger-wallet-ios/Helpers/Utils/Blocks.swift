//
//  Blocks.swift
//  ledger-wallet-ios
//
//  Created by Nicolas Bigot on 22/01/2015.
//  Copyright (c) 2015 Ledger. All rights reserved.
//

import Foundation

func dispatchMainQueue() -> dispatch_queue_t {
    return dispatch_get_main_queue()
}

func dispatchGlobalQueueWithPriority(priority: Int) -> dispatch_queue_t {
    return dispatch_get_global_queue(priority, 0)
}

func dispatchAsyncOnMainQueue(block: () -> Void) {
    dispatch_async(dispatchMainQueue(), block)
}

func dispatchSyncOnMainQueue(block: () -> Void) {
    dispatch_sync(dispatchMainQueue(), block)
}

func delayOnMainQueueAfter(delay: Double, block: () -> Void) {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, Int64(delay * Double(NSEC_PER_SEC))), dispatchMainQueue(), block)
}

func dispatchAsyncOnGlobalQueueWithPriority(priority: Int, block: () -> Void) {
    dispatch_async(dispatchGlobalQueueWithPriority(priority), block)
}

func dispatchSyncOnGlobalQueueWithPriority(priority: Int, block: () -> Void) {
    dispatch_sync(dispatchGlobalQueueWithPriority(priority), block)
}