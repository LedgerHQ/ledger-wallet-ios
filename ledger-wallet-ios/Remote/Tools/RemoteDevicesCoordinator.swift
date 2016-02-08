//
//  RemoteDevicesCoordinator.swift
//  ledger-wallet-ios
//
//  Created by Nicolas Bigot on 04/02/2016.
//  Copyright © 2016 Ledger. All rights reserved.
//

import Foundation

protocol RemoteDevicesCoordinatorDelegate: class {
    
    func devicesCoordinator(devicesCoordinator: RemoteDevicesCoordinator, didFindDevice device: RemoteDeviceType)
    func devicesCoordinator(devicesCoordinator: RemoteDevicesCoordinator, didLoseDevice device: RemoteDeviceType)
    func devicesCoordinator(devicesCoordinator: RemoteDevicesCoordinator, didConnectDevice device: RemoteDeviceType)
    func devicesCoordinator(devicesCoordinator: RemoteDevicesCoordinator, didFailToConnectDevice device: RemoteDeviceType)
    func devicesCoordinator(devicesCoordinator: RemoteDevicesCoordinator, didDisconnectDevice device: RemoteDeviceType, withError error: RemoteDeviceError?)
    func devicesCoordinator(devicesCoordinator: RemoteDevicesCoordinator, didSendAPDU APDU: RemoteAPDU, toDevice device: RemoteDeviceType)
    func devicesCoordinator(devicesCoordinator: RemoteDevicesCoordinator, didFailToSendAPDUToDevice device: RemoteDeviceType)
    func devicesCoordinator(devicesCoordinator: RemoteDevicesCoordinator, didReceiveAPDU APDU: RemoteAPDU, fromDevice device: RemoteDeviceType)
    func devicesCoordinator(devicesCoordinator: RemoteDevicesCoordinator, didFailToReceiveAPDUFromDevice device: RemoteDeviceType)

}

final class RemoteDevicesCoordinator {
    
    private static let transferTimeoutInterval = 5.0
    
    weak var delegate: RemoteDevicesCoordinatorDelegate?
    private weak var currentManager: RemoteDevicesManagerType?
    private let managers: [RemoteDevicesManagerType]
    private let slicers: [RemoteAPDUSlicerType]
    private var currentAPDU: RemoteAPDU?
    private var currentSlicer: RemoteAPDUSlicerType?
    private var pendingSlices: [RemoteAPDUSlice] = []
    private var currentTransferType: RemoteTransferType?
    private var timeoutTimer: DispatchTimer?
    private let extendedLogs = false
    private let delegateQueue: NSOperationQueue
    private let workingQueue = NSOperationQueue(name: "RemoteDevicesCoordinator", maxConcurrentOperationCount: 1)
    private let logger = Logger.sharedInstance(name: "RemoteDevicesCoordinator")
    
