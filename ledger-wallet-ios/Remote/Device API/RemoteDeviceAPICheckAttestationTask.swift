//
//  RemoteDeviceAPICheckAttestationTask.swift
//  ledger-wallet-ios
//
//  Created by Nicolas Bigot on 10/02/2016.
//  Copyright © 2016 Ledger. All rights reserved.
//

import Foundation

final class RemoteDeviceAPICheckAttestationTask: RemoteDeviceAPITaskType {
    
    typealias CompletionBlock = (isAuthentic: Bool, error: RemoteDeviceError?) -> Void
    var completionBlock: (() -> Void)?
    let devicesCoordinator: RemoteDevicesCoordinator
    
    private let servicesProvider: ServicesProviderType
    private var dataBlob: NSData?
    private var authentic = false
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
    
    func handleReceivedAPDU(APDU: RemoteAPDU) {
        guard let responseData = APDU.responseData else {
            completeWithError(.InvalidResponse)
            return
        }
        
        let reader = DataReader(data: responseData)
        guard let
            _ = reader.readNextBigEndianUInt32(),
            _ = reader.readNextBigEndianUInt32(),
            versionData = reader.readNextDataOfLength(8),
            signatureData = reader.readNextAvailableData(),
            blobData = dataBlob,
            key = BTCKey(publicKey: servicesProvider.betaAttestationKey.publicKey)
        else {
            completeWithError(.InvalidResponse)
            return
        }
        
        let verifyData = NSMutableData(data: versionData); verifyData.appendData(blobData)
        authentic = key.isValidSignature(signatureData, hash: BTCSHA256(verifyData))
        completeWithError(nil)
    }

    func notifyResultWithError(error: RemoteDeviceError?) {
        let authentic = self.authentic
        let completionBlock = self.resultCompletionBlock
        self.resultCompletionQueue.addOperationWithBlock() { completionBlock(isAuthentic: authentic, error: error) }
    }
    
    // MARK: Initialization
    
    init(devicesCoordinator: RemoteDevicesCoordinator, servicesProvider: ServicesProviderType, completionQueue: NSOperationQueue, completion: CompletionBlock) {
        self.servicesProvider = servicesProvider
        self.devicesCoordinator = devicesCoordinator
        self.resultCompletionQueue = completionQueue
        self.resultCompletionBlock = completion
    }
    
}