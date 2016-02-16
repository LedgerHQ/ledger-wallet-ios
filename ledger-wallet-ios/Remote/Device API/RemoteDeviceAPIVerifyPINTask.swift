//
//  RemoteDeviceAPIVerifyPINTask.swift
//  ledger-wallet-ios
//
//  Created by Nicolas Bigot on 15/02/2016.
//  Copyright © 2016 Ledger. All rights reserved.
//

import Foundation

final class RemoteDeviceAPIVerifyPINTask: RemoteDeviceAPITaskType {
    
    typealias CompletionBlock = (isVerified: Bool, remainingAttempts: Int, error: RemoteDeviceError?) -> Void
    
    var timeoutInterval = 0.0
    var completionBlock: (() -> Void)?
    let devicesCoordinator: RemoteDevicesCoordinator
    
    private var verified = false
    private var remainingAttempts = 0
    private let pin: String?
    private let resultCompletionQueue: NSOperationQueue
    private let resultCompletionBlock: CompletionBlock
    
    func main() -> Bool {
        let data = NSMutableData()
        if let pin = self.pin, pinData = pin.dataUsingEncoding(NSUTF8StringEncoding) {
            data.appendData(pinData)
        }
        else {
            data.appendByte(0x00)
        }
        
        guard let APDU = RemoteAPDU(classByte: 0xE0, instruction: 0x22, p1: 0x00, p2: 0x00, data: data, responseLength: 0x00) else {
            return false
        }
        
        devicesCoordinator.send(APDU)
        return true
    }
    
    func didReceiveAPDU(APDU: RemoteAPDU) {
        // no error
        if let responseData = APDU.responseData {
            let reader = DataReader(data: responseData)
            
            guard let _ = reader.readNextUInt8() else {
                completeWithError(.InvalidResponse)
                return
            }
            
            verified = true
            completeWithError(nil)
        }
        // incorrect pin
        else if let statusData = APDU.statusData {
            let reader = DataReader(data: statusData)
            
            guard let
                firstByte = reader.readNextUInt8(), secondByte = reader.readNextUInt8()
            where
                firstByte == 0x63 && secondByte & 0xF0 == 0xC0
            else {
                completeWithError(.InvalidResponse)
                return
            }
            
            remainingAttempts = Int(secondByte & 0x0F)
            completeWithError(nil)
        }
        else {
            completeWithError(.InvalidResponse)
        }
    }
    
    func notifyResultWithError(error: RemoteDeviceError?) {
        let completionBlock = self.resultCompletionBlock
        let verified = self.verified
        let remainingAttempts = self.remainingAttempts
        self.resultCompletionQueue.addOperationWithBlock() { completionBlock(isVerified: verified, remainingAttempts: remainingAttempts, error: error) }
    }
    
    // MARK: Initialization
    
    init(PIN: String?, devicesCoordinator: RemoteDevicesCoordinator, completionQueue: NSOperationQueue, completion: CompletionBlock) {
        self.pin = PIN
        self.devicesCoordinator = devicesCoordinator
        self.resultCompletionQueue = completionQueue
        self.resultCompletionBlock = completion
    }
    
}