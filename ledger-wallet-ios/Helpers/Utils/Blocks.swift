//
//  Blocks.swift
//  ledger-wallet-ios
//
//  Created by Nicolas Bigot on 22/01/2015.
//  Copyright (c) 2015 Ledger. All rights reserved.
//

import Foundation

func dispatchQueueNameForIdentifier(identifier: String) -> String {
    return ApplicationManager.sharedInstance.bundleIdentifier + "." + identifier
}

func dispatchMainQueue() -> dispatch_queue_t {
    return dispatch_get_main_queue()
}

func dispatchGlobalQueueWithPriority(priority: Int) -> dispatch_queue_t {
    return dispatch_get_global_queue(priority, 0)
}

func dispatchAsyncOnMainQueue(block: dispatch_block_t) {
    dispatch_async(dispatchMainQueue(), block)
}

func dispatchSyncOnMainQueue(block: dispatch_block_t) {
    dispatch_sync(dispatchMainQueue(), block)
}

func dispatchAsyncOnQueue(queue: dispatch_queue_t, block: dispatch_block_t) {
    dispatch_async(queue, block)
}

func dispatchSyncOnQueue(queue: dispatch_queue_t, block: dispatch_block_t) {
    dispatch_sync(queue, block)
}

func dispatchAfterOnMainQueue(delay: Double, block: dispatch_block_t) {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, Int64(delay * Double(NSEC_PER_SEC))), dispatchMainQueue(), block)
}

func dispatchAsyncOnGlobalQueueWithPriority(priority: Int, block: dispatch_block_t) {
    dispatch_async(dispatchGlobalQueueWithPriority(priority), block)
}

func dispatchSyncOnGlobalQueueWithPriority(priority: Int, block: dispatch_block_t) {
    dispatch_sync(dispatchGlobalQueueWithPriority(priority), block)
}