    // MARK: Scan management
    
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
        return managers.indexOf({ $0.isScanning }) != nil
    }
    
    func startScanning() {
        workingQueue.addOperationWithBlock() { [weak self] in
            guard let strongSelf = self else { return }
            guard !strongSelf.scanning else { return }
            
            strongSelf.logger.info("Start scanning all transport types")
            strongSelf.managers.forEach({ $0.startScanning() })
        }
     }
    
    func stopScanning() {
        workingQueue.addOperationWithBlock() { [weak self] in
            guard let strongSelf = self else { return }
            guard strongSelf.scanning else { return }
            
            strongSelf.logger.info("Stop scanning all transport types")
            strongSelf.managers.forEach({ $0.stopScanning() })
        }
        workingQueue.waitUntilAllOperationsAreFinished()
    }
    
    // MARK: Connection management
    
    var connectionState: RemoteConnectionState {
        var state = RemoteConnectionState.Disconnected
        workingQueue.addOperationWithBlock() { [weak self] in
            guard let strongSelf = self else { return }

            state = strongSelf.state
        }
        workingQueue.waitUntilAllOperationsAreFinished()
        return state
    }
    
    private var state: RemoteConnectionState {
        if let manager = currentManager {
            return manager.connectionState
        }
        return .Disconnected
    }
    
    var activeDevice: RemoteDeviceType? {
        var device: RemoteDeviceType?
        workingQueue.addOperationWithBlock() { [weak self] in
            guard let strongSelf = self else { return }
            
            device = strongSelf.currentDevice
        }
        workingQueue.waitUntilAllOperationsAreFinished()
        return device
    }
    
    private var currentDevice: RemoteDeviceType? {
        if let manager = currentManager {
            return manager.activeDevice
        }
        return nil
    }
    
    func connect(device: RemoteDeviceType) {
        workingQueue.addOperationWithBlock() { [weak self] in
            guard let strongSelf = self else { return }
            guard strongSelf.state == .Disconnected else { return }
            
            guard let manager = strongSelf.managerWithTransportType(device.transportType) else {
                strongSelf.logger.error("Unable to connect device \(device.uid) with transport type \(device.transportType), no manager to handle it")
                strongSelf.notifyDelegateDidFailToConnectDevice(device)
                return
            }
            
            // connect device
            strongSelf.logger.info("Connecting device \(device.uid) with transport type \(device.transportType)")
            strongSelf.currentManager = manager
            manager.connect(device)
        }
    }
    
    func disconnect() {
        workingQueue.addOperationWithBlock() { [weak self] in
            guard let strongSelf = self else { return }
            guard strongSelf.state == .Connecting || strongSelf.state == .Connected else { return }
            guard let manager = strongSelf.currentManager else { return }
            guard let device = strongSelf.currentDevice else { return }
            
            // disconnect device
            strongSelf.logger.info("Disconnecting device \(device.uid) with transport type \(device.transportType)")
            strongSelf.resetInternalState()
            manager.disconnect()
        }
    }
    
    // MARK: Send management
    
    func send(APDU: RemoteAPDU) {
        workingQueue.addOperationWithBlock() { [weak self] in
            guard let strongSelf = self else { return }

            // send APDU
            strongSelf.processSendAPDU(APDU)
        }
    }
    
    // MARK: Initialization
    
    init(servicesProvider: ServicesProviderType, delegateQueue: NSOperationQueue) {
        self.delegateQueue = delegateQueue
        
        let bluetoothSlicer = RemoteBluetoothAPDUSlicer()
        self.slicers = [bluetoothSlicer]

        let bluetoothManager = RemoteBluetoothDevicesManager(servicesProvider: servicesProvider, delegateQueue: workingQueue)
        self.managers = [bluetoothManager]
        self.managers.forEach({ $0.delegate = self })
    }
    
    deinit {
        workingQueue.cancelAllOperations()
        stopScanning()
        disconnect()
    }
    
}

// MARK: - Timeout management

private extension RemoteDevicesCoordinator {

    private func startTransferTimeoutTimerForDevice(device: RemoteDeviceType, manager: RemoteDevicesManagerType, transferType: RemoteTransferType) {
        // start timeout timer
        if let queue = workingQueue.underlyingQueue {
            timeoutTimer = DispatchTimer.scheduledTimerWithTimeInterval(milliseconds: UInt(self.dynamicType.transferTimeoutInterval) * 1000, queue: queue, repeats: false) { [weak self] _ in
                guard let strongSelf = self else { return }
                guard let currentDevice = strongSelf.currentDevice where device === currentDevice else { return }
                guard let currentManager = strongSelf.currentManager where manager === currentManager else { return }
                guard strongSelf.currentTransferType == transferType else { return }
                guard strongSelf.state == .Connected else { return }
                
                strongSelf.logger.error("Transfer \(transferType) timed out for device \(device.uid) with transport type \(device.transportType)")
                if transferType == .Read {
                    strongSelf.processEndReceiveAPDUFromDevice(device, notifyDelegate: true, hasError: true, APDU: nil)
                }
                else {
                    strongSelf.processEndSendAPDUToDevice(device, notifyDelegate: true, hasError: true, APDU: nil)
                }
            }
        }
    }
    
    private func stopTimeoutTimer() {
        // stop timeout timer
        timeoutTimer?.invalidate()
        timeoutTimer = nil
    }
    
}

// MARK: - Connection management

private extension RemoteDevicesCoordinator {
    
    private func resetInternalState() {
        currentManager = nil
        resetTransferInternalState()
    }
    
    private func resetTransferInternalState() {
        currentTransferType = nil
        pendingSlices = []
        currentAPDU = nil
        currentSlicer = nil
        stopTimeoutTimer()
    }
    
    private func managerWithTransportType(type: RemoteTransportType) -> RemoteDevicesManagerType? {
        return managers.filter({ $0.transportType == type }).first
    }
    
}

