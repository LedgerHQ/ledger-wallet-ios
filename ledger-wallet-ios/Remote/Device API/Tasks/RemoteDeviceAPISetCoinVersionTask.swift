//
//  RemoteDeviceAPISetCoinVersionTask.swift
//  ledger-wallet-ios
//
//  Created by Nicolas Bigot on 18/02/2016.
//  Copyright © 2016 Ledger. All rights reserved.
//

import Foundation

final class RemoteDeviceAPISetCoinVersionTask: RemoteDeviceAPITaskType {
    
    typealias CompletionBlock = (success: Bool, error: RemoteDeviceError?) -> Void
    
    var timeoutInterval = 0.0
    var completionBlock: (() -> Void)?
    let devicesCoordinator: RemoteDevicesCoordinator

    private var success = false
    private let coinNetwork: CoinNetworkType
    private let resultCompletionQueue: NSOperationQueue
    private let resultCompletionBlock: CompletionBlock
    
    func main() -> Bool {
        let writer = DataWriter()
        writer.writeNextUInt8(coinNetwork.publicKeyHashPrefix)
        writer.writeNextUInt8(coinNetwork.scriptHashPrefix)
        
        guard let APDU = RemoteAPDU(classByte: 0xE0, instruction: 0x14, p1: 0x00, p2: 0x00, data: writer.data, responseLength: 0x00) else {
            return false
        }
        
        devicesCoordinator.send(APDU)
        return true
    }
    
    func didReceiveAPDU(APDU: RemoteAPDU) {
        guard APDU.responseData == nil else {
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
    
    // MARK: Initialize
    
    init(coinNetwork: CoinNetworkType, devicesCoordinator: RemoteDevicesCoordinator, completionQueue: NSOperationQueue, completion: CompletionBlock) {
        self.coinNetwork = coinNetwork
        self.devicesCoordinator = devicesCoordinator
        self.resultCompletionQueue = completionQueue
        self.resultCompletionBlock = completion
    }

}