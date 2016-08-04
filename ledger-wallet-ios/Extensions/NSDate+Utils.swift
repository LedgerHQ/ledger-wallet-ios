//
//  NSDate+Utils.swift
//  ledger-wallet-ios
//
//  Created by Nicolas Bigot on 20/07/15.
//  Copyright (c) 2015 Ledger. All rights reserved.
//

import Foundation

extension NSDate {
    
    func firstMomentDate() -> NSDate {
        let calendar = NSCalendar.currentCalendar()
        let comps = calendar.components([.Year, .Month, .Day, .Hour, .Minute, .Second], fromDate: self)
        
        comps.hour = 0
        comps.minute = 0
        comps.second = 0
        return calendar.dateFromComponents(comps)!
    }
    
}