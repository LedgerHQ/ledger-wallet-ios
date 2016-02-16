//
//  RemoteDeviceAPIQueue.swift
//  ledger-wallet-ios
//
//  Created by Nicolas Bigot on 10/02/2016.
//  Copyright © 2016 Ledger. All rights reserved.
//

import Foundation

protocol RemoteDeviceAPIQueueDelegate: class {
    
    func deviceAPIQueue(deviceAPIQueue: RemoteDeviceAPIQueue, didTimeoutTask: RemoteDeviceAPITaskType)
    
}

final class RemoteDeviceAPIQueue {
    
    weak var delegate: RemoteDeviceAPIQueueDelegate?
    private var busy = false
    private var timeoutTimer: DispatchTimer?
    private var currentTask: RemoteDeviceAPITaskType?
    private var pendingTasks: [RemoteDeviceAPITaskType] = []
    private let delegateQueue: NSOperationQueue
    private let workingQueue = NSOperationQueue(name: "RemoteDeviceAPIQueue", maxConcurrentOperationCount: 1)
    
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
            
            // start timeout timer
            if task.timeoutInterval > 0 {
                strongSelf.startTimeoutTimerWithInterval(task.timeoutInterval)
            }
            
            // execute task
            task.run() { [weak self] in
                guard let strongSelf = self else { return }
                
                strongSelf.currentTask = nil
                strongSelf.stopTimeoutTimer()
                strongSelf.processNextPendingTask()
            }
        }
    }
    
    // MARK: Events management
    
    func handleReceivedAPDU(APDU: RemoteAPDU) {
        workingQueue.addOperationWithBlock() { [weak self] in
            guard let strongSelf = self else { return }
            guard strongSelf.busy else { return }
            
            strongSelf.currentTask?.receiveAPDU(APDU)
        }
    }
    
    func handleSentAPDU(APDU: RemoteAPDU) {
        workingQueue.addOperationWithBlock() { [weak self] in
            guard let strongSelf = self else { return }
            guard strongSelf.busy else { return }
            
            strongSelf.currentTask?.didSendAPDU(APDU)
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
    
    init(delegateQueue: NSOperationQueue) {
        self.delegateQueue = delegateQueue
        self.workingQueue.underlyingQueue = dispatchSerialQueueWithName(dispatchQueueNameForIdentifier("RemoteDeviceAPIQueue"))
    }
    
    deinit {
        handleError(.CancelledTask)
        cancelAllTasks(cancelPendingTasks: true)
    }
    
}


// MARK: - Timeout management

extension RemoteDeviceAPIQueue {
    
    private func startTimeoutTimerWithInterval(interval: Double) {
        guard interval > 0 else { return }
        guard let queue = workingQueue.underlyingQueue else { return }
        
        timeoutTimer = DispatchTimer.scheduledTimerWithTimeInterval(milliseconds: UInt(interval * 1000), queue: queue, repeats: false) { [weak self] _ in
            guard let strongSelf = self else { return }
            guard strongSelf.busy else { return }
            guard let task = strongSelf.currentTask else { return }
            
            strongSelf.delegateQueue.addOperationWithBlock() { [weak self] in
                guard let strongSelf = self else { return }
                
                strongSelf.delegate?.deviceAPIQueue(strongSelf, didTimeoutTask: task)
            }
            task.completeWithError(.TransferTimeout)
        }
    }
    
    private func stopTimeoutTimer() {
        timeoutTimer?.invalidate()
        timeoutTimer = nil
    }
    
}