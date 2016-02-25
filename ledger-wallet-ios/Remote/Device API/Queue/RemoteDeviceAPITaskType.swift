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
    var timeoutInterval: Double { get set }
    var devicesCoordinator: RemoteDevicesCoordinator { get }
    
    func run(completion completion: () -> Void)
    func notifyRunIsComplete()
    func receiveAPDU(APDU: RemoteAPDU)
    func cancel()
    func completeWithError(error: RemoteDeviceError?)

    // to reimplement
    func main() -> Bool
    func didReceiveAPDU(APDU: RemoteAPDU)
    func didSendAPDU(APDU: RemoteAPDU)
    func notifyResultWithError(error: RemoteDeviceError?)
    
}

extension RemoteDeviceAPITaskType {
    
    // MARK: Queue management

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
    
    // MARK: APDU mangement
    
    func receiveAPDU(APDU: RemoteAPDU) {
        guard APDU.isResponse else {
            completeWithError(.InvalidResponse)
            return
        }
        if let error = APDU.statusError {
            switch error {
            case .Unknown:
                didReceiveAPDU(APDU)
            default:
                completeWithError(error)
            }
            return
        }
        
        didReceiveAPDU(APDU)
    }
    
    func didSendAPDU(APDU: RemoteAPDU) {
        
    }
    
    // MARK: Completion management
    
    func cancel() {
        notifyResultWithError(.CancelledTask)
    }
    
    func completeWithError(error: RemoteDeviceError?) {
        notifyResultWithError(error)
        notifyRunIsComplete()
    }
    
}