//
//  LogEntry.swift
//  ledger-wallet-ios
//
//  Created by Nicolas Bigot on 16/07/15.
//  Copyright (c) 2015 Ledger. All rights reserved.
//

import Foundation

struct LogEntry {
    
    let string: String
    let date: NSDate
    let level: LogLevel
    let loggerName: String
    
    init(string: String, level: LogLevel, loggerName: String) {
        self.string = string
        self.date = NSDate()
        self.level = level
        self.loggerName = loggerName
    }
    
}

// MARK: - Equatable

extension LogEntry: Equatable {}

func ==(lhs: LogEntry, rhs: LogEntry) -> Bool {
    return lhs.string == rhs.string && lhs.date == rhs.date &&
    lhs.level == rhs.level && lhs.loggerName == rhs.loggerName
}

// MARK: - CustomStringConvertible

extension LogEntry: CustomStringConvertible {

    var description: String {
        return "\(date) [\(loggerName)][\(level)] \(string)"
    }

}

// MARK: - CustomDebugStringConvertible

extension LogEntry: CustomDebugStringConvertible {
    
    var debugDescription: String {
        return "[\(loggerName)][\(level)] \(string)"
    }
    
}