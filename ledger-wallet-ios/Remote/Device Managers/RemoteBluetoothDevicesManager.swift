//
//  RemoteBluetoothDevicesManager.swift
//  ledger-wallet-ios
//
//  Created by Nicolas Bigot on 02/02/2016.
//  Copyright © 2016 Ledger. All rights reserved.
//

import Foundation
import CoreBluetooth

final class RemoteBluetoothDevicesManager: NSObject, RemoteDevicesManagerType {
    
    private static let lostDeviceCheckTimeInterval = 10.0
    private static let connectionTimeoutInterval = 15.0
    private static let transferTimeoutInterval = 5.0
    
    weak var delegate: RemoteDevicesManagerDelegate?
    let transportType = RemoteTransportType.Bluetooth
    private var scannedDevices: [RemoteBluetoothDevice: DispatchTimer] = [:]
    private var state = RemoteConnectionState.Disconnected
    private var currentDevice: RemoteBluetoothDevice?
    private var scanning = false
    private var currentData: NSData?
    private var centralManager: CBCentralManager!
    private let servicesProvider: ServicesProviderType
    private var timeoutTimer: DispatchTimer?
    private let extendedLog = false
    private let delegateQueue: NSOperationQueue
    private let workingQueue: NSOperationQueue
    private let logger = Logger.sharedInstance(name: "RemoteBluetoothDevicesManager")

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
            strongSelf.centralManager.delegate = self
            strongSelf.processStartScanIfPossible()
        }
    }
    
    func stopScanning() {
        workingQueue.addOperationWithBlock() { [weak self] in
            guard let strongSelf = self else { return }
            guard strongSelf.scanning else { return }
            
            // stop scanning
            strongSelf.logger.info("Stop scanning devices")
            strongSelf.scanning = false
            strongSelf.centralManager.delegate = nil
            strongSelf.processStopScan(notifyDelegate: false)
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
    
    var activeDevice: RemoteDeviceType? {
        var device: RemoteDeviceType?
        workingQueue.addOperationWithBlock() { [weak self] in
            guard let strongSelf = self else { return }
            
            device = strongSelf.currentDevice
        }
        workingQueue.waitUntilAllOperationsAreFinished()
        return device
    }
    
    func connect(device: RemoteDeviceType) {
        workingQueue.addOperationWithBlock() { [weak self] in
            guard let strongSelf = self else { return }

            guard let bluetoothDevice = device as? RemoteBluetoothDevice else {
                strongSelf.logger.error("Unable to connect non bluetooth device, aborting")
                strongSelf.notifyDelegateDidFailToConnectDevice(device)
                return
            }

            // connect
            strongSelf.processConnectToDevice(bluetoothDevice)
        }
    }
    
    func disconnect() {
        workingQueue.addOperationWithBlock() { [weak self] in
            guard let strongSelf = self else { return }

            // disconnect
            strongSelf.processDisconnectDevice(notifyDelegate: true, error: nil)
        }
        workingQueue.waitUntilAllOperationsAreFinished()
    }
    
    // MARK: Send management
    
    func send(data: NSData) {
        workingQueue.addOperationWithBlock() { [weak self] in
            guard let strongSelf = self else { return }
            
            // send
            strongSelf.processSendData(data)
        }
    }
    
    // MARK: Initialization
    
    init(servicesProvider: ServicesProviderType, delegateQueue: NSOperationQueue) {
        self.servicesProvider = servicesProvider
        self.delegateQueue = delegateQueue
        self.workingQueue = NSOperationQueue(name: "RemoteBluetoothDevicesManager", maxConcurrentOperationCount: 1)
        self.workingQueue.underlyingQueue = dispatchSerialQueueWithName(dispatchQueueNameForIdentifier("RemoteBluetoothDevicesManager"))
    }
    
    private func createCentralManagedIfNeeded() {
        guard centralManager == nil else { return }
        
        let options = [CBCentralManagerOptionShowPowerAlertKey: true]
        centralManager = CBCentralManager(delegate: nil, queue: workingQueue.underlyingQueue, options: options)
    }
    
    deinit {
        workingQueue.cancelAllOperations()
        stopScanning()
        disconnect()
    }
    
}

// MARK: - Scan management

private extension RemoteBluetoothDevicesManager {
    
    private func processStartScanIfPossible() {
        guard centralManager != nil && centralManager.state == .PoweredOn else {
            logger.info("Trying to start bluetooth central scan but not powered on yet, waiting")
            return
        }
        
        logger.info("Bluetooth central is powered on, start scanning for peripherals")
        let options = [CBCentralManagerScanOptionAllowDuplicatesKey: true]
        centralManager.scanForPeripheralsWithServices(nil, options: options)
    }
    
    private func processStopScan(notifyDelegate notifyDelegate: Bool) {
        logger.info("Stop scanning bluetooth central peripherals")
        centralManager.stopScan()
        
        scannedDevices.values.forEach({ $0.invalidate() })
        let devices = scannedDevices.keys
        scannedDevices.removeAll()
        
        if notifyDelegate {
            notifyDelegateScanDidLoseDevices(devices.map({ $0 as RemoteBluetoothDevice }))
        }
    }
    
    private func scannedDeviceWithUniqueIdentifier(uid: String) -> RemoteBluetoothDevice? {
        return scannedDevices.keys.filter({ $0.uid == uid }).first
    }
    
    private func handleDiscoveredPeripheral(peripheral: CBPeripheral, advertisementData: [String : AnyObject]) {
        let handleDeviceLostBlock = { [weak self] (uid: String) in
            guard let strongSelf = self else { return }
            guard strongSelf.scanning else { return }
            guard let device = strongSelf.scannedDeviceWithUniqueIdentifier(uid) else { return }
            
            strongSelf.logger.info("Device \(device.uid) hasn't advertised since \(strongSelf.dynamicType.lostDeviceCheckTimeInterval) secs, destroying it")
            strongSelf.scannedDevices[device]?.invalidate()
            strongSelf.scannedDevices.removeValueForKey(device)
            
            // notify delegate
            strongSelf.notifyDelegateScanDidLoseDevices([device])
        }
        
        let handleDeviceFindBlock = { [weak self] (name: String, peripheral: CBPeripheral, descriptor: RemoteBluetoothDeviceDescriptor) in
            guard let strongSelf = self else { return }
            
            // find or create device
            let finalDevice: RemoteBluetoothDevice
            if let device = strongSelf.scannedDeviceWithUniqueIdentifier(peripheral.identifier.UUIDString) {
                finalDevice = device
            }
            else {
                let device = RemoteBluetoothDevice(name: name, descriptor: descriptor, peripheral: peripheral, devicesManager: strongSelf)
                finalDevice = device
                
                strongSelf.logger.info("Device \(device.uid) advertised for the first time, retaining it")
                
                // notify delegate
                strongSelf.notifyDelegateScanDidFindDevices([finalDevice])
            }
            
            // schedule lost device timer
            if let queue = strongSelf.workingQueue.underlyingQueue {
                strongSelf.scannedDevices[finalDevice]?.invalidate()
                strongSelf.scannedDevices[finalDevice] = DispatchTimer.scheduledTimerWithTimeInterval(milliseconds: UInt(strongSelf.dynamicType.lostDeviceCheckTimeInterval) * 1000, queue: queue, repeats: false) { _ in
                    handleDeviceLostBlock(finalDevice.uid)
                }
            }
        }
        
        // look device name
        for descriptor in servicesProvider.remoteBluetoothDeviceDescriptors {
            guard let isConnectable = advertisementData[CBAdvertisementDataIsConnectable] as? NSNumber where isConnectable.boolValue else {
                continue
            }
            
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

// MARK: - Connection management

private extension RemoteBluetoothDevicesManager {
    
    private func processConnectToDevice(device: RemoteBluetoothDevice) {
        guard state == .Disconnected else { return }
        
        // connect
        logger.info("Connecting device \(device.uid)")
        state = .Connecting
        currentDevice = device
        device.peripheral.delegate = self
        centralManager.delegate = self
        centralManager.connectPeripheral(device.peripheral, options: nil)
        
        // start timeout timer
        startConnectionTimeoutTimerForDevice(device)
    }
    
    private func processDisconnectDevice(notifyDelegate notifyDelegate: Bool, error: RemoteDeviceError?) {
        guard state == .Connecting || state == .Connected else { return }
        guard let device = currentDevice else { return }
        
        // disconnect
        logger.info("Disconnecting device \(device.uid)")
        state = .Disconnected
        currentDevice = nil
        centralManager.delegate = nil
        if let readCharacteristic = device.readCharacteristic {
            device.peripheral.setNotifyValue(false, forCharacteristic: readCharacteristic)
        }
        device.peripheral.delegate = nil
        device.readCharacteristic = nil
        device.writeCharacteristic = nil
        currentData = nil
        centralManager.cancelPeripheralConnection(device.peripheral)
        
        // stop timeout timer
        stopTimeoutTimer()
        
        // if notify delegate
        if notifyDelegate {
            notifyDelegateDidDisconnectDevice(device, withError: error)
        }
    }
    
    private func discoverServicesOfDevice(device: RemoteBluetoothDevice) {
        // discover services
        logger.info("Discovering services of device \(device.uid)")
        device.peripheral.discoverServices(nil)
    }
    
    private func discoverCharacteristicsOfDevice(device: RemoteBluetoothDevice) {
        guard let services = device.peripheral.services else { return }
        guard services.count == 1 else { return }
        
        // discover characteristics
        logger.info("Discovering characteristics of device \(device.uid)")
        device.peripheral.discoverCharacteristics(nil, forService: services[0])
    }
    
    private func handleDiscoveryOfServicesOfDevice(device: RemoteBluetoothDevice, error: NSError?) {
        // make sure we retreived services
        guard
            let descriptor = device.descriptor as? RemoteBluetoothDeviceDescriptor,
            let services = device.peripheral.services
        where
            error == nil
        else {
            logger.error("Unable to retreive services of device \(device.uid), disconnecting")
            processDisconnectDevice(notifyDelegate: true, error: .WrongDevice)
            return
        }
        
        // check that got the required number of services
        guard services.count == 1 else {
            logger.error("Device \(device.uid) has \(services.count), expected \(1), disconnecting")
            processDisconnectDevice(notifyDelegate: true, error: .WrongDevice)
            return
        }
        
        // check that got the required number of services
        guard services[0].UUID == descriptor.service.UUID else {
            logger.error("Discovered services of device \(device.uid) do not match descriptor (got \(services[0].UUID) expected \(descriptor.service.UUID)), disconnecting")
            processDisconnectDevice(notifyDelegate: true, error: .WrongDevice)
            return
        }
        
        // discover characteristics of all services
        discoverCharacteristicsOfDevice(device)
    }
    
    private func handleDiscoveryOfCharacteristicsOfDevice(device: RemoteBluetoothDevice, error: NSError?) {
        // make sure we retreived services
        guard let
            descriptor = device.descriptor as? RemoteBluetoothDeviceDescriptor,
            services = device.peripheral.services
        where
            error == nil
        else {
            logger.error("Unable to retreive services to handle characteristics of device \(device.uid), disconnecting")
            processDisconnectDevice(notifyDelegate: true, error: .WrongDevice)
            return
        }
        
        // check that got the required number of services
        guard services.count == 1 else { return } // shouldn't happen
        let service = services[0]
        
        // check that we got characteristics
        guard let characteristics = service.characteristics else {
            logger.error("Unable to retreive characteristics of device \(device.uid), disconnecting")
            processDisconnectDevice(notifyDelegate: true, error: .WrongDevice)
            return
        }
        
        // check read and write characteristic
        var readCharacteristic: CBCharacteristic?
        var writeCharacteristic: CBCharacteristic?
        for characteristic in characteristics {
            if characteristic.UUID == descriptor.readCharacteristic.UUID {
                if characteristic.properties == descriptor.readCharacteristic.properties {
                    readCharacteristic = characteristic
                }
            }
            if characteristic.UUID == descriptor.writeCharacteristic.UUID {
                if characteristic.properties == descriptor.writeCharacteristic.properties {
                    writeCharacteristic = characteristic
                }
            }
        }
        
        guard let rCharacteristic = readCharacteristic, wCharacteristic = writeCharacteristic else {
            logger.error("Unable to find read or write characteristic of device \(device.uid) from descriptor, disconnecting")
            processDisconnectDevice(notifyDelegate: true, error: .WrongDevice)
            return
        }
        
        // configure device
        logger.info("Device \(device.uid) conforms to descriptor, keeping its read and write characteristics")
        device.readCharacteristic = rCharacteristic
        device.writeCharacteristic = wCharacteristic
        
        logger.info("Asking for read notifications of device \(device.uid)")
        device.peripheral.setNotifyValue(true, forCharacteristic: rCharacteristic)
    }
    
    private func handleReadCharacteristicNotifyStateOfDevice(device: RemoteBluetoothDevice, characteristic: CBCharacteristic, error: NSError?) {
        guard characteristic == device.readCharacteristic else {
            logger.error("Received update of characteristic notification state other than device read, disconnecting")
            processDisconnectDevice(notifyDelegate: true, error: .UnableToBind)
            return
        }
        
        guard error == nil else {
            logger.error("Unable to listen for notification of read characteristic: \(error!.localizedDescription), disconnecting")
            processDisconnectDevice(notifyDelegate: true, error: .UnableToBind)
            return
        }
        
        guard characteristic.isNotifying == true else {
            logger.error("Unable to listen for notification of read characteristic: isNotifying is false, disconnecting")
            processDisconnectDevice(notifyDelegate: true, error: .UnableToBind)
            return
        }
        
        // connection is now successfull
        logger.info("Got read notifications for device \(device.uid), now connected")
        state = .Connected
        
        // stop timeout timer
        stopTimeoutTimer()
        
        // notify delegate
        notifyDelegateDidConnectDevice(device)
    }
    
}

// MARK: - Send management

private extension RemoteBluetoothDevicesManager {

    private func processSendData(data: NSData) {
        guard state == .Connected else { return }
        guard let device = currentDevice else { return }
        guard let writeCharacteristic = device.writeCharacteristic else { return }
        
        guard currentData == nil else {
            logger.warn("Unable to write data \(data), current data \(currentData!) not sent yet")
            return
        }
        
        guard data.length <= device.descriptor.writeByteSize else {
            logger.warn("Unable to write data of size \(data.length), should be <= \(device.descriptor.writeByteSize)")
            notifyDelegateDidFailToSendDataToDevice(device)
            return
        }
        
        // write data
        if extendedLog {
            logger.info("Sending data \(data) to device \(device.uid)")
        }
        currentData = data
        device.peripheral.writeValue(data, forCharacteristic: writeCharacteristic, type: .WithResponse)
        
        // start send timeout timer
        startSendTimeoutTimerForDevice(device)
    }
    
    private func processEndSendDataToDevice(device: RemoteBluetoothDevice, notifyDelegate: Bool, hasError: Bool, data: NSData?) {
        guard state == .Connected else { return }
        guard let currentDevice = currentDevice else { return }
        guard device.peripheral === currentDevice.peripheral else { return }
        
        currentData = nil
        
        // stop timeout timer
        stopTimeoutTimer()

        if notifyDelegate {
            if hasError {
                notifyDelegateDidFailToSendDataToDevice(device)
            }
            else if data != nil {
                notifyDelegateDidSendData(data!, toDevice: device)
            }
        }
    }
    
    private func processEndReceiveDataFromDevice(device: RemoteBluetoothDevice, notifyDelegate: Bool, hasError: Bool, data: NSData?) {
        guard state == .Connected else { return }
        guard let currentDevice = currentDevice else { return }
        guard device.peripheral === currentDevice.peripheral else { return }

        if notifyDelegate {
            if hasError {
                notifyDelegateDidFailToReceiveDataFromDevice(device)
            }
            else if data != nil {
                notifyDelegateDidReceiveData(data!, fromDevice: device)
            }
        }
    }
    
}

// MARK: - Timeout management

private extension RemoteBluetoothDevicesManager {
    
    private func startConnectionTimeoutTimerForDevice(device: RemoteBluetoothDevice) {
        // start timeout timer
        if let queue = workingQueue.underlyingQueue {
            timeoutTimer = DispatchTimer.scheduledTimerWithTimeInterval(milliseconds: UInt(self.dynamicType.connectionTimeoutInterval) * 1000, queue: queue, repeats: false) { [weak self] _ in
                guard let strongSelf = self else { return }
                guard strongSelf.state == .Connecting else { return }
                guard let currentDevice = strongSelf.currentDevice where currentDevice === device else { return }
                
                strongSelf.logger.error("Connection timed out for device \(device.uid), disconnecting")
                strongSelf.processDisconnectDevice(notifyDelegate: false, error: nil)
                strongSelf.notifyDelegateDidFailToConnectDevice(device)
            }
        }
    }
    
    private func startSendTimeoutTimerForDevice(device: RemoteBluetoothDevice) {
        // start timeout timer
        if let queue = workingQueue.underlyingQueue {
            timeoutTimer = DispatchTimer.scheduledTimerWithTimeInterval(milliseconds: UInt(self.dynamicType.transferTimeoutInterval) * 1000, queue: queue, repeats: false) { [weak self] _ in
                guard let strongSelf = self else { return }
                guard strongSelf.state == .Connected else { return }
                guard let currentDevice = strongSelf.currentDevice where currentDevice === device else { return }
                
                strongSelf.logger.error("Send timed out for device \(device.uid)")
                strongSelf.processEndSendDataToDevice(device, notifyDelegate: true, hasError: true, data: nil)
            }
        }
    }
    
    private func stopTimeoutTimer() {
        // stop timeout timer
        timeoutTimer?.invalidate()
        timeoutTimer = nil
    }
    
}

// MARK: - Delegate management

private extension RemoteBluetoothDevicesManager {
    
    private func notifyDelegateScanDidFindDevices(devices: [RemoteDeviceType]) {
        delegateQueue.addOperationWithBlock() { [weak self] in
            guard let strongSelf = self else { return }
            
            for device in devices {
                strongSelf.delegate?.devicesManager(strongSelf, didFindDevice: device)
            }
        }
    }
    
    private func notifyDelegateScanDidLoseDevices(devices: [RemoteDeviceType]) {
        delegateQueue.addOperationWithBlock() { [weak self] in
            guard let strongSelf = self else { return }
            
            for device in devices {
                strongSelf.delegate?.devicesManager(strongSelf, didLoseDevice: device)
            }
        }
    }
    
    private func notifyDelegateDidFailToConnectDevice(device: RemoteDeviceType) {
        delegateQueue.addOperationWithBlock() { [weak self] in
            guard let strongSelf = self else { return }
            strongSelf.delegate?.devicesManager(strongSelf, didFailToConnectDevice: device)
        }
    }
    
    private func notifyDelegateDidConnectDevice(device: RemoteDeviceType) {
        delegateQueue.addOperationWithBlock() { [weak self] in
            guard let strongSelf = self else { return }
            
            strongSelf.delegate?.devicesManager(strongSelf, didConnectDevice: device)
        }
    }
    
    private func notifyDelegateDidDisconnectDevice(device: RemoteDeviceType, withError error: RemoteDeviceError?) {
        delegateQueue.addOperationWithBlock() { [weak self] in
            guard let strongSelf = self else { return }
            
            strongSelf.delegate?.devicesManager(strongSelf, didDisconnectDevice: device, withError: error)
        }
    }
    
    private func notifyDelegateDidReceiveData(data: NSData, fromDevice device: RemoteDeviceType) {
        delegateQueue.addOperationWithBlock() { [weak self] in
            guard let strongSelf = self else { return }
            
            strongSelf.delegate?.devicesManager(strongSelf, didReceiveData: data, fromDevice: device)
        }
    }
    
    private func notifyDelegateDidFailToReceiveDataFromDevice(device: RemoteDeviceType) {
        delegateQueue.addOperationWithBlock() { [weak self] in
            guard let strongSelf = self else { return }
            
            strongSelf.delegate?.devicesManager(strongSelf, didFailToReceiveDataFromDevice: device)
        }
    }
    
    private func notifyDelegateDidSendData(data: NSData, toDevice device: RemoteDeviceType) {
        delegateQueue.addOperationWithBlock() { [weak self] in
            guard let strongSelf = self else { return }
            
            strongSelf.delegate?.devicesManager(strongSelf, didSendData: data, toDevice: device)
        }
    }
    
    private func notifyDelegateDidFailToSendDataToDevice(device: RemoteDeviceType) {
        delegateQueue.addOperationWithBlock() { [weak self] in
            guard let strongSelf = self else { return }
            
            strongSelf.delegate?.devicesManager(strongSelf, didFailToSendDataToDevice: device)
        }
    }
    
}

// MARK: - CBCentralManagerDelegate

extension RemoteBluetoothDevicesManager: CBCentralManagerDelegate {
    
    func centralManagerDidUpdateState(central: CBCentralManager) {
        logger.info("Bluetooth central state is now \(central.state.description)")
        
        if scanning {
            if centralManager.state == .PoweredOn {
                processStartScanIfPossible()
                return
            }
            else if centralManager.state.rawValue < CBCentralManagerState.PoweredOn.rawValue {
                processStopScan(notifyDelegate: true)
                return
            }
        }
        
        if state == .Connecting || state == .Connected {
            if centralManager.state.rawValue < CBCentralManagerState.PoweredOn.rawValue {
                processDisconnectDevice(notifyDelegate: true, error: .RemoteDisconnection)
                return
            }
        }
    }
    
    func centralManager(central: CBCentralManager, didDiscoverPeripheral peripheral: CBPeripheral, advertisementData: [String : AnyObject], RSSI: NSNumber) {
        guard scanning else { return }
        
        // handle discovered peripheral
        handleDiscoveredPeripheral(peripheral, advertisementData: advertisementData)
    }
    
    func centralManager(central: CBCentralManager, didConnectPeripheral peripheral: CBPeripheral) {
        guard state == .Connecting else { return }
        guard let device = currentDevice where device.peripheral === peripheral else { return }
        
        // discover services
        logger.info("Connected to device \(device.uid), discovering services")
        discoverServicesOfDevice(device)
    }
    
    func centralManager(central: CBCentralManager, didFailToConnectPeripheral peripheral: CBPeripheral, error: NSError?) {
        guard state == .Connecting else { return }
        guard let device = currentDevice where device.peripheral === peripheral else { return }

        // aknowledge disconnection
        logger.error("Failed to connect to device \(device.uid), aborting")
        processDisconnectDevice(notifyDelegate: false, error: nil)
    
        // notify delegate
        notifyDelegateDidFailToConnectDevice(device)
    }
    
    func centralManager(central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: NSError?) {
        guard state == .Connecting || state == .Connected else { return }
        guard let device = currentDevice where device.peripheral === peripheral else { return }

        // aknowledge disconnection
        if error != nil {
            logger.error("Disconnected from device \(device.uid), \(error!.localizedDescription)")
        }
        else {
            logger.info("Disconnected from device \(device.uid)")
        }
        processDisconnectDevice(notifyDelegate: true, error: error != nil ? .RemoteDisconnection : nil)
    }
    
}

// MARK: - CBPeripheralDelegate

extension RemoteBluetoothDevicesManager: CBPeripheralDelegate {
    
    func peripheral(peripheral: CBPeripheral, didDiscoverServices error: NSError?) {
        guard state == .Connecting else { return }
        guard let device = currentDevice where device.peripheral === peripheral else { return }
        
        // handle services discovery
        handleDiscoveryOfServicesOfDevice(device, error: error)
    }
    
    func peripheral(peripheral: CBPeripheral, didDiscoverCharacteristicsForService service: CBService, error: NSError?) {
        guard state == .Connecting else { return }
        guard let device = currentDevice where device.peripheral === peripheral else { return }
        
        // handle characteristics discovery
        handleDiscoveryOfCharacteristicsOfDevice(device, error: error)
    }
    
    func peripheral(peripheral: CBPeripheral, didUpdateNotificationStateForCharacteristic characteristic: CBCharacteristic, error: NSError?) {
        guard state == .Connecting else { return }
        guard let device = currentDevice where device.peripheral === peripheral else { return }
        
        // handle read characteristic notify state change
        handleReadCharacteristicNotifyStateOfDevice(device, characteristic: characteristic, error: error)
    }
    
    func peripheral(peripheral: CBPeripheral, didWriteValueForCharacteristic characteristic: CBCharacteristic, error: NSError?) {
        guard state == .Connected else { return }
        guard let device = currentDevice where device.peripheral === peripheral else { return }

        if let error = error {
            logger.error("Unable to write value to write characteristic of device \(device.uid): \(error.localizedDescription)")
            processEndSendDataToDevice(device, notifyDelegate: true, hasError: true, data: nil)
            return
        }
        
        guard let data = currentData else {
            logger.error("Sent data to device \(device.uid) but do not have trace of which data")
            processEndSendDataToDevice(device, notifyDelegate: true, hasError: true, data: nil)
            return
        }

        if extendedLog {
            logger.info("Sent data \(data) to device \(device.uid)")
        }
        processEndSendDataToDevice(device, notifyDelegate: true, hasError: false, data: data)
    }
    
    func peripheral(peripheral: CBPeripheral, didUpdateValueForCharacteristic characteristic: CBCharacteristic, error: NSError?) {
        guard state == .Connected else { return }
        guard let device = currentDevice where device.peripheral === peripheral else { return }

        if let error = error {
            logger.error("Unable to read value from read characteristic of device \(device.uid): \(error.localizedDescription)")
            processEndReceiveDataFromDevice(device, notifyDelegate: true, hasError: true, data: nil)
            return
        }
        
        guard let data = characteristic.value else {
            logger.error("Received data from device \(device.uid) but nothing to read")
            processEndReceiveDataFromDevice(device, notifyDelegate: true, hasError: true, data: nil)
            return
        }

        // notify delegate
        if extendedLog {
            logger.info("Received data \(data) from device \(device.uid)")
        }
        processEndReceiveDataFromDevice(device, notifyDelegate: true, hasError: false, data: data)
    }
    
}

// MARK: - CBCentralManagerState CustomStringConvertible

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