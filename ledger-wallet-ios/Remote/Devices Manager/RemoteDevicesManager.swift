//
//  RemoteDevicesManager.swift
//  ledger-wallet-ios
//
//  Created by Nicolas Bigot on 22/01/2016.
//  Copyright © 2016 Ledger. All rights reserved.
//

import Foundation


final class RemoteDevicesManager {
    
    private let delegateQueue: NSOperationQueue
    private var scanning = false
    private let scanners: [RemoteDeviceScannerType]
    private let workingQueue = NSOperationQueue(name: "RemoteDevicesManager", maxConcurrentOperationCount: 1)
    private let logger = Logger.sharedInstance(name: "RemoteDevicesManager")
    
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
            strongSelf.scanners.forEach({ $0.startScanning() })
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
            strongSelf.scanners.forEach({ $0.stopScanning() })
        }
        workingQueue.waitUntilAllOperationsAreFinished()
    }
    
    // MARK: Initialization
    
    init(servicesProvider: ServicesProviderType, delegateQueue: NSOperationQueue) {
        self.delegateQueue = delegateQueue

        let bluetoothScanner = RemoteBluetoothDeviceScanner(servicesProvider: servicesProvider, delegateQueue: workingQueue)
        self.scanners = [bluetoothScanner]
        
        bluetoothScanner.delegate = self
    }
    
    deinit {
        stopScanning()
    }
    
}

// MARK: - RemoteDeviceScannerDelegate

extension RemoteDevicesManager: RemoteDeviceScannerDelegate {
    
    func deviceScannerDidStartScanning(deviceScanner: RemoteDeviceScannerType) {
        
    }
    
    func deviceScannerDidStopScanning(deviceScanner: RemoteDeviceScannerType) {
        
    }
    
    func deviceScanner(deviceScanner: RemoteDeviceScannerType, didFindDevice: RemoteDeviceType) {
        
    }

    func deviceScanner(deviceScanner: RemoteDeviceScannerType, didLoseDevice: RemoteDeviceType) {
        
    }
    
}