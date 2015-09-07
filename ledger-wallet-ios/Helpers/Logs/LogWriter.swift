//
//  LogWriter.swift
//  ledger-wallet-ios
//
//  Created by Nicolas Bigot on 17/07/15.
//  Copyright (c) 2015 Ledger. All rights reserved.
//

import Foundation

final class LogWriter: SharableObject {
    
    lazy private var fileHandles: [NSDate: NSFileHandle] = [:]
    lazy private var logsDirectoryPath = ApplicationManager.sharedInstance().libraryDirectoryPath.stringByAppendingPathComponent("Logs")
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
    
    func exportLogsToData(#sequentially: Bool, sequence: ((NSData) -> Void)? = nil, completion: ((NSData?) -> Void)) {
        // enqueue export logs operation
        operationQueue.addOperationWithBlock() {
            // extract list of to-export files - (most 2 recent files) roughly 48 hours of logs
            let filesToExport: ArraySlice<String>
            if let files = self.fileManager.contentsOfDirectoryAtPath(self.logsDirectoryPath, error: nil) as? [String] {
                var allLogs = files.filter({$0.hasSuffix(".log")})
                allLogs.sort(<)
                filesToExport = suffix(allLogs, 2)
            }
            else {
                console("LogWriter: Unable to obtain list of files to export from logs directory at path \(self.logsDirectoryPath)")
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
                let filepath = self.logsDirectoryPath.stringByAppendingPathComponent(file)
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
    
    func exportLogsToFile(#autoremove: Bool, completion: (ephemeralFilepath: String?) -> Void) {
        let uuid = NSUUID().UUIDString
        let temporypath = ApplicationManager.sharedInstance().temporaryDirectoryPath
        let filepath = temporypath.stringByAppendingPathComponent(uuid).stringByAppendingPathExtension("txt")!
        
        // remove file if it already exists (shouldnt happen)
        if self.fileManager.fileExistsAtPath(filepath) {
            if !self.fileManager.removeItemAtPath(filepath, error: nil) {
                console("LogWriter: Unable to remove already existing exported empeheral log file at path \(filepath)")
                completion(ephemeralFilepath: nil)
                return
            }
        }
        if !self.fileManager.createFileAtPath(filepath, contents: nil, attributes: nil) {
            console("LogWriter: Unable to create empeheral log file at path \(filepath)")
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
                        self.fileManager.removeItemAtPath(filepath, error: nil) // try to remove file
                    }
                }
                else {
                    console("LogWriter: Unable to write to empeheral log file at path \(filepath)")
                    self.fileManager.removeItemAtPath(filepath, error: nil) // try to remove file
                    completion(ephemeralFilepath: nil)
                }
            })
        }
        else {
            console("LogWriter: Unable to open empeheral log file for writing at path \(filepath)")
            self.fileManager.removeItemAtPath(filepath, error: nil) // try to remove file
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
            console("LogWriter: Unable to save data \"\(finalString)\"")
        }
    }
    
    // MARK: Utilities
    
    private func logFilepathForFirstMomentDate(date: NSDate) -> String {
        let fileName = logsDirectoryPath.stringByAppendingPathComponent(self.dateFormatter.stringFromDate(date))
        if let fullFileName = fileName.stringByAppendingPathExtension("log") {
            return fullFileName
        }
        return fileName
    }
    
    private func enqueuePrepareDirectoriesOperation() {
        // enqueue prepare directories operation
        operationQueue.addOperationWithBlock() {
            if !self.fileManager.createDirectoryAtPath(self.logsDirectoryPath, withIntermediateDirectories: true, attributes: nil, error: nil) {
                console("LogWriter: Unable to create logs directory at path \(self.logsDirectoryPath)")
            }
            let URL = NSURL(fileURLWithPath: self.logsDirectoryPath, isDirectory: true)
            if URL == nil || !URL!.setResourceValue(true, forKey: NSURLIsExcludedFromBackupKey, error: nil) {
                console("LogWriter: Unable to exclude logs directory from backup at path \(self.logsDirectoryPath)")
            }
        }
    }
    
    private func enqueueCleanLogsFilesOperation() {
        // enqueue clean logs file operation
        operationQueue.addOperationWithBlock() {
            // extract list of to-keep files - (most 2 recent files) roughly 48 hours of logs
            let filesToRemove: ArraySlice<String>
            if let files = self.fileManager.contentsOfDirectoryAtPath(self.logsDirectoryPath, error: nil) as? [String] {
                var allLogs = files.filter({$0.hasSuffix(".log")})
                allLogs.sort(<)
                filesToRemove = prefix(allLogs, max(0, allLogs.count - 2))
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
            for (date, fileHandle) in self.fileHandles {
                fileHandle.closeFile()
            }
            self.fileHandles = [:]
            
            // remove all stale files
            for file in filesToRemove {
                let filepath = self.logsDirectoryPath.stringByAppendingPathComponent(file)
                if !self.fileManager.removeItemAtPath(filepath, error: nil) {
                    console("LogWriter: Unable to remove log file at path \(filepath)")
                }
            }
        }
    }
    
    // MARK: Initialization
    
    required init() {
        super.init()
        
        enqueuePrepareDirectoriesOperation()
    }
}