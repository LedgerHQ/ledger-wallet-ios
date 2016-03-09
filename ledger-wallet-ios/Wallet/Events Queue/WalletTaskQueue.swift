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
    func taskQueue(taskQueue: WalletTaskQueue, willProcessTask task: WalletTaskType)
    func taskQueue(taskQueue: WalletTaskQueue, didProcessTask task: WalletTaskType)
    
}

final class WalletTaskQueue {
    
    weak var delegate: WalletTaskQueueDelegate?
    private var pendingTasks: [WalletTaskType] = []
    private var busy = false
    private let delegateQueue: NSOperationQueue
    private let workingQueue = NSOperationQueue(name: "WalletTaskQueue", maxConcurrentOperationCount: 1)
    
    // MARK: Tasks management
    
    func enqueueTask(task: WalletTaskType) {
        enqueueTasks([task])
    }
    
    func enqueueTasks(tasks: [WalletTaskType]) {
        guard tasks.count > 0 else { return }
        
        workingQueue.addOperationWithBlock() { [weak self] in
            guard let strongSelf = self else { return }
            
            // enqueue tasks
            strongSelf.pendingTasks.appendContentsOf(tasks)
            
            // process next pending task if not busy
            strongSelf.processNextPendingTaskIfNotBusy()
        }
    }
    
    func cancelAllTasks() {
        workingQueue.cancelAllOperations()
        workingQueue.addOperationWithBlock() { [weak self] in
            guard let strongSelf = self else { return }

            strongSelf.pendingTasks.removeAll()
        }
        workingQueue.waitUntilAllOperationsAreFinished()
    }
    
    private func processNextPendingTaskIfNotBusy() {
        // process next pending task if not busy
        if !busy {
            initiateDequeueProcess()
            processNextPendingTask()
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
            strongSelf.notifyWillProcessTask(task)
            task.process(strongSelf.workingQueue) { [weak self] in
                guard let strongSelf = self else { return }
                
                strongSelf.notifyDidProcessTask(task)
                strongSelf.processNextPendingTask()
            }
        }
    }
    
    // MARK: Dequeue lifecycle
    
    private func initiateDequeueProcess() {
        busy = true
        notifyStartOfDequeuingTasks()
    }
    
    private func terminateDequeueProcess() {
        busy = false
        notifyStopOfDequeuingTasks()
    }
    
    // MARK: Initialization
    
    init(delegateQueue: NSOperationQueue) {
        self.delegateQueue = delegateQueue
    }
    
    deinit {
        cancelAllTasks()
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
    
    private func notifyWillProcessTask(task: WalletTaskType) {
        delegateQueue.addOperationWithBlock() { [weak self] in
            guard let strongSelf = self else { return }
            strongSelf.delegate?.taskQueue(strongSelf, willProcessTask: task)
        }
    }
    
    private func notifyDidProcessTask(task: WalletTaskType) {
        delegateQueue.addOperationWithBlock() { [weak self] in
            guard let strongSelf = self else { return }
            strongSelf.delegate?.taskQueue(strongSelf, didProcessTask: task)
        }
    }
    
}