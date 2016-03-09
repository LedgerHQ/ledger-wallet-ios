//
//  RemoteDeviceAPISignUntrustedHash.swift
//  ledger-wallet-ios
//
//  Created by Nicolas Bigot on 26/02/2016.
//  Copyright © 2016 Ledger. All rights reserved.
//

import Foundation

final class RemoteDeviceAPISignUntrustedHashTask: RemoteDeviceAPITaskType {
    
    typealias CompletionBlock = (signature: NSData?, sigHashType: UInt8?, error: RemoteDeviceError?) -> Void
    
    var timeoutInterval = 0.0
    var completionBlock: (() -> Void)?
    let devicesCoordinator: RemoteDevicesCoordinator
    
    static private let signatureHashTypeByte: UInt8 = 0x01
    private var signature: NSData?
    private var sigHashType: UInt8?
    private let inputAddressPath: WalletAddressPath
    private let resultCompletionQueue: NSOperationQueue
    private let resultCompletionBlock: CompletionBlock

    func main() -> Bool {
        let writer = DataWriter()
        writer.writeNextUInt8(UInt8(inputAddressPath.depth))
        inputAddressPath.derivationIndexes.forEach({ writer.writeNextBigEndianUInt32($0) })
        writer.writeNextUInt8(0x00)
        writer.writeNextBigEndianUInt32(0x00000000)
        writer.writeNextUInt8(self.dynamicType.signatureHashTypeByte)
        
        guard let APDU = RemoteAPDU(classByte: 0xE0, instruction: 0x48, p1: 0x00, p2: 0x00, data: writer.data, responseLength: 0x00) else {
            return false
        }
        
        devicesCoordinator.send(APDU)
        return true
    }
    
    func didReceiveAPDU(APDU: RemoteAPDU) {
        guard let responseData = APDU.responseData else {
            completeWithError(.InvalidResponse)
            return
        }
        
        let reader = DataReader(data: responseData)
        guard let
            signature = reader.readNextDataOfLength(responseData.length - 1),
            sigHashType = reader.readNextUInt8()
        where
            sigHashType == self.dynamicType.signatureHashTypeByte
        else {
            completeWithError(.InvalidResponse)
            return
        }
        
        let finalSignature = NSMutableData(data: signature)
        finalSignature.replaceBytesInRange(NSMakeRange(0, 1), withBytes: [0x30] as [UInt8], length: 1)
        self.signature = finalSignature
        self.sigHashType = sigHashType
        completeWithError(nil)
    }
    
    func notifyResultWithError(error: RemoteDeviceError?) {
        let completionBlock = self.resultCompletionBlock
        let signature = self.signature
        let sigHashType = self.sigHashType
        self.resultCompletionQueue.addOperationWithBlock() { completionBlock(signature: signature, sigHashType: sigHashType, error: error) }
    }
    
    // MARK: Initialization
    
    init(inputAddressPath: WalletAddressPath, devicesCoordinator: RemoteDevicesCoordinator, completionQueue: NSOperationQueue, completion: CompletionBlock) {
        self.inputAddressPath = inputAddressPath
        self.devicesCoordinator = devicesCoordinator
        self.resultCompletionQueue = completionQueue
        self.resultCompletionBlock = completion
    }
    
}