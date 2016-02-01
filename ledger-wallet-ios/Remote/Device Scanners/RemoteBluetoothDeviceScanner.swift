//
//  RemoteBluetoothDeviceScanner.swift
//  ledger-wallet-ios
//
//  Created by Nicolas Bigot on 22/01/2016.
//  Copyright © 2016 Ledger. All rights reserved.
//

import Foundation
import CoreBluetooth

final class RemoteBluetoothDeviceScanner: NSObject, RemoteDeviceScannerType {
    
    private static let lostDeviceCheckTimeInterval = 10.0
    
    weak var delegate: RemoteDeviceScannerDelegate?
    let transportType = RemoteTransportType.Bluetooth
    private var scanning = false
    private var knownDevices: [RemoteBluetoothDevice: DispatchTimer] = [:]
    private let servicesProvider: ServicesProviderType
    private var centralManager: CBCentralManager!
    private let delegateQueue: NSOperationQueue
    private let workingQueue: NSOperationQueue
    private let logger = Logger.sharedInstance(name: "RemoteBluetoothDeviceScanner")
    
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
    
    func startScanning() {
        workingQueue.addOperationWithBlock() { [weak self] in
            guard let strongSelf = self else { return }
            guard !strongSelf.scanning else { return }
            
            // start scanning
            strongSelf.logger.info("Start scanning devices")
            strongSelf.scanning = true
            strongSelf.createCentralManagedIfNeeded()
            strongSelf.startCentralScanIfPossible()
            
            // notify delegate
            strongSelf.notifyDelegateScanDidStart()
        }
    }
    
    func stopScanning() {
        workingQueue.cancelAllOperations()
        workingQueue.addOperationWithBlock() { [weak self] in
            guard let strongSelf = self else { return }
            guard strongSelf.scanning else { return }
            
            // stop scanning
            strongSelf.logger.info("Stop scanning devices")
            strongSelf.scanning = false
            strongSelf.stopCentralScan()
            strongSelf.knownDevices.values.forEach({ $0.invalidate() })
            strongSelf.knownDevices.removeAll()
            
            // notify delegate
            strongSelf.notifyDelegateScanDidStop()
        }
        workingQueue.waitUntilAllOperationsAreFinished()
    }
    
    private func deviceWithPeripheralIdentifier(identifier: String) -> RemoteBluetoothDevice? {
        for device in knownDevices.keys {
            if device.peripheral.identifier.UUIDString == identifier {
                return device
            }
        }
        return nil
    }
    
    // MARK: Central management

    private func startCentralScanIfPossible() {
        guard centralManager != nil && centralManager.state == .PoweredOn else {
            logger.info("Trying to start bluetooth central scan but not powered on yet, waiting")
            return
        }
        
        logger.info("Bluetooth central is powered on, start scanning for peripherals")
        let options = [CBCentralManagerScanOptionAllowDuplicatesKey: true]
        centralManager.scanForPeripheralsWithServices(nil, options: options)
    }
    
    private func stopCentralScan() {
        logger.info("Stop scanning bluetooth central peripherals")
        centralManager.stopScan()
    }
    
    private func createCentralManagedIfNeeded() {
        guard centralManager == nil else { return }
        
        let options = [CBCentralManagerOptionShowPowerAlertKey: true]
        centralManager = CBCentralManager(delegate: nil, queue: workingQueue.underlyingQueue, options: options)
        centralManager.delegate = self
    }
    
    // MARK: Initialization
    
    init(servicesProvider: ServicesProviderType, delegateQueue: NSOperationQueue) {
        self.servicesProvider = servicesProvider
        self.delegateQueue = delegateQueue
        self.workingQueue = NSOperationQueue(name: "RemoteBluetoothDeviceScanner", maxConcurrentOperationCount: 1)
        self.workingQueue.underlyingQueue = dispatchSerialQueueWithName(dispatchQueueNameForIdentifier("RemoteBluetoothDeviceScanner"))
    }
    
    deinit {
        stopScanning()
    }
    
}

// MARK: - Delegate management 

private extension RemoteBluetoothDeviceScanner {
    
    private func notifyDelegateScanDidStart() {
        delegateQueue.addOperationWithBlock() { [weak self] in
            guard let strongSelf = self else { return }
            strongSelf.delegate?.deviceScannerDidStartScanning(strongSelf)
        }
    }
    
