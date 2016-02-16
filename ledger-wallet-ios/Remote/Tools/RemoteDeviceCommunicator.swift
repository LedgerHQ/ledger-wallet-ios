//
//  RemoteDeviceCommunicator.swift
//  ledger-wallet-ios
//
//  Created by Nicolas Bigot on 09/02/2016.
//  Copyright © 2016 Ledger. All rights reserved.
//

import Foundation

final class RemoteDeviceCommunicator {
    
    private(set) var deviceAPI: RemoteDeviceAPI?
    private var passingAttestation: Bool?
    private var forcedDelegateError: RemoteDeviceError?
    private var scanHandlerQueue: NSOperationQueue?
    private var scanHandlerBlock: ScanHandlerBlock?
    private var connectionHandlerQueue: NSOperationQueue?
    private var connectionHandlerBlock: ConnectionHandlerBlock?
    private let devicesCoordinator: RemoteDevicesCoordinator
    private let servicesProvider: ServicesProviderType
    private let workingQueue = NSOperationQueue(name: "RemoteDeviceCommunicator", maxConcurrentOperationCount: 1)
    private let logger = Logger.sharedInstance(name: "RemoteDeviceCommunicator")
    
    // MARK: Initialization
    
    init(servicesProvider: ServicesProviderType) {
        self.servicesProvider = servicesProvider
        self.devicesCoordinator = RemoteDevicesCoordinator(servicesProvider: servicesProvider, delegateQueue: workingQueue)
        self.devicesCoordinator.delegate = self
    }
 
    deinit {
        workingQueue.cancelAllOperations()
        stopScanning()
        disconnect()
    }
    
}

// MARK: - Scan management

extension RemoteDeviceCommunicator {
    
    typealias ScanHandlerBlock = (device: RemoteDeviceType, isFound: Bool) -> Void
    
    var isScanning: Bool {
        var scanning = false
        workingQueue.addOperationWithBlock() { [weak self] in
            guard let strongSelf = self else { return }
            
            scanning = strongSelf.scanning
        }
        workingQueue.waitUntilAllOperationsAreFinished()
        return scanning
    }
    
    private var scanning: Bool {
        return devicesCoordinator.isScanning
    }
    
    func startScanningWithHandlerQueue(handlerQueue: NSOperationQueue, handler: ScanHandlerBlock) {
        workingQueue.addOperationWithBlock() { [weak self] in
            guard let strongSelf = self else { return }
            guard !strongSelf.scanning else { return }
            
            strongSelf.logger.info("Start scanning devices")
            strongSelf.scanHandlerQueue = handlerQueue
            strongSelf.scanHandlerBlock = handler
            strongSelf.devicesCoordinator.startScanning()
        }
    }
    
    func stopScanning() {
        workingQueue.addOperationWithBlock() { [weak self] in
            guard let strongSelf = self else { return }
            guard strongSelf.scanning else { return }
            
            strongSelf.logger.info("Stop scanning devices")
            strongSelf.devicesCoordinator.stopScanning()
            strongSelf.scanHandlerQueue = nil
            strongSelf.scanHandlerBlock = nil
        }
        workingQueue.waitUntilAllOperationsAreFinished()
    }
    
}

// MARK: - Connection management

extension RemoteDeviceCommunicator {
    
    typealias ConnectionHandlerBlock = (device: RemoteDeviceType, isConnected: Bool, error: RemoteDeviceError?) -> Void
    
    var connectionState: RemoteConnectionState {
        var state = RemoteConnectionState.Disconnected
        workingQueue.addOperationWithBlock() { [weak self] in
            guard let strongSelf = self else { return }
            
            state = strongSelf.internalState
        }
        workingQueue.waitUntilAllOperationsAreFinished()
        return state
    }
    
    private var internalState: RemoteConnectionState {
        var state = devicesCoordinator.connectionState
        if state == .Connected {
            switch passingAttestation {
            case nil:
                state = .Connecting
            case let value where value == false:
                state = .Disconnected
            default:
                break
            }
        }
        return state
    }
    
    var activeDevice: RemoteDeviceType? {
        var device: RemoteDeviceType?
        workingQueue.addOperationWithBlock() { [weak self] in
            guard let strongSelf = self else { return }
            
            device = strongSelf.internalDevice
        }
        workingQueue.waitUntilAllOperationsAreFinished()
        return device
    }
    
