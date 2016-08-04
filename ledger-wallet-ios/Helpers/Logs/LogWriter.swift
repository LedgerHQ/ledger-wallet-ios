//
//  LogWriter.swift
//  ledger-wallet-ios
//
//  Created by Nicolas Bigot on 17/07/15.
//  Copyright (c) 2015 Ledger. All rights reserved.
//

import Foundation

final class LogWriter {
    
    static let sharedInstance = LogWriter()
    
    lazy private var fileHandles: [NSDate: NSFileHandle] = [:]
    lazy private var logsDirectoryPath = (ApplicationManager.sharedInstance.libraryDirectoryPath as NSString).stringByAppendingPathComponent("Logs")
    lazy private var fileManager = NSFileManager.defaultManager()
    lazy private var operationQueue: NSOperationQueue = {
        let queue = NSOperationQueue()
        queue.maxConcurrentOperationCount = 1
        queue.name = "LogFileWriter operation queue"
        return queue
    }()
    lazy private var dateFormatter: NSDateFormatter = {
       let dateFormatter = NSDateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        return dateFormatter
    }()
    
    // MARK: Public interface
    
    func storeLogEntry(logEntry: LogEntry) {
        operationQueue.addOperationWithBlock() {
            let firstMomentDate = logEntry.date.firstMomentDate()
            
            // if a file handle to store that log already exists
            if let fileHandle = self.fileHandles[firstMomentDate] {
                self.writeLogEntryToFile(logEntry, fileHandle: fileHandle)
            }
            else {
                // get log expected filepath
                let logFilepath = self.logFilepathForFirstMomentDate(firstMomentDate)
                
                // create file if not existing
                if !self.fileManager.fileExistsAtPath(logFilepath) {
                    if !self.fileManager.createFileAtPath(logFilepath, contents: nil, attributes: nil) {
                        console("LogWriter: Unable to create log file at path \(logFilepath)")
                    }
                }
        
                // try to open file
                if let fileHandle = NSFileHandle(forUpdatingAtPath: logFilepath) {
                    fileHandle.seekToEndOfFile()
                    self.fileHandles[firstMomentDate] = fileHandle
                    self.writeLogEntryToFile(logEntry, fileHandle: fileHandle)
                }
                else {
                    console("LogWriter: Unable to open log file at path \(logFilepath)")
                }
            }
        }
    }
    
    func cleanStaleLogFiles() {
        enqueueCleanLogsFilesOperation()
    }
    
    // MARK: Write management
    
    private func writeLogEntryToFile(logEntry: LogEntry, fileHandle: NSFileHandle) {
        let finalString = logEntry.description + "\n"
        if let data = finalString.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: true) {
            fileHandle.writeData(data)
        }
        else {
            console("LogWriter: Unable to save data \"\(finalString)\"")
        }
    }
    
    // MARK: Utilities
    
    private func logFilepathForFirstMomentDate(date: NSDate) -> String {
        let fileName = (logsDirectoryPath as NSString).stringByAppendingPathComponent(self.dateFormatter.stringFromDate(date))
        if let fullFileName = (fileName as NSString).stringByAppendingPathExtension("log") {
            return fullFileName
        }
        return fileName
    }
    
    private func enqueuePrepareDirectoriesOperation() {
        // enqueue prepare directories operation
        operationQueue.addOperationWithBlock() {
            if (try? self.fileManager.createDirectoryAtPath(self.logsDirectoryPath, withIntermediateDirectories: true, attributes: nil)) == nil {
                console("LogWriter: Unable to create logs directory at path \(self.logsDirectoryPath)")
            }
            let URL = NSURL(fileURLWithPath: self.logsDirectoryPath, isDirectory: true)
            if (try? URL.setResourceValue(true, forKey: NSURLIsExcludedFromBackupKey)) == nil {
                console("LogWriter: Unable to exclude logs directory from backup at path \(self.logsDirectoryPath)")
            }
        }
    }
    
    private func enqueueCleanLogsFilesOperation() {
        // enqueue clean logs file operation
        operationQueue.addOperationWithBlock() {
            // extract list of to-keep files - (most 2 recent files) roughly 48 hours of logs
            let filesToRemove: ArraySlice<String>
            if let files = (try? self.fileManager.contentsOfDirectoryAtPath(self.logsDirectoryPath)) {
                var allLogs = files.filter({$0.hasSuffix(".log")})
                allLogs.sortInPlace(<)
                filesToRemove = allLogs.prefix(max(0, allLogs.count - 2))
            }
            else {
                console("LogWriter: Unable to obtain list of files to clean from logs directory at path \(self.logsDirectoryPath)")
                return
            }
            
            // abort if no file needs to be removed
            if filesToRemove.isEmpty {
                return
            }
            
            // close all opened files
            for (_, fileHandle) in self.fileHandles {
                fileHandle.closeFile()
            }
            self.fileHandles = [:]
            
            // remove all stale files
            for file in filesToRemove {
                let filepath = (self.logsDirectoryPath as NSString).stringByAppendingPathComponent(file)
                if (try? self.fileManager.removeItemAtPath(filepath)) == nil {
                    console("LogWriter: Unable to remove log file at path \(filepath)")
                }
            }
        }
    }
    
    // MARK: Initialization
    
    private init() {
        enqueuePrepareDirectoriesOperation()
    }
}