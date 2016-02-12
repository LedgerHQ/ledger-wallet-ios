//
//  ServicesProviderType.swift
//  ledger-wallet-ios
//
//  Created by Nicolas Bigot on 08/01/2016.
//  Copyright © 2016 Ledger. All rights reserved.
//

import Foundation

protocol ServicesProviderType {
    
    var name: String { get }
    var coinNetwork: CoinNetworkType { get }
    
    // Base URLs
    var websocketBaseURL: NSURL { get }
    var APIBaseURL: NSURL { get }
    var supportBaseURL: NSURL { get }
    
    // Endpoint URLs
    var walletEventsWebsocketURL: NSURL { get }
    var m2FAChannelsWebsocketURL: NSURL { get }
    func walletTransactionsURLForAddresses(addresses: [String]) -> NSURL
    func m2FAPushTokensURLForPairingId(pairingId: String) -> NSURL

    // Attestation keys
    var attestationKeys: [AttestationKey] { get }
    var betaAttestationKey: AttestationKey { get }
    func attestationKeyWithIDs(batchID batchID: UInt32, derivationID: UInt32, fallbackToBeta: Bool) -> AttestationKey?
    
    // HTTP headers
    var httpHeaders: [String: String] { get }
    
    // Device descriptors
    var remoteDeviceDescriptors: [RemoteDeviceDescriptorType] { get }
    var remoteBluetoothDeviceDescriptors: [RemoteBluetoothDeviceDescriptor] { get }
    
    init(coinNetwork: CoinNetworkType)
    
}

extension ServicesProviderType {
    
    var remoteBluetoothDeviceDescriptors: [RemoteBluetoothDeviceDescriptor] {
        return remoteDeviceDescriptors.flatMap({ $0 as? RemoteBluetoothDeviceDescriptor })
    }
    
    func attestationKeyWithIDs(batchID batchID: UInt32, derivationID: UInt32, fallbackToBeta: Bool) -> AttestationKey? {
        for attestationKey in attestationKeys {
            if attestationKey.batchID == batchID && attestationKey.derivationID == derivationID {
                return attestationKey
            }
        }
        if fallbackToBeta {
            return betaAttestationKey
        }
        return nil
    }
    
}