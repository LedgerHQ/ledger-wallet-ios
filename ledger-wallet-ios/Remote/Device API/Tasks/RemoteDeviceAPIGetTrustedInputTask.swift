//
//  RemoteDeviceAPIGetTrustedInput.swift
//  ledger-wallet-ios
//
//  Created by Nicolas Bigot on 24/02/2016.
//  Copyright © 2016 Ledger. All rights reserved.
//

import Foundation

final class RemoteDeviceAPIGetTrustedInputTask: RemoteDeviceAPITaskType {
    
    typealias CompletionBlock = (trustedInput: NSData?, error: RemoteDeviceError?) -> Void
    
    var timeoutInterval = 0.0
    var completionBlock: (() -> Void)?
    let devicesCoordinator: RemoteDevicesCoordinator
    
    private var trustedInput: NSData?
    private var pendingSlices: [NSData] = []
    private let rawTransaction: NSData
    private let outputIndex: UInt32
    private let resultCompletionQueue: NSOperationQueue
    private let resultCompletionBlock: CompletionBlock

    func main() -> Bool {
        pendingSlices = sliceRawTransaction(rawTransaction, outputIndex: outputIndex)
        guard pendingSlices.count > 0 else { return false }
        
        sendNextPendingSlice(firstCall: true)
        return true
    }
    
    func didReceiveAPDU(APDU: RemoteAPDU) {
        if pendingSlices.count > 0 {
            sendNextPendingSlice(firstCall: false)
            return
        }
        
        guard let responseData = APDU.responseData where responseData.length == 56 else {
            completeWithError(.InvalidResponse)
            return
        }
        
        trustedInput = responseData
        completeWithError(nil)
    }
    
    func notifyResultWithError(error: RemoteDeviceError?) {
        let completionBlock = self.resultCompletionBlock
        let trustedInput = self.trustedInput
        self.resultCompletionQueue.addOperationWithBlock() { completionBlock(trustedInput: trustedInput, error: error) }
    }
    
    // MARK: Slices management
    
    private func sendNextPendingSlice(firstCall firstCall: Bool) {
        guard pendingSlices.count > 0 else {
            return
        }
        
        let slice = pendingSlices.removeFirst()
        guard let APDU = RemoteAPDU(classByte: 0xE0, instruction: 0x42, p1: firstCall ? 0x00 : 0x80, p2: 0x00, data: slice, responseLength: 0x00) else {
            completeWithError(.InvalidParameters)
            return
        }
        devicesCoordinator.send(APDU)
    }
    
    private func sliceRawTransaction(rawTransaction: NSData, splitSize: Int = Int(UInt8.max), outputIndex: UInt32) -> [NSData] {
        let reader = DataReader(data: rawTransaction)
        var slices: [NSData] = []
        
        // output index
        let writer = DataWriter()
        writer.writeNextBigEndianUInt32(outputIndex)
        
        // transaction
        var numberOfInputs: UInt64 = 0
        var numberOfOutputs: UInt64 = 0
        if let slice = parseTransactionHeader(reader, numberOfInputs: &numberOfInputs) { writer.writeNextData(slice); slices.append(writer.data) } else { return [] }
        for _ in 0..<numberOfInputs {
            var scriptLength: UInt64 = 0
            if let header = parseInputHeader(reader, scriptLength: &scriptLength) { slices.append(header) } else { return [] }
            if let script = parseInputScript(reader, length: scriptLength) { slices.appendContentsOf(script) } else { return [] }
        }
        if let slice = parseNumberOfOutputs(reader, numberOfOutputs: &numberOfOutputs) { slices.append(slice) } else { return [] }
        for _ in 0..<numberOfOutputs {
            var scriptLength: UInt64 = 0
            if let header = parseOutputHeader(reader, scriptLength: &scriptLength) { slices.append(header) } else { return [] }
            if let script = parseOutputScript(reader, length: scriptLength) { slices.appendContentsOf(script) } else { return [] }
        }
        if let slice = parseTransactionFooter(reader) { slices.append(slice) } else { return [] }
        return slices
    }
    
    private func parseTransactionHeader(reader: DataReader, inout numberOfInputs: UInt64) -> NSData? {
        guard let
            version = reader.readNextLittleEndianUInt32(),
            inputsCount = reader.readNextVarInteger()
        else {
            return nil
        }
        
        let writer = DataWriter()
        writer.writeNextLittleEndianUInt32(version)
        writer.writeNextVarInteger(inputsCount)
        numberOfInputs = inputsCount
        return writer.data
    }
    
    private func parseInputHeader(reader: DataReader, inout scriptLength: UInt64) -> NSData? {
        guard let
            transactionHash = reader.readNextDataOfLength(32),
            outputIndex = reader.readNextLittleEndianUInt32(),
            scriptSize = reader.readNextVarInteger()
        else {
            return nil
        }
        
        let writer = DataWriter()
        writer.writeNextData(transactionHash)
        writer.writeNextLittleEndianUInt32(outputIndex)
        writer.writeNextVarInteger(scriptSize)
        scriptLength = scriptSize
        return writer.data
    }
    
    private func parseInputScript(reader: DataReader, length: UInt64) -> [NSData]? {
        guard let
            script = reader.readNextDataOfLength(Int(length)),
            sequence = reader.readNextLittleEndianUInt32()
        else {
            return nil
        }
        
        let writer = DataWriter()
        writer.writeNextData(script)
        writer.writeNextLittleEndianUInt32(sequence)
        return writer.data.splitWithSize(Int(UInt8.max))
    }
    
    private func parseNumberOfOutputs(reader: DataReader, inout numberOfOutputs: UInt64) -> NSData? {
        guard let
            outputsCount = reader.readNextVarInteger()
        else {
            return nil
        }
        
        let writer = DataWriter()
        writer.writeNextVarInteger(outputsCount)
        numberOfOutputs = outputsCount
        return writer.data
    }
    
    private func parseOutputHeader(reader: DataReader, inout scriptLength: UInt64) -> NSData? {
        guard let
            value = reader.readNextLittleEndianUInt64(),
            scriptSize = reader.readNextVarInteger()
            else {
                return nil
        }
        
        let writer = DataWriter()
        writer.writeNextLittleEndianUInt64(value)
        writer.writeNextVarInteger(scriptSize)
        scriptLength = scriptSize
        return writer.data
    }
    
    private func parseOutputScript(reader: DataReader, length: UInt64) -> [NSData]? {
        guard let
            script = reader.readNextDataOfLength(Int(length))
        else {
            return nil
        }
        
        let writer = DataWriter()
        writer.writeNextData(script)
        return writer.data.splitWithSize(Int(UInt8.max))
    }
    
    private func parseTransactionFooter(reader: DataReader) -> NSData? {
        guard let
            lockTime = reader.readNextLittleEndianUInt32()
        else {
            return nil
        }
        
        let writer = DataWriter()
        writer.writeNextLittleEndianUInt32(lockTime)
        return writer.data
    }
    
    // MARK: Initialization
    
    init(rawTransaction: NSData, outputIndex: UInt32, devicesCoordinator: RemoteDevicesCoordinator, completionQueue: NSOperationQueue, completion: CompletionBlock) {
        self.rawTransaction = rawTransaction
        self.outputIndex = outputIndex
        self.devicesCoordinator = devicesCoordinator
        self.resultCompletionQueue = completionQueue
        self.resultCompletionBlock = completion
    }
    
}