// MARK: - Send management

private extension RemoteDevicesCoordinator {

    private func processSendAPDU(APDU: RemoteAPDU) {
        guard state == .Connected else { return }
        guard let manager = currentManager else { return }
        guard let device = currentDevice else { return }
        
        guard currentTransferType == nil && pendingSlices.count == 0 && currentAPDU == nil else {
            logger.warn("Trying to send APDU \(APDU.data) but current transfer is not finished, still \(pendingSlices.count) to send")
            return
        }

        guard let slicer = slicerWithTransportType(manager.transportType) else {
            logger.error("Trying to send APDU \(APDU.data) but no slicer of transport type \(manager.transportType) to handle it")
            notifyDelegateDidFailToSendAPDUToDevice(device)
            return
        }
        
        // get slices
        let slices = slicer.sliceAPDU(APDU, maxBytesLength: device.descriptor.writeByteSize)
        guard slices.count > 0 else {
            logger.error("Trying to send APDU \(APDU.data) but no slice were created, aborting")
            notifyDelegateDidFailToSendAPDUToDevice(device)
            return
        }
        
        // send slices
        if extendedLogs {
            logger.info("Sending APDU \(APDU.data) to device \(device.uid) with transport type \(device.transportType)")
        }
        else {
            logger.info("-> APDU \(APDU.data) to device \(device.uid) with transport type \(device.transportType)")
        }
        currentTransferType = .Write
        pendingSlices = slices
        currentAPDU = APDU
        currentSlicer = slicer
        processSendNextSlice()
        
        // start timeout timer
        startTransferTimeoutTimerForDevice(device, manager: manager, transferType: .Write)
    }
    
    private func processSendNextSlice() {
        workingQueue.addOperationWithBlock() { [weak self] in
            guard let strongSelf = self else { return }
            guard strongSelf.state == .Connected else { return }
            guard let manager = strongSelf.currentManager else { return }
            guard let device = strongSelf.currentDevice else { return }
            guard strongSelf.currentTransferType == .Write else { return }

            if strongSelf.pendingSlices.count > 0 {
                // send slice
                let slice = strongSelf.pendingSlices.first!
                if strongSelf.extendedLogs {
                    strongSelf.logger.info("Sending slice \(slice.index) \(slice.data) to device \(device.uid) with transport type \(device.transportType)")
                }
                manager.send(slice.data)
            }
        }
    }
    
    private func processEndSendAPDUToDevice(device: RemoteDeviceType, notifyDelegate: Bool, hasError: Bool, APDU: RemoteAPDU?) {
        let currentSlicer = self.currentSlicer
        resetTransferInternalState()

        if !hasError {
            currentTransferType = .Read
            self.currentSlicer = currentSlicer
        }
        
        if notifyDelegate {
            if hasError {
                notifyDelegateDidFailToSendAPDUToDevice(device)
            }
            else if APDU != nil {
                notifyDelegateDidSendAPDU(APDU!, toDevice: device)
            }
        }
    }
    
    private func processEndReceiveAPDUFromDevice(device: RemoteDeviceType, notifyDelegate: Bool, hasError: Bool, APDU: RemoteAPDU?) {
        resetTransferInternalState()
        
        if notifyDelegate {
            if hasError {
                notifyDelegateDidFailToReceiveAPDUFromDevice(device)
            }
            else if APDU != nil {
                notifyDelegateDidReceiveAPDU(APDU!, fromDevice: device)
            }
        }
    }
    
    private func slicerWithTransportType(type: RemoteTransportType) -> RemoteAPDUSlicerType? {
        return slicers.filter({ $0.transportType == type }).first
    }
    
}


// MARK: - Notifications management

private extension RemoteDevicesCoordinator {
    
    private func notifyDelegateScanDidFindDevice(device: RemoteDeviceType) {
        delegateQueue.addOperationWithBlock() { [weak self] in
            guard let strongSelf = self else { return }
            
            strongSelf.delegate?.devicesCoordinator(strongSelf, didFindDevice: device)
        }
    }
    
    private func notifyDelegateScanDidLoseDevice(device: RemoteDeviceType) {
        delegateQueue.addOperationWithBlock() { [weak self] in
            guard let strongSelf = self else { return }
            
            strongSelf.delegate?.devicesCoordinator(strongSelf, didLoseDevice: device)
        }
    }
    
