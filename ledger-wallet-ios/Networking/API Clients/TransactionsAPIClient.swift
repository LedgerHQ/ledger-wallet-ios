//
//  TransactionsAPIClient.swift
//  ledger-wallet-ios
//
//  Created by Nicolas Bigot on 03/12/2015.
//  Copyright © 2015 Ledger. All rights reserved.
//

import Foundation

final class TransactionsAPIClient: LedgerAPIClient {
    
    private let logger = Logger.sharedInstance(name: "TransactionsAPIClient")
    
    // MARK: - Transactions mangement
    
    func fetchTransactionsForAddresses(addresses: [String], completion: ([[String: AnyObject]]?) -> Void) {
        guard addresses.count > 0 else {
            handlersQueue.addOperationWithBlock() { [weak self] in
                guard self != nil else { return }
                completion([])
            }
            return
        }
        
        let adressesString = addresses.joinWithSeparator(",")
        restClient.get("/blockchain/btc/addresses/\(adressesString)/transactions") { [weak self] data, request, response, error in
            guard let strongSelf = self else { return }
            
            guard error == nil, let data = data, JSON = JSON.JSONObjectFromData(data) as? [[String: AnyObject]] else {
                strongSelf.logger.error("Unable to fetch or parse transactions JSON")
                strongSelf.handlersQueue.addOperationWithBlock() { [weak self] in
                    guard self != nil else { return }
                    completion(nil)
                }
                return
            }
            strongSelf.handlersQueue.addOperationWithBlock() { [weak self] in
                guard self != nil else { return }
                completion(JSON)
            }
        }
    }
    
}