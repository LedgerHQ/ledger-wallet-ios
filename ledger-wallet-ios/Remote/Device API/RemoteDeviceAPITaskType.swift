//
//  RemoteDeviceAPITaskType.swift
//  ledger-wallet-ios
//
//  Created by Nicolas Bigot on 10/02/2016.
//  Copyright © 2016 Ledger. All rights reserved.
//

import Foundation

protocol RemoteDeviceAPITaskType: class {
    
    var completionBlock: (() -> Void)? { get set }
    var devicesCoordinator: RemoteDevicesCoordinator { get }
    
    func run(completion completion: () -> Void)
    func notifyRunIsComplete()
    func processReceivedAPDU(APDU: RemoteAPDU)
    func cancel()
    func completeWithError(error: RemoteDeviceError?)

    // to reimplement
    func main() -> Bool
    func handleReceivedAPDU(APDU: RemoteAPDU)
    func handleSentAPDU(APDU: RemoteAPDU)
    func notifyResultWithError(error: RemoteDeviceError?)
    
}

extension RemoteDeviceAPITaskType {
    
    func run(completion completion: () -> Void) {
        completionBlock = completion
        
        guard devicesCoordinator.connectionState == .Connected && main() else {
            completeWithError(.CancelledTask)
            return
        }
    }

    func notifyRunIsComplete() {
        completionBlock?()
    }
    
    func processReceivedAPDU(APDU: RemoteAPDU) {
        guard APDU.isResponse else {
            completeWithError(.InvalidResponse)
            return
        }
        if let error = APDU.statusError {
            completeWithError(error)
            return
        }
        
        handleReceivedAPDU(APDU)
    }
    
    func handleSentAPDU(APDU: RemoteAPDU) {
        
    }
    
    func cancel() {
        notifyResultWithError(.CancelledTask)
    }
    
    func completeWithError(error: RemoteDeviceError?) {
        notifyResultWithError(error)
        notifyRunIsComplete()
    }
    
}