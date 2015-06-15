//
//  JSON.swift
//  ledger-wallet-ios
//
//  Created by Nicolas Bigot on 10/02/2015.
//  Copyright (c) 2015 Ledger. All rights reserved.
//

import Foundation

class JSON {
    
    class func JSONObjectFromData(data: NSData) -> AnyObject? {
        return NSJSONSerialization.JSONObjectWithData(data, options: nil, error: nil)
    }
    
    class func dataFromJSONObject(object: AnyObject) -> NSData? {
        return NSJSONSerialization.dataWithJSONObject(object, options: nil, error: nil)
    }
    
}