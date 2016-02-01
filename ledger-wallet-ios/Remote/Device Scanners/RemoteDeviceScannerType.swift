//
//  RemoteDeviceScannerType.swift
//  ledger-wallet-ios
//
//  Created by Nicolas Bigot on 22/01/2016.
//  Copyright © 2016 Ledger. All rights reserved.
//

import Foundation

protocol RemoteDeviceScannerDelegate: class {
    
    func deviceScannerDidStartScanning(deviceScanner: RemoteDeviceScannerType)
    func deviceScannerDidStopScanning(deviceScanner: RemoteDeviceScannerType)
    func deviceScanner(deviceScanner: RemoteDeviceScannerType, didFindDevice: RemoteDeviceType)
    func deviceScanner(deviceScanner: RemoteDeviceScannerType, didLoseDevice: RemoteDeviceType)
    
}

protocol RemoteDeviceScannerType {
    
    var isScanning: Bool { get }
    var delegate: RemoteDeviceScannerDelegate? { get set }
    var transportType: RemoteTransportType { get }
    
    func startScanning()
    func stopScanning()
    
    init(servicesProvider: ServicesProviderType, delegateQueue: NSOperationQueue)
    
}