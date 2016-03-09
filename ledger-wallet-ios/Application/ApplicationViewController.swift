//
//  ApplicationWalletViewController.swift
//  ledger-wallet-ios
//
//  Created by Nicolas Bigot on 19/02/2016.
//  Copyright © 2016 Ledger. All rights reserved.
//

import Foundation

class ApplicationViewController: UIViewController {
    
    private var observers: [NSObjectProtocol] = []
    
    var context: ApplicationContext? = nil {
        didSet {
            self.listenNotifications(context != nil)
            self.handleNewContext(context)
        }
    }
    
    private func listenNotifications(listen: Bool) {
        if listen {
            if let context = context {
                observers.append(NSNotificationCenter.defaultCenter().addObserverForName(WalletTransactionsManagerDidUpdateAccountsNotification, object: context.transactionsManager, queue: NSOperationQueue.mainQueue()) { [weak self] notification in
                    guard let strongSelf = self else { return }
                
                    strongSelf.handleDidUpdateAccounts()
                })
                observers.append(NSNotificationCenter.defaultCenter().addObserverForName(WalletTransactionsManagerDidUpdateOperationsNotification, object: context.transactionsManager, queue: NSOperationQueue.mainQueue()) { [weak self] notification in
                    guard let strongSelf = self else { return }
                    
                    strongSelf.handleDidUpdateOperations()
                })
                observers.append(NSNotificationCenter.defaultCenter().addObserverForName(WalletTransactionsManagerDidStartRefreshingTransactionsNotification, object: context.transactionsManager, queue: NSOperationQueue.mainQueue()) { [weak self] notification in
                    guard let strongSelf = self else { return }
                    
                    strongSelf.handleDidStartRefreshingTransactions()
                })
                observers.append(NSNotificationCenter.defaultCenter().addObserverForName(WalletTransactionsManagerDidStopRefreshingTransactionsNotification, object: context.transactionsManager, queue: NSOperationQueue.mainQueue()) { [weak self] notification in
                    guard let strongSelf = self else { return }
                    
                    strongSelf.handleDidStopRefreshingTransactions()
                })
                observers.append(NSNotificationCenter.defaultCenter().addObserverForName(WalletTransactionsManagerDidMissAccountNotification, object: context.transactionsManager, queue: NSOperationQueue.mainQueue()) { [weak self] notification in
                    guard let strongSelf = self else { return }
                    
                    if let request = notification.userInfo?[WalletTransactionsManagerMissingAccountRequestKey] as? WalletMissingAccountRequest {
                        strongSelf.handleDidMissAccount(request)
                    }
                })
            }
        }
        else {
            observers.forEach(NSNotificationCenter.defaultCenter().removeObserver)
        }
    }
    
    func handleNewContext(context: ApplicationContext?) {
        
    }
    
    func handleDidUpdateAccounts() {
        
    }
    
    func handleDidUpdateOperations() {
        
    }
    
    func handleDidStartRefreshingTransactions() {
        
    }
    
    func handleDidStopRefreshingTransactions() {
        
    }
    
    func handleDidMissAccount(request: WalletMissingAccountRequest) {

    }
    
    func ensureDeviceIsConnected(completion: (RemoteDeviceAPI?) -> Void) {
        if let deviceAPI = context?.deviceCommunicator.deviceAPI {
            completion(deviceAPI)
            return
        }
        
        let remoteViewController = ApplicationRemoteDeviceViewController.instantiateFromMainStoryboard()
        remoteViewController.acceptableIdentifier = context?.identifier
        remoteViewController.deviceCommunicator = context?.deviceCommunicator
        remoteViewController.completionBlock = { success, deviceCommunicator, identifier in
            guard success == true, let deviceAPI = deviceCommunicator?.deviceAPI else {
                completion(nil)
                return
            }
            completion(deviceAPI)
        }
        presentViewController(remoteViewController, animated: true, completion: nil)
    }
}