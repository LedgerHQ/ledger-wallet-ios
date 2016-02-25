//
//  RemoteDeviceAPIGetFirmwareVersionTask.swift
//  ledger-wallet-ios
//
//  Created by Nicolas Bigot on 12/02/2016.
//  Copyright © 2016 Ledger. All rights reserved.
//

import Foundation

final class RemoteDeviceAPIGetFirmwareVersionTask: RemoteDeviceAPITaskType {
    
    typealias CompletionBlock = (version: RemoteDeviceFirmwareVersion?, error: RemoteDeviceError?) -> Void
    
    var timeoutInterval = 0.0
    var completionBlock: (() -> Void)?
    let devicesCoordinator: RemoteDevicesCoordinator

    private var version: RemoteDeviceFirmwareVersion?
    private let resultCompletionQueue: NSOperationQueue
    private let resultCompletionBlock: CompletionBlock

    func main() -> Bool {
        guard let APDU = RemoteAPDU(classByte: 0xE0, instruction: 0xC4, p1: 0x00, p2: 0x00, data: nil, responseLength: UInt8(RemoteDeviceFirmwareVersion.requiredBytesLength)) else {
            return false
        }
        
        devicesCoordinator.send(APDU)
        return true
    }
    
    func didReceiveAPDU(APDU: RemoteAPDU) {
        guard let responseData = APDU.responseData, let version = RemoteDeviceFirmwareVersion(versionData: responseData) else {
            completeWithError(.InvalidResponse)
            return
        }
        
        self.version = version
        completeWithError(nil)
    }
    
    func notifyResultWithError(error: RemoteDeviceError?) {
        let version = self.version
        let completionBlock = self.resultCompletionBlock
        self.resultCompletionQueue.addOperationWithBlock() { completionBlock(version: version, error: error) }
    }
    
    // MARK: Initialization
    
    init(devicesCoordinator: RemoteDevicesCoordinator, completionQueue: NSOperationQueue, completion: CompletionBlock) {
        self.devicesCoordinator = devicesCoordinator
        self.resultCompletionQueue = completionQueue
        self.resultCompletionBlock = completion
    }
    
}