    private func notifyDelegateDidFailToConnectDevice(device: RemoteDeviceType) {
        delegateQueue.addOperationWithBlock() { [weak self] in
            guard let strongSelf = self else { return }
            strongSelf.delegate?.devicesCoordinator(strongSelf, didFailToConnectDevice: device)
        }
    }
    
    private func notifyDelegateDidConnectDevice(device: RemoteDeviceType) {
        delegateQueue.addOperationWithBlock() { [weak self] in
            guard let strongSelf = self else { return }
            
            strongSelf.delegate?.devicesCoordinator(strongSelf, didConnectDevice: device)
        }
    }
    
    private func notifyDelegateDidDisconnectDevice(device: RemoteDeviceType, withError error: RemoteDeviceError?) {
        delegateQueue.addOperationWithBlock() { [weak self] in
            guard let strongSelf = self else { return }
            
            strongSelf.delegate?.devicesCoordinator(strongSelf, didDisconnectDevice: device, withError: error)
        }
    }
    
    private func notifyDelegateDidSendAPDU(APDU: RemoteAPDU, toDevice device: RemoteDeviceType) {
        delegateQueue.addOperationWithBlock() { [weak self] in
            guard let strongSelf = self else { return }
         
            strongSelf.delegate?.devicesCoordinator(strongSelf, didSendAPDU: APDU, toDevice: device)
        }
    }

    private func notifyDelegateDidFailToSendAPDUToDevice(device: RemoteDeviceType) {
        delegateQueue.addOperationWithBlock() { [weak self] in
            guard let strongSelf = self else { return }
            
            strongSelf.delegate?.devicesCoordinator(strongSelf, didFailToSendAPDUToDevice: device)
        }
    }

    private func notifyDelegateDidReceiveAPDU(APDU: RemoteAPDU, fromDevice device: RemoteDeviceType) {
        delegateQueue.addOperationWithBlock() { [weak self] in
            guard let strongSelf = self else { return }
         
            strongSelf.delegate?.devicesCoordinator(strongSelf, didReceiveAPDU: APDU, fromDevice: device)
        }
    }
    
    private func notifyDelegateDidFailToReceiveAPDUFromDevice(device: RemoteDeviceType) {
        delegateQueue.addOperationWithBlock() { [weak self] in
            guard let strongSelf = self else { return }
            
            strongSelf.delegate?.devicesCoordinator(strongSelf, didFailToReceiveAPDUFromDevice: device)
        }
    }
    
}

// MARK: - RemoteDevicesManagerDelegate

extension RemoteDevicesCoordinator: RemoteDevicesManagerDelegate {
    
    func devicesManager(devicesManager: RemoteDevicesManagerType, didFindDevice device: RemoteDeviceType) {
        guard scanning else { return }
        
        // notify delegate
        notifyDelegateScanDidFindDevice(device)
    }
    
    func devicesManager(devicesManager: RemoteDevicesManagerType, didLoseDevice device: RemoteDeviceType) {
        guard scanning else { return }
        
        // notify delegate
        notifyDelegateScanDidLoseDevice(device)
    }
    
    func devicesManager(devicesManager: RemoteDevicesManagerType, didConnectDevice device: RemoteDeviceType) {
        // notify delegate
        notifyDelegateDidConnectDevice(device)
    }
    
    func devicesManager(devicesManager: RemoteDevicesManagerType, didFailToConnectDevice device: RemoteDeviceType) {
        resetInternalState()
        
        // notify delegate
        notifyDelegateDidFailToConnectDevice(device)
    }
    
    func devicesManager(devicesManager: RemoteDevicesManagerType, didDisconnectDevice device: RemoteDeviceType, withError error: RemoteDeviceError?) {
        resetInternalState()
        
        // notify delegate
        notifyDelegateDidDisconnectDevice(device, withError: error)
    }
    
