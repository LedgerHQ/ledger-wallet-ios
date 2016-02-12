//
//  RemoteDeviceAPIQueue.swift
//  ledger-wallet-ios
//
//  Created by Nicolas Bigot on 10/02/2016.
//  Copyright © 2016 Ledger. All rights reserved.
//

import Foundation

final class RemoteDeviceAPIQueue {
    
    private var busy = false
    private var currentTask: RemoteDeviceAPITaskType?
    private var pendingTasks: [RemoteDeviceAPITaskType] = []
    private var workingQueue = NSOperationQueue(name: "RemoteDeviceAPIQueue", maxConcurrentOperationCount: 1)
    
    // MARK: Tasks management
    
    var activeTask: RemoteDeviceAPITaskType? {
        var task: RemoteDeviceAPITaskType?
        workingQueue.addOperationWithBlock() { [weak self] in
            guard let strongSelf = self else { return }
            
            task = strongSelf.currentTask
        }
        workingQueue.waitUntilAllOperationsAreFinished()
        return task
    }
    
    func enqueueTask(task: RemoteDeviceAPITaskType) {
        workingQueue.addOperationWithBlock() { [weak self] in
            guard let strongSelf = self else { return }
            
            // enqueue task
            strongSelf.pendingTasks.append(task)
            
            // process next pending task if not busy
            strongSelf.processNextPendingTaskIfNotBusy()
        }
    }
    
    func cancelAllTasks(cancelPendingTasks cancelPendingTasks: Bool) {
        workingQueue.addOperationWithBlock() { [weak self] in
            guard let strongSelf = self else { return }
            
            if cancelPendingTasks {
                strongSelf.pendingTasks.forEach({ $0.cancel() })
            }
            strongSelf.pendingTasks.removeAll()
        }
        workingQueue.waitUntilAllOperationsAreFinished()
    }
    
    private func processNextPendingTaskIfNotBusy() {
        // process next pending task if not busy
        if !busy {
            busy = true
            processNextPendingTask()
        }
    }
    
    private func processNextPendingTask() {
        workingQueue.addOperationWithBlock() { [weak self] in
            guard let strongSelf = self else { return }
            
            // pop first task
            guard let task = strongSelf.pendingTasks.first else {
                strongSelf.busy = false
                strongSelf.currentTask = nil
                return
            }
            strongSelf.currentTask = task
            strongSelf.pendingTasks.removeFirst()
            
            // execute task
            task.run() { [weak self] in
                guard let strongSelf = self else { return }
                
                strongSelf.processNextPendingTask()
            }
        }
    }
    
    // MARK: Events management
    
    func handleReceivedAPDU(APDU: RemoteAPDU) {
        workingQueue.addOperationWithBlock() { [weak self] in
            guard let strongSelf = self else { return }
            guard strongSelf.busy else { return }
            
            strongSelf.currentTask?.processReceivedAPDU(APDU)
        }
    }
    
    func handleSentAPDU(APDU: RemoteAPDU) {
        workingQueue.addOperationWithBlock() { [weak self] in
            guard let strongSelf = self else { return }
            guard strongSelf.busy else { return }
            
            strongSelf.currentTask?.handleSentAPDU(APDU)
        }
    }
    
    func handleError(error: RemoteDeviceError) {
        workingQueue.addOperationWithBlock() { [weak self] in
            guard let strongSelf = self else { return }
            guard strongSelf.busy else { return }
            
            strongSelf.currentTask?.completeWithError(error)
        }
    }
    
    // MARK: Initialization
    
    deinit {
        workingQueue.cancelAllOperations()
        cancelAllTasks(cancelPendingTasks: true)
    }
    
}