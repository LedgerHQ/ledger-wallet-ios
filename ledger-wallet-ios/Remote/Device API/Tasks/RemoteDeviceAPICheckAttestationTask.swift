//
//  RemoteDeviceAPICheckAttestationTask.swift
//  ledger-wallet-ios
//
//  Created by Nicolas Bigot on 10/02/2016.
//  Copyright © 2016 Ledger. All rights reserved.
//

import Foundation

final class RemoteDeviceAPICheckAttestationTask: RemoteDeviceAPITaskType {
    
    typealias CompletionBlock = (isAuthentic: Bool, isBeta: Bool, error: RemoteDeviceError?) -> Void
    
    var timeoutInterval = 0.0
    var completionBlock: (() -> Void)?
    let devicesCoordinator: RemoteDevicesCoordinator
    
    private let servicesProvider: ServicesProviderType
    private var dataBlob: NSData?
    private var authentic = false
    private var beta = false
    private let resultCompletionQueue: NSOperationQueue
    private let resultCompletionBlock: CompletionBlock
    
    func main() -> Bool {
        guard
            let dataBlob = BTCRandomDataWithLength(8),
            let APDU = RemoteAPDU(classByte: 0xE0, instruction: 0xC2, p1: 0x00, p2: 0x00, data: dataBlob, responseLength: 0x00)
        else {
            return false
        }
        
        self.dataBlob = dataBlob
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
            batchID = reader.readNextBigEndianUInt32(),
            derivationID = reader.readNextBigEndianUInt32(),
            versionData = reader.readNextDataOfLength(8),
            signatureData = reader.readNextAvailableData(),
            blobData = dataBlob
        else {
            completeWithError(.InvalidResponse)
            return
        }
        
        // normalize data
        let verifyData = NSMutableData(data: versionData); verifyData.appendData(blobData)
        let finalSignatureData = NSMutableData(data: signatureData)
        
        // fix first byte 0x31 issue
        var byte: UInt8 = 0
        finalSignatureData.getBytes(&byte, length: sizeofValue(byte))
        if byte == 0x31 {
            finalSignatureData.replaceBytesInRange(NSMakeRange(0, sizeofValue(byte)), withBytes: [0x30] as [UInt8], length: sizeofValue(byte))
        }
        
        // try production key
        if let productionAttestationKey = servicesProvider.attestationKeyWithIDs(batchID: batchID, derivationID: derivationID, fallbackToBeta: false) {
            let key = BTCKey(publicKey: productionAttestationKey.publicKey)
            authentic = key.isValidSignature(finalSignatureData, hash: BTCSHA256(verifyData))
            if authentic {
                completeWithError(nil)
                return
            }
        }
        
        // try beta key
        let betaAttestationKey = servicesProvider.betaAttestationKey
        let key = BTCKey(publicKey: betaAttestationKey.publicKey)
        beta = true
        authentic = key.isValidSignature(finalSignatureData, hash: BTCSHA256(verifyData))
        completeWithError(nil)
    }

    func notifyResultWithError(error: RemoteDeviceError?) {
        let authentic = self.authentic
        let beta = self.beta
        let completionBlock = self.resultCompletionBlock
        self.resultCompletionQueue.addOperationWithBlock() { completionBlock(isAuthentic: authentic, isBeta: beta, error: error) }
    }
    
    // MARK: Initialization
    
    init(devicesCoordinator: RemoteDevicesCoordinator, servicesProvider: ServicesProviderType, completionQueue: NSOperationQueue, completion: CompletionBlock) {
        self.servicesProvider = servicesProvider
        self.devicesCoordinator = devicesCoordinator
        self.resultCompletionQueue = completionQueue
        self.resultCompletionBlock = completion
    }
    
}