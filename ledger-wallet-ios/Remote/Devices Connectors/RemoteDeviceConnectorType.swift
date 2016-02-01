//
//  RemoteDeviceConnectorType.swift
//  ledger-wallet-ios
//
//  Created by Nicolas Bigot on 01/02/2016.
//  Copyright © 2016 Ledger. All rights reserved.
//

import Foundation

protocol RemoteDeviceConnectorDelegate: class {
    
    func deviceConnector(deviceConnector: RemoteDeviceConnectorType, didConnectDevice device: RemoteDeviceType)
    func deviceConnector(deviceConnector: RemoteDeviceConnectorType, didFailToConnectDevice device: RemoteDeviceType, withError error: NSError?)
    func deviceConnector(deviceConnector: RemoteDeviceConnectorType, didDisconnectDevice device: RemoteDeviceType, withError error: NSError?)
    
}

enum RemoteDeviceConnectorState {
    
    case Connecting
    case Connected
    case Disconnecting
    case Disconnected
    
}

protocol RemoteDeviceConnectorType {
    
    var connectionState: RemoteDeviceConnectorState { get }
    var connectedDevice: RemoteDeviceType? { get }
    var transportType: RemoteTransportType { get }
    
    func connectDevice(device: RemoteDeviceType)
    func disconnectDevice()
    
    init(servicesProvider: ServicesProviderType, delegateQueue: NSOperationQueue)
    
}