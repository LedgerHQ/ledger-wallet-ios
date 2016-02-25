//
//  RemoteDeviceAPIStartUntrustedHashTransactionInputTask.swift
//  ledger-wallet-ios
//
//  Created by Nicolas Bigot on 25/02/2016.
//  Copyright © 2016 Ledger. All rights reserved.
//

import Foundation

final class RemoteDeviceAPIStartUntrustedHashTransactionInputTask: RemoteDeviceAPITaskType {
    
    typealias CompletionBlock = (success: Bool, error: RemoteDeviceError?) -> Void
    
    var timeoutInterval = 0.0
    var completionBlock: (() -> Void)?
    let devicesCoordinator: RemoteDevicesCoordinator

    private var success = false
    private var pendingSlices: [NSData] = []
    private let outputScript: NSData
    private let trustedInputIndex: Int
    private let trustedInputs: [NSData]
    private let resultCompletionQueue: NSOperationQueue
    private let resultCompletionBlock: CompletionBlock

    func main() -> Bool {
        guard trustedInputs.count > 0 else { return false }
        pendingSlices = buildSlices()
        guard pendingSlices.count > 0 else { return false }
        
        sendNextPendingSlice(firstClass: true)
        return true
    }
    
    func didReceiveAPDU(APDU: RemoteAPDU) {
        if pendingSlices.count > 0 {
            sendNextPendingSlice(firstClass: false)
            return
        }
        
        success = true
        completeWithError(nil)
    }
    
    func notifyResultWithError(error: RemoteDeviceError?) {
        let completion = self.resultCompletionBlock
        let success = self.success
        self.resultCompletionQueue.addOperationWithBlock() { completion(success: success, error: error) }
    }
    
    // MARK: Slices management
    
    func sendNextPendingSlice(firstClass firstClass: Bool) {
        guard pendingSlices.count > 0 else {
            return
        }
        
        let slice = pendingSlices.removeFirst()
        guard let APDU = RemoteAPDU(classByte: 0xE0, instruction: 0x44, p1: firstClass ? 0x00 : 0x80, p2: 0x00, data: slice, responseLength: 0x00) else {
            completeWithError(.InvalidParameters)
            return
        }
        devicesCoordinator.send(APDU)
    }
    
    private func buildSlices() -> [NSData] {
        var slices: [NSData] = []
        
        slices.append(buildTransactionHeaderSlice())
        for i in 0..<trustedInputs.count {
            slices.append(buildTrustedInputSlice(currentTrustedInputIndex: i))
        }
        return slices
    }
    
    private func buildTransactionHeaderSlice() -> NSData {
        let writer = DataWriter()
        
        writer.writeNextLittleEndianUInt32(1)
        writer.writeNextVarInteger(UInt64(trustedInputs.count))
        return writer.data
    }
    
    private func buildTrustedInputSlice(currentTrustedInputIndex currentTrustedInputIndex: Int) -> NSData {
        let trustedInput = trustedInputs[currentTrustedInputIndex]
        let writer = DataWriter()
        
        writer.writeNextUInt8(0x01)
        writer.writeNextUInt8(UInt8(trustedInput.length))
        writer.writeNextData(trustedInput)
        if currentTrustedInputIndex == trustedInputIndex {
            writer.writeNextVarInteger(UInt64(outputScript.length))
            writer.writeNextData(outputScript)
        }
        else {
            writer.writeNextVarInteger(0)
        }
        writer.writeNextLittleEndianUInt32(0xFFFFFFFF)
        return writer.data
    }

    // MARK: Initialization
    
    init(trustedInputs: [NSData], trustedInputIndex: Int, outputScript: NSData, devicesCoordinator: RemoteDevicesCoordinator, completionQueue: NSOperationQueue, completion: CompletionBlock) {
        self.trustedInputIndex = trustedInputIndex
        self.trustedInputs = trustedInputs
        self.outputScript = outputScript
        self.devicesCoordinator = devicesCoordinator
        self.resultCompletionQueue = completionQueue
        self.resultCompletionBlock = completion
    }
    
}