//
//  RemoteDeviceAPIFinalizeFullUntrustedHashTransactionInputTask.swift
//  ledger-wallet-ios
//
//  Created by Nicolas Bigot on 25/02/2016.
//  Copyright © 2016 Ledger. All rights reserved.
//

import Foundation

final class RemoteDeviceAPIFinalizeFullUntrustedHashTransactionInputTask: RemoteDeviceAPITaskType {
    
    typealias CompletionBlock = (success: Bool, error: RemoteDeviceError?) -> Void
    
    var timeoutInterval = 0.0
    var completionBlock: (() -> Void)?
    let devicesCoordinator: RemoteDevicesCoordinator
    
    private var success = false
    private let spendableOutputs: [WalletSpendableTransactionOutput]
    private let changeOutput: WalletSpendableTransactionOutput?
    private var pendingAPDUs: [RemoteAPDU] = []
    private let resultCompletionQueue: NSOperationQueue
    private let resultCompletionBlock: CompletionBlock
    
    func main() -> Bool {
        guard spendableOutputs.count > 0 else { return false }
        guard let pendingAPDUs = buildAPDUs() else { return false }
        self.pendingAPDUs = pendingAPDUs
        
        sendNextPendingAPDU()
        return true
    }
    
    func didReceiveAPDU(APDU: RemoteAPDU) {
        if pendingAPDUs.count > 0 {
            sendNextPendingAPDU()
            return
        }
        
        guard let responseData = APDU.responseData else {
            completeWithError(.InvalidResponse)
            return
        }
        
        let reader = DataReader(data: responseData)
        guard let
            RFU = reader.readNextUInt8(),
            validationFlag = reader.readNextUInt8()
        where
            RFU == 0x00 && validationFlag == 0x00
        else {
            completeWithError(.InvalidResponse)
            return
        }
        
        success = true
        completeWithError(nil)
    }
    
    func notifyResultWithError(error: RemoteDeviceError?) {
        let completionBlock = self.resultCompletionBlock
        let success = self.success
        self.resultCompletionQueue.addOperationWithBlock() { completionBlock(success: success, error: error) }
    }
    
    // MARK: APDU management
    
    private func sendNextPendingAPDU() {
        guard pendingAPDUs.count > 0 else { return }
        
        let APDU = pendingAPDUs.removeFirst()
        devicesCoordinator.send(APDU)
    }
    
    private func buildAPDUs() -> [RemoteAPDU]? {
        var APDUs: [RemoteAPDU] = []
        
        if let changeAPDU = buildChangeIndexesAPDU() { APDUs.append(changeAPDU) } else { return nil }
        if let numberOfOutputsAPDU = buildNumberOfOutputsAPDU() { APDUs.append(numberOfOutputsAPDU) } else { return nil }
        for (index, output) in spendableOutputs.enumerate() {
            if let outputHeaderAPDU = buildOutputHeaderAPDU(output) { APDUs.append(outputHeaderAPDU) } else { return nil }
            if let outputScriptAPDUs = buildOutputScriptAPDUs(output, lastOutput: index == spendableOutputs.count - 1) { APDUs.appendContentsOf(outputScriptAPDUs) } else { return nil }
        }
        return APDUs
    }

    private func buildChangeIndexesAPDU() -> RemoteAPDU? {
        let writer = DataWriter()
        
        if let changeOutput = changeOutput, changeAddress = changeOutput.address {
            writer.writeNextUInt8(UInt8(changeAddress.path.depth))
            changeAddress.path.derivationIndexes.forEach({ writer.writeNextBigEndianUInt32($0) })
        }
        else {
            writer.writeNextUInt8(0x00)
        }
        guard let APDU = RemoteAPDU(classByte: 0xE0, instruction: 0x4A, p1: 0xFF, p2: 0x00, data: writer.data, responseLength: 0x00) else {
            return nil
        }
        return APDU
    }
    
    private func buildNumberOfOutputsAPDU() -> RemoteAPDU? {
        let writer = DataWriter()
        writer.writeNextVarInteger(UInt64(spendableOutputs.count))
        
        guard let APDU = RemoteAPDU(classByte: 0xE0, instruction: 0x4A, p1: 0x00, p2: 0x00, data: writer.data, responseLength: 0x00) else {
            return nil
        }
        return APDU
    }
    
    private func buildOutputHeaderAPDU(output: WalletSpendableTransactionOutput) -> RemoteAPDU? {
        let writer = DataWriter()
        writer.writeNextLittleEndianInt64(output.amount)
        writer.writeNextVarInteger(UInt64(output.script.length))
        
        guard let APDU = RemoteAPDU(classByte: 0xE0, instruction: 0x4A, p1: 0x00, p2: 0x00, data: writer.data, responseLength: 0x00) else {
            return nil
        }
        return APDU
    }
    
    private func buildOutputScriptAPDUs(output: WalletSpendableTransactionOutput, lastOutput: Bool) -> [RemoteAPDU]? {
        let slices = output.script.splitWithSize(Int(UInt8.max))
        guard slices.count > 0 else { return nil }
        var APDUs: [RemoteAPDU] = []
        
        for (index, slice) in slices.enumerate() {
            guard let APDU = RemoteAPDU(classByte: 0xE0, instruction: 0x4A, p1: lastOutput && index == slices.count - 1 ? 0x80 : 0x00, p2: 0x00, data: slice, responseLength: 0x00) else {
                return nil
            }
            APDUs.append(APDU)
        }
        return APDUs
    }
    
    // MARK: Initialization
    
    init(spendableOutputs: [WalletSpendableTransactionOutput], changeOutput: WalletSpendableTransactionOutput?, devicesCoordinator: RemoteDevicesCoordinator, completionQueue: NSOperationQueue, completion: CompletionBlock) {
        self.spendableOutputs = spendableOutputs
        self.changeOutput = changeOutput
        self.devicesCoordinator = devicesCoordinator
        self.resultCompletionQueue = completionQueue
        self.resultCompletionBlock = completion
    }
    
}