    func devicesManager(devicesManager: RemoteDevicesManagerType, didReceiveData data: NSData, fromDevice device: RemoteDeviceType) {
        guard currentTransferType == .Read else { return }
        guard state == .Connected else { return }
        guard let currentManager = currentManager where currentManager === devicesManager else { return }
        guard let currentDevice = currentDevice where currentDevice === device else { return }

        guard let slicer = currentSlicer else {
            logger.error("Failed to receive slice \(data) from device \(device.uid) with transport type \(device.transportType), no slicer to handle it")
            processEndReceiveAPDUFromDevice(device, notifyDelegate: true, hasError: true, APDU: nil)
            return
        }
        
        guard let slice = slicer.sliceFromData(data) else {
            logger.error("Failed to receive slice \(data) from device \(device.uid) with transport type \(device.transportType), unable to build slice")
            processEndReceiveAPDUFromDevice(device, notifyDelegate: true, hasError: true, APDU: nil)
            return
        }
        
        if extendedLogs {
            logger.info("Received slice \(slice.index) \(slice.data) from device \(device.uid) with transport type \(device.transportType)")
        }
        pendingSlices.append(slice)
        
        // start timeout timer
        if slice.index == 0 {
            startTransferTimeoutTimerForDevice(device, manager: devicesManager, transferType: .Read)
        }
        
        // try to build APDU from slices
        if let APDU = slicer.joinSlices(pendingSlices) {
            // stop timeout timer
            stopTimeoutTimer()
            
            if extendedLogs {
                logger.info("Received APDU \(APDU.data) from device \(device.uid) with transport type \(device.transportType)")
            }
            else {
                logger.info("<- APDU \(APDU.data) from device \(device.uid) with transport type \(device.transportType)")
            }
            processEndReceiveAPDUFromDevice(device, notifyDelegate: true, hasError: false, APDU: APDU)
        }
    }
    
    func devicesManager(devicesManager: RemoteDevicesManagerType, didFailToReceiveDataFromDevice device: RemoteDeviceType) {
        guard currentTransferType == .Read else { return }
        guard state == .Connected else { return }
        guard let currentManager = currentManager where currentManager === devicesManager else { return }
        guard let currentDevice = currentDevice where currentDevice === device else { return }

        logger.error("Failed to receive APDU from device \(device.uid) with transport type \(device.transportType)")
        processEndReceiveAPDUFromDevice(device, notifyDelegate: true, hasError: true, APDU: nil)
    }
    
    func devicesManager(devicesManager: RemoteDevicesManagerType, didSendData data: NSData, toDevice device: RemoteDeviceType) {
        guard currentTransferType == .Write else { return }
        guard state == .Connected else { return }
        guard let currentManager = currentManager where currentManager === devicesManager else { return }
        guard let currentDevice = currentDevice where currentDevice === device else { return }
    
        guard pendingSlices.count > 0 && pendingSlices.first!.data == data else {
            logger.error("Sent slice data \(data) to device \(device.uid) with transport type \(device.transportType) but data doesn't match current slice")
            processEndSendAPDUToDevice(device, notifyDelegate: true, hasError: true, APDU: nil)
            return
        }
        
        let slice = pendingSlices.removeFirst()
        if extendedLogs {
            logger.info("Sent slice \(slice.index) \(slice.data) to device \(device.uid) with transport type \(device.transportType)")
        }
        
        // if we have other slices to send
        if pendingSlices.count > 0
        {
            processSendNextSlice()
        }
        else {
            // stop timeout timer
            stopTimeoutTimer()
            
            // notify delegate
            if let APDU = currentAPDU  {
                if extendedLogs {
                    logger.info("Sent APDU \(APDU.data) to device \(device.uid) with transport type \(device.transportType)")
                }
                processEndSendAPDUToDevice(device, notifyDelegate: true, hasError: false, APDU: APDU)
            }
            else {
                logger.error("Sent APDU to device \(device.uid) with transport type \(device.transportType) but with no trace of which data, weird")
                processEndSendAPDUToDevice(device, notifyDelegate: true, hasError: true, APDU: nil)
            }
        }
    }
    
    func devicesManager(devicesManager: RemoteDevicesManagerType, didFailToSendDataToDevice device: RemoteDeviceType) {
        guard currentTransferType == .Write else { return }
        guard state == .Connected else { return }
        guard let currentManager = currentManager where currentManager === devicesManager else { return }
        guard let currentDevice = currentDevice where currentDevice === device else { return }
        
        let slice = pendingSlices.removeFirst()
        logger.error("Failed to send slice \(slice.index) \(slice.data) to device \(device.uid) with transport type \(device.transportType)")
        processEndSendAPDUToDevice(device, notifyDelegate: true, hasError: true, APDU: nil)
    }

}