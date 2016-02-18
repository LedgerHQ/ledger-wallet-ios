//
//  ApplicationContextManager.swift
//  ledger-wallet-ios
//
//  Created by Nicolas Bigot on 18/02/2016.
//  Copyright © 2016 Ledger. All rights reserved.
//

import Foundation

final class ApplicationContextManager {
    
    static let sharedInstance = ApplicationContextManager()
    private static let activeContextIdentifierKey = "active_context_identifier"
    private let servicesProvider: ServicesProviderType
    private let preferences = Preferences(storeName: "ApplicationContextsManager")
    private let logger = Logger.sharedInstance(name: "ApplicationContextsManager")
    private var activeContext: ApplicationContext?
    
    func getActiveContext() -> ApplicationContext? {
        if let context = activeContext {
            return context
        }

        // try to fetch saved identifier
        guard let identifier = preferences.stringForKey(self.dynamicType.activeContextIdentifierKey) else {
            return nil
        }
        
        // build context from identifier
        guard let context = ApplicationContext(identifier: identifier, deviceCommunicator: vendRemoteDeviceCommunicator(), servicesProvider: servicesProvider) else {
            logger.error("Failed to build context to get active context with identifier \(identifier)")
            return nil
        }
        
        // retain context
        activeContext = context
        return activeContext
    }
    
    func persistActiveContext(identifier: String, deviceCommunicator: RemoteDeviceCommunicator) -> Bool {
        // try to fetch saved identifier
        guard activeContext == nil && preferences.stringForKey(self.dynamicType.activeContextIdentifierKey) == nil else {
            logger.error("Cannot persist active context with identifier \(identifier), already active context persisted")
            return false
        }
        
        // build context from identifier
        guard let context = ApplicationContext(identifier: identifier, deviceCommunicator: deviceCommunicator, servicesProvider: servicesProvider) else {
            logger.error("Failed to build context to persist active context with identifier \(identifier)")
            return false
        }
        
        logger.info("Persisting active context with identifier \(identifier)")
        preferences.setString(context.identifier, forKey: self.dynamicType.activeContextIdentifierKey)
        activeContext = context
        return true
    }
    
    func removeActiveContext() {
        logger.info("Removing active context, if present")
        preferences.removeObjectForKey(self.dynamicType.activeContextIdentifierKey)
        activeContext = nil
    }
    
    func vendRemoteDeviceCommunicator() -> RemoteDeviceCommunicator {
        return RemoteDeviceCommunicator(servicesProvider: servicesProvider)
    }
    
    // MARK: Initialization
    
    private init() {
        self.servicesProvider = LedgerServicesProvider(coinNetwork: BitcoinNetwork())
    }
}