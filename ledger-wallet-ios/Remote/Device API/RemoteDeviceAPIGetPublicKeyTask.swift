//
//  RemoteDeviceAPIGetPublicKeyTask.swift
//  ledger-wallet-ios
//
//  Created by Nicolas Bigot on 15/02/2016.
//  Copyright © 2016 Ledger. All rights reserved.
//

import Foundation

final class RemoteDeviceAPIGetPublicKeyTask: RemoteDeviceAPITaskType {
    
    typealias CompletionBlock = (publicKey: NSData?, publicAddress: String?, chainCode: NSData?, error: RemoteDeviceError?) -> Void
    
    var timeoutInterval = 0.0
    var completionBlock: (() -> Void)?
    let devicesCoordinator: RemoteDevicesCoordinator
    
    private var publicKey: NSData?
    private var publicAddress: String?
    private var chainCode: NSData?
    private let addressPath: WalletAddressPath
    private let resultCompletionQueue: NSOperationQueue
    private let resultCompletionBlock: CompletionBlock
    
    func main() -> Bool {
        let dataWriter = DataWriter()
        let indexes = addressPath.derivationIndexes
        dataWriter.writeNextUInt8(UInt8(indexes.count))
        indexes.forEach({ dataWriter.writeNextBigEndianUInt32($0) })
        
        guard let APDU = RemoteAPDU(classByte: 0xE0, instruction: 0x40, p1: 0x00, p2: 0x00, data: dataWriter.data, responseLength: 0x00) else {
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
            publicKeyLength = reader.readNextUInt8(),
            publicKeyData = reader.readNextDataOfLength(Int(publicKeyLength)),
            publicAddressLength = reader.readNextUInt8(),
            publicAddressData = reader.readNextDataOfLength(Int(publicAddressLength)),
            chainCodeData = reader.readNextDataOfLength(32),
            publicAddress = String(data: publicAddressData, encoding: NSUTF8StringEncoding)
        else {
            completeWithError(.InvalidResponse)
            return
        }
    
        self.publicKey = publicKeyData
        self.publicAddress = publicAddress
        self.chainCode = chainCodeData
        completeWithError(nil)
    }
    
    func notifyResultWithError(error: RemoteDeviceError?) {
        let completionBlock = self.resultCompletionBlock
        let publicKey = self.publicKey
        let publicAddress = self.publicAddress
        let chainCode = self.chainCode
        self.resultCompletionQueue.addOperationWithBlock() { completionBlock(publicKey: publicKey, publicAddress: publicAddress, chainCode: chainCode, error: error) }
    }
    
    // MARK: Initialization
    
    init(path: WalletAddressPath, devicesCoordinator: RemoteDevicesCoordinator, completionQueue: NSOperationQueue, completion: CompletionBlock) {
        self.addressPath = path
        self.devicesCoordinator = devicesCoordinator
        self.resultCompletionQueue = completionQueue
        self.resultCompletionBlock = completion
    }

    
}