    private var internalDevice: RemoteDeviceType? {
        var device = devicesCoordinator.activeDevice
        if device != nil {
            switch passingAttestation {
            case nil:
                device = nil
            case let value where value == false:
                device = nil
            default:
                break
            }
        }
        return device
    }

    func connect(device: RemoteDeviceType, handlerQueue: NSOperationQueue, handler: ConnectionHandlerBlock) {
        workingQueue.addOperationWithBlock() { [weak self] in
            guard let strongSelf = self else { return }

            // connect
            strongSelf.processConnectToDevice(device, handlerQueue: handlerQueue, handler: handler)
        }
    }
    
    func disconnect() {
        workingQueue.addOperationWithBlock() { [weak self] in
            guard let strongSelf = self else { return }

            // disconnect
            strongSelf.processDisconnect(delegateError: nil)
        }
        workingQueue.waitUntilAllOperationsAreFinished()
    }
    
    private func processConnectToDevice(device: RemoteDeviceType, handlerQueue: NSOperationQueue, handler: ConnectionHandlerBlock) {
        guard internalState == .Disconnected else { return }

        logger.info("Connecting device \(device.uid)")
        connectionHandlerQueue = handlerQueue
        connectionHandlerBlock = handler
        devicesCoordinator.connect(device)
    }
    
    private func processDisconnect(delegateError delegateError: RemoteDeviceError?) {
        guard internalState == .Connected || internalState == .Connecting || internalState == .Disconnected else { return }
        guard let device = devicesCoordinator.activeDevice else { return }
        
        logger.info("Disconnecting device \(device.uid)")
        forcedDelegateError = delegateError
        devicesCoordinator.disconnect()
    }
    
    private func resetConnectionState() {
        connectionHandlerBlock = nil
        connectionHandlerQueue = nil
        passingAttestation = nil
        forcedDelegateError = nil
        deviceAPI = nil
    }
    
}

// MARK: - Notifications management

private extension RemoteDeviceCommunicator {
    
    private func notifyHandlerDidFindDevice(device: RemoteDeviceType) {
        let scanHandlerQueue = self.scanHandlerQueue
        let scanHandlerBlock = self.scanHandlerBlock
        
        scanHandlerQueue?.addOperationWithBlock() {
            scanHandlerBlock?(device: device, isFound: true)
        }
    }
    
    private func notifyHandlerDidLostDevice(device: RemoteDeviceType) {
        let scanHandlerQueue = self.scanHandlerQueue
        let scanHandlerBlock = self.scanHandlerBlock
        
        scanHandlerQueue?.addOperationWithBlock() {
            scanHandlerBlock?(device: device, isFound: false)
        }
    }

    private func notifyHandlerDidConnectDevice(device: RemoteDeviceType) {
        let connectionHandlerBlock = self.connectionHandlerBlock
        let connectionHandlerQueue = self.connectionHandlerQueue
        
        connectionHandlerQueue?.addOperationWithBlock() {
            connectionHandlerBlock?(device: device, isConnected: true, error: nil)
        }
    }
    
    private func notifyHandlerDidFailToConnectDevice(device: RemoteDeviceType) {
        let connectionHandlerBlock = self.connectionHandlerBlock
        let connectionHandlerQueue = self.connectionHandlerQueue
        
        connectionHandlerQueue?.addOperationWithBlock() {
            connectionHandlerBlock?(device: device, isConnected: false, error: .UnableToConnect)
        }
    }
    
    private func notifyHandlerDidDisconnectDevice(device: RemoteDeviceType, error: RemoteDeviceError?) {
        let forcedError = self.forcedDelegateError
        let connectionHandlerBlock = self.connectionHandlerBlock
        let connectionHandlerQueue = self.connectionHandlerQueue
        
        connectionHandlerQueue?.addOperationWithBlock() {
            if error == nil && forcedError != nil {
                connectionHandlerBlock?(device: device, isConnected: false, error: forcedError)
            }
            else {
                connectionHandlerBlock?(device: device, isConnected: false, error: error)
            }
        }
    }
    
}

// MARK: - RemoteDevicesCoordinatorDelegate

