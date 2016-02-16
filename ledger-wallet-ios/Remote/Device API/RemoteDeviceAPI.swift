//
//  RemoteDeviceAPI.swift
//  ledger-wallet-ios
//
//  Created by Nicolas Bigot on 08/02/2016.
//  Copyright © 2016 Ledger. All rights reserved.
//

import Foundation

final class RemoteDeviceAPI {
 
    private let devicesCoordinator: RemoteDevicesCoordinator
    private let servicesProvider: ServicesProviderType
    private let queue: RemoteDeviceAPIQueue
    private var firmwareVersion: RemoteDeviceFirmwareVersion?
    private var checkAttestion: (isAuthentic: Bool, isBeta: Bool)?
    private let workingQueue = NSOperationQueue(name: "RemoteDeviceAPI", maxConcurrentOperationCount: 1)
    
    // MARK: API management
    
    func getFirmwareVersion(timeoutInterval timeoutInterval: Double = 5.0, completionQueue: NSOperationQueue, completion: RemoteDeviceAPIGetFirmwareVersionTask.CompletionBlock) {
        workingQueue.addOperationWithBlock() { [weak self] in
            guard let strongSelf = self else { return }
            
            if let firmwareVersion = strongSelf.firmwareVersion {
                completionQueue.addOperationWithBlock() { completion(version: firmwareVersion, error: nil) }
            }
            else {
                let task = RemoteDeviceAPIGetFirmwareVersionTask(devicesCoordinator: strongSelf.devicesCoordinator, completionQueue: strongSelf.workingQueue) { [weak self] firmwareVersion, error in
                    guard let strongSelf = self else { return }

                    strongSelf.firmwareVersion = firmwareVersion
                    completionQueue.addOperationWithBlock() { completion(version: firmwareVersion, error: error) }
                }
                task.timeoutInterval = timeoutInterval
                strongSelf.queue.enqueueTask(task)
            }
        }
    }
    
    func checkAttestation(timeoutInterval timeoutInterval: Double = 5.0, completionQueue: NSOperationQueue, completion: RemoteDeviceAPICheckAttestationTask.CompletionBlock) {
        workingQueue.addOperationWithBlock() { [weak self] in
            guard let strongSelf = self else { return }
            
            if let checkAttestion = strongSelf.checkAttestion {
                completionQueue.addOperationWithBlock() { completion(isAuthentic: checkAttestion.isAuthentic, isBeta: checkAttestion.isBeta, error: nil) }
            }
            else {
                let task = RemoteDeviceAPICheckAttestationTask(devicesCoordinator: strongSelf.devicesCoordinator, servicesProvider: strongSelf.servicesProvider, completionQueue: strongSelf.workingQueue) { [weak self] isAuthentic, isBeta, error in
                    guard let strongSelf = self else { return }
                    
                    strongSelf.checkAttestion = (isAuthentic, isBeta)
                    completionQueue.addOperationWithBlock() { completion(isAuthentic: isAuthentic, isBeta: isBeta, error: error) }
                }
                task.timeoutInterval = timeoutInterval
                strongSelf.queue.enqueueTask(task)
            }
        }
    }
    
    func verifyPIN(PIN PIN: String?, timeoutInterval: Double = 5.0, completionQueue: NSOperationQueue, completion: RemoteDeviceAPIVerifyPINTask.CompletionBlock) {
        workingQueue.addOperationWithBlock() { [weak self] in
            guard let strongSelf = self else { return }
            
            let task = RemoteDeviceAPIVerifyPINTask(PIN: PIN, devicesCoordinator: strongSelf.devicesCoordinator, completionQueue: strongSelf.workingQueue, completion: completion)
            task.timeoutInterval = timeoutInterval
            strongSelf.queue.enqueueTask(task)
        }
    }
    
    func getPublicKey(path path: WalletAddressPath, timeoutInterval: Double = 5.0, completionQueue: NSOperationQueue, completion: RemoteDeviceAPIGetPublicKeyTask.CompletionBlock) {
        workingQueue.addOperationWithBlock() { [weak self] in
            guard let strongSelf = self else { return }
            
            let task = RemoteDeviceAPIGetPublicKeyTask(path: path, devicesCoordinator: strongSelf.devicesCoordinator, completionQueue: strongSelf.workingQueue, completion: completion)
            task.timeoutInterval = timeoutInterval
            strongSelf.queue.enqueueTask(task)
        }
    }
    
    // MARK: Events management
    
    func handleDidReceiveAPDU(APDU: RemoteAPDU, fromDevice device: RemoteDeviceType) {
        workingQueue.addOperationWithBlock() { [weak self] in
            guard let strongSelf = self else { return }

            strongSelf.queue.handleReceivedAPDU(APDU)
        }
    }
    
    func handleDidFailToReceiveAPDUFromDevice(device: RemoteDeviceType) {
        workingQueue.addOperationWithBlock() { [weak self] in
            guard let strongSelf = self else { return }
            
            strongSelf.queue.handleError(.UnableToRead)
        }
    }
    
    func handleDidSendAPDU(APDU: RemoteAPDU, toDevice device: RemoteDeviceType) {
        workingQueue.addOperationWithBlock() { [weak self] in
            guard let strongSelf = self else { return }
            
            strongSelf.queue.handleSentAPDU(APDU)
        }
    }
    
    func handleDidFailToSendAPDUToDevice(device: RemoteDeviceType) {
        workingQueue.addOperationWithBlock() { [weak self] in
            guard let strongSelf = self else { return }
            
            strongSelf.queue.handleError(.UnableToWrite)
        }
    }
    
    func handleDidDisconnectDevice(device: RemoteDeviceType, withError error: RemoteDeviceError?) {
        workingQueue.addOperationWithBlock() { [weak self] in
            guard let strongSelf = self else { return }
            
            let finalError = error ?? .CancelledTask
            strongSelf.queue.handleError(finalError)
            strongSelf.queue.cancelAllTasks(cancelPendingTasks: true)
        }
    }
    
    // MARK: Initialization
    
    init(devicesCoordinator: RemoteDevicesCoordinator, servicesProvider: ServicesProviderType) {
        self.devicesCoordinator = devicesCoordinator
        self.servicesProvider = servicesProvider
        self.queue = RemoteDeviceAPIQueue(delegateQueue: workingQueue)
        self.queue.delegate = self
    }
    
    deinit {
        workingQueue.addOperationWithBlock() { [weak self] in
            self?.queue.cancelAllTasks(cancelPendingTasks: true)
        }
        workingQueue.waitUntilAllOperationsAreFinished()
    }
    
}

// MARK: - RemoteDeviceAPIQueueDelegate

extension RemoteDeviceAPI: RemoteDeviceAPIQueueDelegate {
    
    func deviceAPIQueue(deviceAPIQueue: RemoteDeviceAPIQueue, didTimeoutTask: RemoteDeviceAPITaskType) {
        devicesCoordinator.abortCurrentTransfer()
    }
    
}