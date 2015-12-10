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

func dispatchSerialQueueWithName(name: String) -> dispatch_queue_t {
    return dispatch_queue_create(name, DISPATCH_QUEUE_SERIAL)
}

func dispatchConcurrentQueueWithName(name: String) -> dispatch_queue_t {
    return dispatch_queue_create(name, DISPATCH_QUEUE_CONCURRENT)
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

func dispatchAsyncOnGlobalQueueWithPriority(priority: Int, block: dispatch_block_t) {
    dispatch_async(dispatchGlobalQueueWithPriority(priority), block)
}

func dispatchSyncOnGlobalQueueWithPriority(priority: Int, block: dispatch_block_t) {
    dispatch_sync(dispatchGlobalQueueWithPriority(priority), block)
}

func dispatchAfterOnMainQueue(delay: Double, block: dispatch_block_t) {
    dispatchAfter(delay, queue: dispatchMainQueue(), block: block)
}

func dispatchAfter(delay: Double, queue: dispatch_queue_t, block: dispatch_block_t) {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, Int64(delay * Double(NSEC_PER_SEC))), queue, block)
}