//
//  WalletBlock.swift
//  ledger-wallet-ios
//
//  Created by Nicolas Bigot on 12/01/2016.
//  Copyright © 2016 Ledger. All rights reserved.
//

import Foundation

struct WalletBlock {
    
    let hash: String
    let height: Int
    let time: String
    
}

// MARK: - JSONInitializableModel

extension WalletBlock: JSONInitializableModel {
    
    init?(JSONObject: [String : AnyObject]) {
        guard let
            hash = JSONObject["hash"] as? String,
        	height = JSONObject["height"] as? Int,
            time = JSONObject["time"] as? String
        else {
            return nil
        }
        
        self.hash = hash
        self.height = height
        self.time = time
    }
    
}