    private func notifyDelegateScanDidStop() {
        delegateQueue.addOperationWithBlock() { [weak self] in
            guard let strongSelf = self else { return }
            strongSelf.delegate?.deviceScannerDidStopScanning(strongSelf)
        }
    }
    
    private func notifyDelegateScanDidFindDevice(device: RemoteBluetoothDevice) {
        delegateQueue.addOperationWithBlock() { [weak self] in
            guard let strongSelf = self else { return }
            strongSelf.delegate?.deviceScanner(strongSelf, didFindDevice: device)
        }
    }
    
    private func notifyDelegateScanDidLoseDevice(device: RemoteBluetoothDevice) {
        delegateQueue.addOperationWithBlock() { [weak self] in
            guard let strongSelf = self else { return }
            strongSelf.delegate?.deviceScanner(strongSelf, didLoseDevice: device)
        }
    }
    
}

// MARK: - CBCentralManagerDelegate

extension RemoteBluetoothDeviceScanner: CBCentralManagerDelegate {
    
    func centralManagerDidUpdateState(central: CBCentralManager) {
        guard scanning else { return }
        
        logger.info("Bluetooth central state is now \(central.state.description)")
        if centralManager.state == .PoweredOn {
            startCentralScanIfPossible()
        }
        else {
            stopCentralScan()
        }
    }
    
    func centralManager(central: CBCentralManager, didDiscoverPeripheral peripheral: CBPeripheral, advertisementData: [String : AnyObject], RSSI: NSNumber) {
        guard scanning else { return }

        let handleDeviceLostBlock = { [weak self] (identifier: String) in
            guard let strongSelf = self else { return }
            guard strongSelf.scanning else { return }
            guard let device = strongSelf.deviceWithPeripheralIdentifier(identifier) else { return }
            
            strongSelf.logger.info("Device \(device.peripheral.identifier.UUIDString) hasn't advertised since \(strongSelf.dynamicType.lostDeviceCheckTimeInterval) secs, destroying it")
            strongSelf.knownDevices[device]?.invalidate()
            strongSelf.knownDevices.removeValueForKey(device)
            
            // notify delegate
            strongSelf.notifyDelegateScanDidLoseDevice(device)
        }
        
        let handleDeviceFindBlock = { [weak self] (name: String, peripheral: CBPeripheral, descriptor: RemoteBluetoothDeviceDescriptor) in
            guard let strongSelf = self else { return }
            
            // find or create device
            let finalDevice: RemoteBluetoothDevice
            if let device = strongSelf.deviceWithPeripheralIdentifier(peripheral.identifier.UUIDString) {
                finalDevice = device
            }
            else {
                let device = RemoteBluetoothDevice(name: name, peripheral: peripheral, descriptor: descriptor)
                finalDevice = device
                
                strongSelf.logger.info("Device \(device.peripheral.identifier.UUIDString) advertised for the first time, retaining it")
                
                // notify delegate
                strongSelf.notifyDelegateScanDidFindDevice(finalDevice)
            }
            
            // schedule lost device timer
            if let queue = strongSelf.workingQueue.underlyingQueue {
                strongSelf.knownDevices[finalDevice]?.invalidate()
                strongSelf.knownDevices[finalDevice] = DispatchTimer.scheduledTimerWithTimeInterval(milliseconds: UInt(strongSelf.dynamicType.lostDeviceCheckTimeInterval) * 1000, queue: queue, repeats: false) { _ in
                    handleDeviceLostBlock(finalDevice.peripheral.identifier.UUIDString)
                }
            }
        }
        
        // look device name
        for descriptor in servicesProvider.remoteBluetoothDeviceDescriptors {
            if let name = peripheral.name where name.hasPrefix(descriptor.name) {
                handleDeviceFindBlock(name, peripheral, descriptor)
                break
            }
            else if let name = advertisementData[CBAdvertisementDataLocalNameKey] as? String where name.hasPrefix(descriptor.name) {
                handleDeviceFindBlock(name, peripheral, descriptor)
                break
            }
        }
    }
    
}

// MARK: - CBCentralManagerState

extension CBCentralManagerState: CustomStringConvertible {
    
    public var description: String {
        switch self {
        case .PoweredOn: return "PoweredOn"
        case .PoweredOff: return "PoweredOff"
        case .Resetting: return "Resetting"
        case .Unauthorized: return "Unauthorized"
        case .Unknown: return "Unknown"
        case .Unsupported: return "Unsupported"
        }
    }
    
}