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
    private lazy var fileHandles: [NSDate: NSFileHandle] = [:]
    private lazy var logsDirectoryPath = ApplicationManager.sharedInstance.logsDirectoryPath
    private lazy var fileManager = NSFileManager.defaultManager()
    private lazy var operationQueue: NSOperationQueue = {
        let queue = NSOperationQueue()
        queue.maxConcurrentOperationCount = 1
        queue.name = "LogFileWriter operation queue"
        return queue
    }()
    private lazy var dateFormatter: NSDateFormatter = {
       let dateFormatter = NSDateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        return dateFormatter
    }()
    
    // MARK: Public interface
    
    func storeLogEntry(logEntry: LogEntry) {
        operationQueue.addOperationWithBlock() {
            let firstMomentDate = NSCalendar.currentCalendar().startOfDayForDate(logEntry.date)
            
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
                        NSLog("LogWriter: Unable to create log file at path \(logFilepath)")
                    }
                }
        
                // try to open file
                if let fileHandle = NSFileHandle(forUpdatingAtPath: logFilepath) {
                    fileHandle.seekToEndOfFile()
                    self.fileHandles[firstMomentDate] = fileHandle
                    self.writeLogEntryToFile(logEntry, fileHandle: fileHandle)
                }
                else {
                    NSLog("LogWriter: Unable to open log file at path \(logFilepath)")
                }
            }
        }
    }
    
    func cleanStaleLogFiles() {
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
                NSLog("LogWriter: Unable to obtain list of files to clean from logs directory at path \(self.logsDirectoryPath)")
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
                do {
                    try self.fileManager.removeItemAtPath(filepath)
                } catch _ {
                    NSLog("LogWriter: Unable to remove log file at path \(filepath)")
                }
            }
        }
    }
    
    func exportLogsToData(sequentially sequentially: Bool, sequence: ((NSData) -> Void)? = nil, completion: ((NSData?) -> Void)) {
        // enqueue export logs operation
        operationQueue.addOperationWithBlock() {
            // extract list of to-export files - (most 2 recent files) roughly 48 hours of logs
            let filesToExport: ArraySlice<String>
            if let files = (try? self.fileManager.contentsOfDirectoryAtPath(self.logsDirectoryPath)) {
                var allLogs = files.filter({$0.hasSuffix(".log")})
                allLogs.sortInPlace(<)
                filesToExport = allLogs.suffix(2)
            }
            else {
                NSLog("LogWriter: Unable to obtain list of files to export from logs directory at path \(self.logsDirectoryPath)")
                return
            }
            
            // abort if no file needs to be exported
            if filesToExport.isEmpty {
                dispatchAsyncOnMainQueue() {
                    completion(NSData())
                }
                return
            }
            
            // build final NSData
            let finalData = NSMutableData()
            for file in filesToExport {
                let filepath = (self.logsDirectoryPath as NSString).stringByAppendingPathComponent(file)
                if let fileData = self.fileManager.contentsAtPath(filepath) {
                    if sequentially == true {
                        dispatchAsyncOnMainQueue() {
                            sequence?(fileData)
                        }
                    }
                    else {
                        finalData.appendData(fileData)
                    }
                }
            }
            dispatchAsyncOnMainQueue() {
                completion(sequentially == true ? nil : finalData)
            }
        }
    }
    
    func exportLogsToFile(autoremove autoremove: Bool, completion: (ephemeralFilepath: String?) -> Void) {
        let uuid = NSUUID().UUIDString
        let temporypath = ApplicationManager.sharedInstance.temporaryDirectoryPath
        let filepath = ((temporypath as NSString).stringByAppendingPathComponent(uuid) as NSString).stringByAppendingPathExtension("txt")!
        
        // remove file if it already exists (shouldn't happen)
        if self.fileManager.fileExistsAtPath(filepath) {
            do {
                try self.fileManager.removeItemAtPath(filepath)
            } catch _ {
                NSLog("LogWriter: Unable to remove already existing exported empeheral log file at path \(filepath)")
                completion(ephemeralFilepath: nil)
                return
            }
        }
        if !self.fileManager.createFileAtPath(filepath, contents: nil, attributes: nil) {
            NSLog("LogWriter: Unable to create empeheral log file at path \(filepath)")
            completion(ephemeralFilepath: nil)
            return
        }
        
        // create file handle
        if let fileHandle = NSFileHandle(forWritingAtPath: filepath) {
            // export logs
            exportLogsToData(sequentially: true, sequence: { data in
                fileHandle.writeData(data)
            }, completion: { data in
                let writtenBytes = fileHandle.offsetInFile
                fileHandle.closeFile()
                
                // if exported data was not empty (nothing to export)
                if data == nil && writtenBytes > 0 {
                    completion(ephemeralFilepath: filepath)
                    if autoremove == true {
                        do {
                            try self.fileManager.removeItemAtPath(filepath)
                        } catch _ {
                        } // try to remove file
                    }
                }
                else {
                    NSLog("LogWriter: Unable to write to empeheral log file at path \(filepath)")
                    do {
                        try self.fileManager.removeItemAtPath(filepath)
                    } catch _ {
                    } // try to remove file
                    completion(ephemeralFilepath: nil)
                }
            })
        }
        else {
            NSLog("LogWriter: Unable to open empeheral log file for writing at path \(filepath)")
            do {
                try self.fileManager.removeItemAtPath(filepath)
            } catch _ {
            } // try to remove file
            completion(ephemeralFilepath: nil)
        }
    }
    
    // MARK: Write management
    
    private func writeLogEntryToFile(logEntry: LogEntry, fileHandle: NSFileHandle) {
        let finalString = logEntry.description + "\n"
        if let data = finalString.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: true) {
            fileHandle.writeData(data)
        }
        else {
            NSLog("LogWriter: Unable to save data \"\(finalString)\"")
        }
    }
    
    // MARK: Utilities
    
    private func logFilepathForFirstMomentDate(date: NSDate) -> String {
        let fileName = (logsDirectoryPath as NSString).stringByAppendingPathComponent(self.dateFormatter.stringFromDate(date))
        let fullFileName = (fileName as NSString).stringByAppendingPathExtension("log")
        return fullFileName!
    }
    
    private func enqueuePrepareDirectoriesOperation() {
        // enqueue prepare directories operation
        operationQueue.addOperationWithBlock() {
            do {
                try self.fileManager.createDirectoryAtPath(self.logsDirectoryPath, withIntermediateDirectories: true, attributes: nil)
            }
            catch _ {
                NSLog("LogWriter: Unable to create logs directory at path \(self.logsDirectoryPath)")
            }
            let URL = NSURL(fileURLWithPath: self.logsDirectoryPath, isDirectory: true)
            do {
                try URL.setResourceValue(true, forKey: NSURLIsExcludedFromBackupKey)
            }
            catch _ {
                NSLog("LogWriter: Unable to exclude logs directory from backup at path \(self.logsDirectoryPath)")
            }
        }
    }
    
    // MARK: Initialization
    
    private init() {
        enqueuePrepareDirectoriesOperation()
    }

}