extension RemoteDeviceCommunicator: RemoteDevicesCoordinatorDelegate {
    
    func devicesCoordinator(devicesCoordinator: RemoteDevicesCoordinator, didFindDevice device: RemoteDeviceType) {
        guard scanning else { return }
        
        // notify handler
        notifyHandlerDidFindDevice(device)
    }
    
    func devicesCoordinator(devicesCoordinator: RemoteDevicesCoordinator, didLoseDevice device: RemoteDeviceType) {
        guard scanning else { return }
        
        // notify handler
        notifyHandlerDidLostDevice(device)
    }
    
    func devicesCoordinator(devicesCoordinator: RemoteDevicesCoordinator, didConnectDevice device: RemoteDeviceType) {
        guard internalState == .Connecting else { return }
        
        // check attestation
        logger.info("Checking attestation for device \(device.uid)")
        deviceAPI = RemoteDeviceAPI(devicesCoordinator: self.devicesCoordinator, servicesProvider: servicesProvider)
        deviceAPI?.checkAttestation(timeoutInterval: 5.0, completionQueue: workingQueue) { [weak self] isAuthentic, isBeta, error in
            guard let strongSelf = self else { return }
            
            if isAuthentic {
                strongSelf.logger.info("Attestation passed for device \(device.uid) (beta = \(isBeta)), considering connected")
            }
            else {
                strongSelf.logger.warn("Attestation failed for device \(device.uid), disconnecting")
            }
            
            strongSelf.passingAttestation = isAuthentic
            if isAuthentic && error == nil {
                // able to pass attestation
                strongSelf.logger.info("Connected device \(device.uid)")
                strongSelf.notifyHandlerDidConnectDevice(device)
            }
            else {
                // unable to pass attestation
                strongSelf.processDisconnect(delegateError: .UnableToAuthentify)
            }
        }
    }
    
    func devicesCoordinator(devicesCoordinator: RemoteDevicesCoordinator, didFailToConnectDevice device: RemoteDeviceType) {
        guard internalState == .Disconnected else { return }

        // notify handler
        logger.error("Failed to connect device \(device.uid)")
        notifyHandlerDidFailToConnectDevice(device)
        resetConnectionState()
    }
    
    func devicesCoordinator(devicesCoordinator: RemoteDevicesCoordinator, didDisconnectDevice device: RemoteDeviceType, withError error: RemoteDeviceError?) {
        guard internalState == .Connecting || internalState == .Connected || internalState == .Disconnected else { return }

        // notify handler
        if error != nil {
            logger.error("Disconnected device \(device.uid) with error \(error!)")
        }
        else {
            logger.info("Disconnected device \(device.uid)")
        }
        notifyHandlerDidDisconnectDevice(device, error: error)

        // notify API
        deviceAPI?.handleDidDisconnectDevice(device, withError: error)
        
        resetConnectionState()
    }
    
    func devicesCoordinator(devicesCoordinator: RemoteDevicesCoordinator, didSendAPDU APDU: RemoteAPDU, toDevice device: RemoteDeviceType) {
        guard internalState == .Connected || internalState == .Connecting else { return }
    
        // notify API
        deviceAPI?.handleDidSendAPDU(APDU, toDevice: device)
    }
    
    func devicesCoordinator(devicesCoordinator: RemoteDevicesCoordinator, didFailToSendAPDUToDevice device: RemoteDeviceType) {
        guard internalState == .Connected || internalState == .Connecting else { return }

        // notify API
        deviceAPI?.handleDidFailToSendAPDUToDevice(device)
    }
    
    func devicesCoordinator(devicesCoordinator: RemoteDevicesCoordinator, didReceiveAPDU APDU: RemoteAPDU, fromDevice device: RemoteDeviceType) {
        guard internalState == .Connected || internalState == .Connecting else { return }

        // notify API
        deviceAPI?.handleDidReceiveAPDU(APDU, fromDevice: device)
    }
    
    func devicesCoordinator(devicesCoordinator: RemoteDevicesCoordinator, didFailToReceiveAPDUFromDevice device: RemoteDeviceType) {
        guard internalState == .Connected || internalState == .Connecting else { return }

        // notify API
        deviceAPI?.handleDidFailToReceiveAPDUFromDevice(device)
    }
    
}