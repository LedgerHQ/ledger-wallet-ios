//
//  ApplicationContext.swift
//  ledger-wallet-ios
//
//  Created by Nicolas Bigot on 18/02/2016.
//  Copyright © 2016 Ledger. All rights reserved.
//

import Foundation

final class ApplicationContext {
    
    let identifier: String
    let servicesProvider: ServicesProviderType
    let transactionsManager: WalletTransactionsManagerType
    let deviceCommunicator: RemoteDeviceCommunicator
    
    init?(identifier: String, deviceCommunicator: RemoteDeviceCommunicator, servicesProvider: ServicesProviderType) {
        guard let transactionsManager = WalletTransactionsManager(identifier: identifier, servicesProvider: servicesProvider) else {
            return nil
        }
        
        self.identifier = identifier
        self.servicesProvider = servicesProvider
        self.transactionsManager = transactionsManager
        self.deviceCommunicator = deviceCommunicator
    }
    
}