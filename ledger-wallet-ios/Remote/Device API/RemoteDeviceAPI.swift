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
    private let queue = RemoteDeviceAPIQueue()
    private var firmwareVersion: RemoteDeviceFirmwareVersion?
    private let workingQueue = NSOperationQueue(name: "RemoteDeviceAPI", maxConcurrentOperationCount: 1)
    
    // MARK: API management
    
    func getFirmwareVersion(completionQueue: NSOperationQueue, completion: RemoteDeviceAPIGetFirmwareVersionTask.CompletionBlock) {
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
                strongSelf.queue.enqueueTask(task)
            }
        }
    }
    
    func checkAttestation(completionQueue: NSOperationQueue, completion: RemoteDeviceAPICheckAttestationTask.CompletionBlock) {
        workingQueue.addOperationWithBlock() { [weak self] in
            guard let strongSelf = self else { return }

            let task = RemoteDeviceAPICheckAttestationTask(devicesCoordinator: strongSelf.devicesCoordinator, servicesProvider: strongSelf.servicesProvider, completionQueue: completionQueue, completion: completion)
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
    }
    
    deinit {
        workingQueue.addOperationWithBlock() { [weak self] in
            self?.queue.cancelAllTasks(cancelPendingTasks: true)
        }
        workingQueue.waitUntilAllOperationsAreFinished()
    }
    
}