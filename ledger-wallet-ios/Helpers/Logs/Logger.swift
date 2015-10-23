//
//  Logger.swift
//  ledger-wallet-ios
//
//  Created by Nicolas Bigot on 16/07/15.
//  Copyright (c) 2015 Ledger. All rights reserved.
//

import Foundation

final class Logger {
    
    let name: String
    private static var instancesQueue = dispatch_queue_create("co.ledger.logger.dispatch-queue", DISPATCH_QUEUE_SERIAL)
    private static var instances: [String: Logger] = [:]
    
    // MARK: - Log methods
    
    func debug(string: String) {
        log(string, level: .Debug)
    }
    
    func info(string: String) {
        log(string, level: .Info)
    }
    
    func warn(string: String) {
        log(string, level: .Warn)
    }
    
    func error(string: String) {
        log(string, level: .Error)
    }
    
    // MARK: Log utils
    
    private func log(string: String, level: LogLevel) {
        // build entry from string and level
        let logEntry = buildLogEntry(string, logLevel: level)
        
        // log to console if app is in debug
        if ApplicationManager.sharedInstance.isInDebug {
            console(logEntry)
        }
        
        // log to file
        LogWriter.sharedInstance.storeLogEntry(logEntry)
    }
    
    private func buildLogEntry(string: String, logLevel: LogLevel) -> LogEntry {
        return LogEntry(string: string, level: logLevel, loggerName: self.name)
    }
    
    // MARK: - Initialization
    
    class func sharedInstance(name name: String) -> Logger {
        dispatch_sync(instancesQueue) {
            if self.instances[name] == nil {
                self.instances[name] = Logger(name: name)
            }
        }
        return instances[name]!
    }
    
    private init(name: String) {
        self.name = name
    }
    
}