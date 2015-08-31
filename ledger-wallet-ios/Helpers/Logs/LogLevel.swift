//
//  LogLevel.swift
//  ledger-wallet-ios
//
//  Created by Nicolas Bigot on 17/07/15.
//  Copyright (c) 2015 Ledger. All rights reserved.
//

import Foundation

enum LogLevel: Int {
    case Debug, Info, Warn, Error
}

extension LogLevel: Printable {
    
    var description: String {
        switch self {
        case .Debug: return "Debug"
        case .Info: return "Info"
        case .Warn: return "Warn"
        case .Error: return "Error"
        }
    }
    
}