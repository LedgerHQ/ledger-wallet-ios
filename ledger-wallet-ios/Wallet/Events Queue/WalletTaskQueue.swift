//
//  WalletTaskQueue.swift
//  ledger-wallet-ios
//
//  Created by Nicolas Bigot on 12/01/2016.
//  Copyright © 2016 Ledger. All rights reserved.
//

import Foundation

protocol WalletTaskQueueDelegate: class {
    
    func taskQueueDidStartDequeingTasks(taskQueue: WalletTaskQueue)
    func taskQueueDidStopDequeingTasks(taskQueue: WalletTaskQueue)
    
}

final class WalletTaskQueue {
    
    weak var delegate: WalletTaskQueueDelegate?
    private var pendingTasks: [WalletTaskType] = []
    private var busy = false
    private let delegateQueue: NSOperationQueue
    private let workingQueue = NSOperationQueue(name: dispatchQueueNameForIdentifier("WalletTaskQueue"), maxConcurrentOperationCount: 1)
    
    // MARK: Tasks management
    
    func enqueueTasks(tasks: [WalletTaskType]) {
        guard tasks.count > 0 else { return }
        
        workingQueue.addOperationWithBlock() { [weak self] in
            guard let strongSelf = self else { return }
            
            // enqueue tasks
            strongSelf.pendingTasks.appendContentsOf(tasks)
            
            // process next pending transaction if not busy
            if !strongSelf.busy {
                strongSelf.initiateDequeueProcess()
            }
        }
    }
    
    private func processNextPendingTask() {
        workingQueue.addOperationWithBlock() { [weak self] in
            guard let strongSelf = self else { return }
            
            // pop first task
            guard let task = strongSelf.pendingTasks.first else {
                strongSelf.terminateDequeueProcess()
                return
            }
            strongSelf.pendingTasks.removeFirst()
        
            // execute task
            task.process() { [weak self] in
                guard let strongSelf = self else { return }
                
                strongSelf.processNextPendingTask()
            }
        }
    }
    
    // MARK: Dequeue lifecycle
    
    private func initiateDequeueProcess() {
        busy = true
        notifyStartOfDequeuingTasks()
        processNextPendingTask()
    }
    
    private func terminateDequeueProcess() {
        busy = false
        notifyStopOfDequeuingTasks()
    }
    
    // MARK: Initialization
    
    init(delegateQueue: NSOperationQueue) {
        self.delegateQueue = delegateQueue
    }
    
}

// MARK: - Delegate management

private extension WalletTaskQueue {
    
    private func notifyStartOfDequeuingTasks() {
        delegateQueue.addOperationWithBlock() { [weak self] in
            guard let strongSelf = self else { return }
            strongSelf.delegate?.taskQueueDidStartDequeingTasks(strongSelf)
        }
    }
    
    private func notifyStopOfDequeuingTasks() {
        delegateQueue.addOperationWithBlock() { [weak self] in
            guard let strongSelf = self else { return }
            strongSelf.delegate?.taskQueueDidStopDequeingTasks(strongSelf)
        }
    }
    
}