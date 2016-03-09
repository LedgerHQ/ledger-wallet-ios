//
//  WalletTransactionsAPIClient.swift
//  ledger-wallet-ios
//
//  Created by Nicolas Bigot on 03/12/2015.
//  Copyright © 2015 Ledger. All rights reserved.
//

import Foundation

final class WalletTransactionsAPIClient: APIClientType {
    
    let httpClient: HTTPClient
    private let logger = Logger.sharedInstance(name: "WalletTransactionsAPIClient")
    private let workingQueue = NSOperationQueue(name: "WalletTransactionsAPIClient", maxConcurrentOperationCount: NSOperationQueueDefaultMaxConcurrentOperationCount)
    private let servicesProvider: ServicesProviderType
    private let delegateQueue: NSOperationQueue
    
    // MARK: Transactions mangement
    
    func fetchTransactionsForAddresses(addresses: [String], completion: ([WalletTransactionContainer]?) -> Void) {
        workingQueue.addOperationWithBlock() { [weak self] in
            guard let strongSelf = self else { return }
            
            guard addresses.count > 0 else {
                strongSelf.delegateQueue.addOperationWithBlock() { completion([]) }
                return
            }
            
            let URL = strongSelf.servicesProvider.walletTransactionsURLForAddresses(addresses)
            strongSelf.httpClient.get(URL) { [weak self] data, request, response, error in
                guard let strongSelf = self else { return }
                
                guard error == nil, let data = data, JSON = JSON.JSONObjectFromData(data) as? [[String: AnyObject]] else {
                    strongSelf.logger.error("Unable to fetch or parse transactions JSON")
                    strongSelf.delegateQueue.addOperationWithBlock() { completion(nil) }
                    return
                }
                
                let transactions = WalletTransactionContainer.collectionFromJSONArray(JSON, parentObject: nil)
                strongSelf.delegateQueue.addOperationWithBlock() { completion(transactions) }
            }
        }
    }
    
    func fetchRawTransactionFromHash(hash: String, completion: (NSData?) -> Void) {
        workingQueue.addOperationWithBlock() { [weak self] in
            guard let strongSelf = self else { return }

            let URL = strongSelf.servicesProvider.walletRawTransactionURLFromHash(hash)
            strongSelf.httpClient.get(URL) { [weak self] data, request, response, error in
                guard let strongSelf = self else { return }

                guard error == nil, let
                    data = data,
                    JSON = JSON.JSONObjectFromData(data) as? [String: AnyObject],
                    rawTransaction = JSON["hex"] as? String
                else {
                    strongSelf.logger.error("Unable to fetch or parse raw transaction JSON")
                    strongSelf.delegateQueue.addOperationWithBlock() { completion(nil) }
                    return
                }

                let rawData = BTCDataFromHex(rawTransaction)
                strongSelf.delegateQueue.addOperationWithBlock() { completion(rawData) }
            }
        }
    }
    
    func pushRawTransaction(rawTransaction: NSData, completion: (Bool) -> Void) {
        workingQueue.addOperationWithBlock() { [weak self] in
            guard let strongSelf = self else { return }

            guard let tx = BTCHexFromData(rawTransaction) else {
                strongSelf.logger.error("Unable to build raw transaction string to push tx")
                strongSelf.delegateQueue.addOperationWithBlock() { completion(false) }
                return
            }
            
            let URL = strongSelf.servicesProvider.walletPushRawTransactionURL()
            strongSelf.httpClient.post(URL, parameters: ["tx": tx]) { [weak self] data, request, response, error in
                guard let strongSelf = self else { return }
                
                guard error == nil else {
                    strongSelf.logger.error("Unable to push raw transaction to network")
                    strongSelf.delegateQueue.addOperationWithBlock() { completion(false) }
                    return
                }
                
                strongSelf.delegateQueue.addOperationWithBlock() { completion(true) }
            }
        }
    }
    
    // MARK: Initialization
    
    init(servicesProvider: ServicesProviderType, delegateQueue: NSOperationQueue) {
        self.servicesProvider = servicesProvider
        self.delegateQueue = delegateQueue
        self.httpClient = HTTPClient(delegateQueue: workingQueue)
        self.httpClient.additionalHeaders = servicesProvider.httpHeaders
    }
    
}