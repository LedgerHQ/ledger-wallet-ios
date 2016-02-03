//
//  RemoteDevicesManagerType.swift
//  ledger-wallet-ios
//
//  Created by Nicolas Bigot on 02/02/2016.
//  Copyright © 2016 Ledger. All rights reserved.
//

import Foundation

enum RemoteDevicesManagerError: ErrorType {
    
    case RemoteDisconnection
    case WrongDevice
    case UnableToBind
    case UnableToRead
    case UnableToWrite
    
}

protocol RemoteDevicesManagerDelegate: class {
    
    func devicesManager(devicesManager: RemoteDevicesManagerType, didFindDevice device: RemoteDeviceType)
    func devicesManager(devicesManager: RemoteDevicesManagerType, didLoseDevice device: RemoteDeviceType)
    func devicesManager(devicesManager: RemoteDevicesManagerType, didConnectDevice device: RemoteDeviceType)
    func devicesManager(devicesManager: RemoteDevicesManagerType, didFailToConnectDevice device: RemoteDeviceType)
    func devicesManager(devicesManager: RemoteDevicesManagerType, didDisconnectDevice device: RemoteDeviceType, withError error: RemoteDevicesManagerError?)
    func devicesManager(devicesManager: RemoteDevicesManagerType, didSendData data: NSData, toDevice device: RemoteDeviceType)
    func devicesManager(devicesManager: RemoteDevicesManagerType, didReceiveData data: NSData, fromDevice device: RemoteDeviceType)
    
}

protocol RemoteDevicesManagerType: class {
    
    var isScanning: Bool { get }
    var connectionState: RemoteConnectionState { get }
    var activeDevice: RemoteDeviceType? { get }
    var delegate: RemoteDevicesManagerDelegate? { get set }
    
    func startScanning()
    func stopScanning()
    func connect(device: RemoteDeviceType)
    func disconnect()
    func send(data: NSData)
    
    init(servicesProvider: ServicesProviderType, delegateQueue: NSOperationQueue)
    
}