//
//  RemoteDeviceAPI.swift
//  ledger-wallet-ios
//
//  Created by Nicolas Bigot on 08/02/2016.
//  Copyright © 2016 Ledger. All rights reserved.
//

import Foundation

final class RemoteDeviceAPI {
 
    private let devicesCoordinator: RemoteDevicesCoordinator
    private let servicesProvider: ServicesProviderType
    private let queue: RemoteDeviceAPIQueue
    private var firmwareVersion: RemoteDeviceFirmwareVersion?
    private var checkAttestion: (isAuthentic: Bool, isBeta: Bool)?
    private let workingQueue = NSOperationQueue(name: "RemoteDeviceAPI", maxConcurrentOperationCount: 1)
    
    // MARK: API management
    
    func getFirmwareVersion(timeoutInterval timeoutInterval: Double = 5.0, completionQueue: NSOperationQueue, completion: RemoteDeviceAPIGetFirmwareVersionTask.CompletionBlock) {
        workingQueue.addOperationWithBlock() { [weak self] in
            guard let strongSelf = self else { return }
            
            if let firmwareVersion = strongSelf.firmwareVersion {
                completionQueue.addOperationWithBlock() { completion(version: firmwareVersion, error: nil) }
            }
            else {
                let task = RemoteDeviceAPIGetFirmwareVersionTask(devicesCoordinator: strongSelf.devicesCoordinator, completionQueue: strongSelf.workingQueue) { [weak self] firmwareVersion, error in
                    guard let strongSelf = self else { return }

                    strongSelf.firmwareVersion = firmwareVersion
                    completionQueue.addOperationWithBlock() { completion(version: firmwareVersion, error: error) }
                }
                task.timeoutInterval = timeoutInterval
                strongSelf.queue.enqueueTask(task)
            }
        }
    }
    
    func checkAttestation(timeoutInterval timeoutInterval: Double = 5.0, completionQueue: NSOperationQueue, completion: RemoteDeviceAPICheckAttestationTask.CompletionBlock) {
        workingQueue.addOperationWithBlock() { [weak self] in
            guard let strongSelf = self else { return }
            
            if let checkAttestion = strongSelf.checkAttestion {
                completionQueue.addOperationWithBlock() { completion(isAuthentic: checkAttestion.isAuthentic, isBeta: checkAttestion.isBeta, error: nil) }
            }
            else {
                let task = RemoteDeviceAPICheckAttestationTask(devicesCoordinator: strongSelf.devicesCoordinator, servicesProvider: strongSelf.servicesProvider, completionQueue: strongSelf.workingQueue) { [weak self] isAuthentic, isBeta, error in
                    guard let strongSelf = self else { return }
                    
                    strongSelf.checkAttestion = (isAuthentic, isBeta)
                    completionQueue.addOperationWithBlock() { completion(isAuthentic: isAuthentic, isBeta: isBeta, error: error) }
                }
                task.timeoutInterval = timeoutInterval
                strongSelf.queue.enqueueTask(task)
            }
        }
    }
    
    func verifyPIN(PIN: String?, timeoutInterval: Double = 0.0, completionQueue: NSOperationQueue, completion: RemoteDeviceAPIVerifyPINTask.CompletionBlock) {
        workingQueue.addOperationWithBlock() { [weak self] in
            guard let strongSelf = self else { return }
            
            let task = RemoteDeviceAPIVerifyPINTask(PIN: PIN, devicesCoordinator: strongSelf.devicesCoordinator, completionQueue: strongSelf.workingQueue, completion: completion)
            task.timeoutInterval = timeoutInterval
            strongSelf.queue.enqueueTask(task)
        }
    }
    
    func getPublicKey(path path: WalletAddressPath, timeoutInterval: Double = 5.0, completionQueue: NSOperationQueue, completion: RemoteDeviceAPIGetPublicKeyTask.CompletionBlock) {
        workingQueue.addOperationWithBlock() { [weak self] in
            guard let strongSelf = self else { return }
            
            let task = RemoteDeviceAPIGetPublicKeyTask(path: path, devicesCoordinator: strongSelf.devicesCoordinator, completionQueue: strongSelf.workingQueue, completion: completion)
            task.timeoutInterval = timeoutInterval
            strongSelf.queue.enqueueTask(task)
        }
    }
    
    func getExtendedPublicKey(accountIndex accountIndex: Int, timeoutInterval: Double = 5.0, completionQueue: NSOperationQueue, completion: (extendedPublicKey: String?, error: RemoteDeviceError?) -> Void) {
        workingQueue.addOperationWithBlock() { [weak self] in
            guard let strongSelf = self else { return }

            let path = WalletAddressPath(BIP44AccountIndex: accountIndex, coinNetwork: strongSelf.servicesProvider.coinNetwork)
            guard let parentPath = path.parentPath else {
                completionQueue.addOperationWithBlock() { completion(extendedPublicKey: nil, error: .InvalidParameters) }
                return
            }

            let finalize = { (fingerprint: UInt32) in
                strongSelf.getPublicKey(path: path, timeoutInterval: timeoutInterval, completionQueue: strongSelf.workingQueue) { publicKey, publicAddress, chainCode, error in
                    guard error == nil else {
                        completionQueue.addOperationWithBlock() { completion(extendedPublicKey: nil, error: error) }
                        return
                    }
                    
                    guard let
                        publicKey = publicKey,
                        chainCode = chainCode,
                        key = BTCKey(publicKey: publicKey),
                        compressedPublicKey = key.compressedPublicKey,
                        derivationIndex = path.derivationIndexes.last
                    else {
                        completionQueue.addOperationWithBlock() { completion(extendedPublicKey: nil, error: error) }
                        return
                    }
                    
                    let writer = DataWriter()
                    writer.writeNextData(strongSelf.servicesProvider.coinNetwork.extendedPublicKeyVersionData)
                    writer.writeNextUInt8(UInt8(path.depth))
                    writer.writeNextBigEndianUInt32(fingerprint)
                    writer.writeNextBigEndianUInt32(derivationIndex)
                    writer.writeNextData(chainCode)
                    writer.writeNextData(compressedPublicKey)
                    
                    if writer.data.length == 78, let extendedPublicKey = BTCBase58CheckStringWithData(writer.data) {
                        completionQueue.addOperationWithBlock() { completion(extendedPublicKey: extendedPublicKey, error: nil) }
                    }
                    else {
                        completionQueue.addOperationWithBlock() { completion(extendedPublicKey: nil, error: .InvalidResponse) }
                    }
                }
            }
            
            strongSelf.getPublicKey(path: parentPath, timeoutInterval: timeoutInterval, completionQueue: strongSelf.workingQueue) { publicKey, publicAddress, chainCode, error in
                guard error == nil else {
                    completionQueue.addOperationWithBlock() { completion(extendedPublicKey: nil, error: error) }
                    return
                }
                
                guard let
                    publicKey = publicKey,
                    key = BTCKey(publicKey: publicKey),
                    compressedPublicKey = key.compressedPublicKey,
                    hash = BTCHash160(compressedPublicKey)
                else {
                    completionQueue.addOperationWithBlock() { completion(extendedPublicKey: nil, error: error) }
                    return
                }
                
                let reader = DataReader(data: hash)
                guard let fingerprint = reader.readNextBigEndianUInt32() else {
                    completionQueue.addOperationWithBlock() { completion(extendedPublicKey: nil, error: error) }
                    return
                }
                finalize(fingerprint)
            }
        }
    }
    
    func getIdentifier(completionQueue completionQueue: NSOperationQueue, completion: (identifier: String?, error: RemoteDeviceError?) -> Void) {
        workingQueue.addOperationWithBlock() { [weak self] in
            guard let strongSelf = self else { return }
            
            strongSelf.getPublicKey(path: WalletAddressPath(path: "0"), completionQueue: strongSelf.workingQueue) { publicKey, publicAddress, chainCode, error in
                completionQueue.addOperationWithBlock() { completion(identifier: publicAddress, error: error) }
            }
        }
    }
    
    func setCoinVersion(coinNetwork: CoinNetworkType, timeoutInterval: Double = 5.0, completionQueue: NSOperationQueue, completion: RemoteDeviceAPISetCoinVersionTask.CompletionBlock) {
        workingQueue.addOperationWithBlock() { [weak self] in
            guard let strongSelf = self else { return }
            
            let task = RemoteDeviceAPISetCoinVersionTask(coinNetwork: coinNetwork, devicesCoordinator: strongSelf.devicesCoordinator, completionQueue: completionQueue, completion: completion)
            task.timeoutInterval = timeoutInterval
            strongSelf.queue.enqueueTask(task)
        }
    }
    
    func getTrustedInput(rawTransaction rawTransaction: NSData, outputIndex: UInt32, timeoutInterval: Double = 0.0, completionQueue: NSOperationQueue, completion: RemoteDeviceAPIGetTrustedInputTask.CompletionBlock) {
        workingQueue.addOperationWithBlock() { [weak self] in
            guard let strongSelf = self else { return }

            let task = RemoteDeviceAPIGetTrustedInputTask(rawTransaction: rawTransaction, outputIndex: outputIndex, devicesCoordinator: strongSelf.devicesCoordinator, completionQueue: completionQueue, completion: completion)
            task.timeoutInterval = timeoutInterval
            strongSelf.queue.enqueueTask(task)
        }
    }
    
    func startUntrustedHashTransactionInput(trustedInputs trustedInputs: [NSData], trustedInputIndex: Int, outputScript: NSData, timeoutInterval: Double = 0.0, completionQueue: NSOperationQueue, completion: RemoteDeviceAPIStartUntrustedHashTransactionInputTask.CompletionBlock) {
        workingQueue.addOperationWithBlock() { [weak self] in
            guard let strongSelf = self else { return }
            
            let task = RemoteDeviceAPIStartUntrustedHashTransactionInputTask(trustedInputs: trustedInputs, trustedInputIndex: trustedInputIndex, outputScript: outputScript, devicesCoordinator: strongSelf.devicesCoordinator, completionQueue: completionQueue, completion: completion)
            task.timeoutInterval = timeoutInterval
            strongSelf.queue.enqueueTask(task)
        }
    }
    
    func finalizeFullUntrustedHashTransactionInput(spendableOutputs spendableOutputs: [WalletSpendableTransactionOutput], changeOutput: WalletSpendableTransactionOutput?, timeoutInterval: Double = 0.0, completionQueue: NSOperationQueue, completion: RemoteDeviceAPIFinalizeFullUntrustedHashTransactionInputTask.CompletionBlock) {
        workingQueue.addOperationWithBlock() { [weak self] in
            guard let strongSelf = self else { return }
            
            let task = RemoteDeviceAPIFinalizeFullUntrustedHashTransactionInputTask(spendableOutputs: spendableOutputs, changeOutput: changeOutput, devicesCoordinator: strongSelf.devicesCoordinator, completionQueue: completionQueue, completion: completion)
            task.timeoutInterval = timeoutInterval
            strongSelf.queue.enqueueTask(task)
        }
    }
    
    func signUntrustedTransactionHash(inputAddressPath inputAddressPath: WalletAddressPath, timeoutInterval: Double = 5.0, completionQueue: NSOperationQueue, completion: RemoteDeviceAPISignUntrustedHashTask.CompletionBlock) {
        workingQueue.addOperationWithBlock() { [weak self] in
            guard let strongSelf = self else { return }
            
            let task = RemoteDeviceAPISignUntrustedHashTask(inputAddressPath: inputAddressPath, devicesCoordinator: strongSelf.devicesCoordinator, completionQueue: completionQueue, completion: completion)
            task.timeoutInterval = timeoutInterval
            strongSelf.queue.enqueueTask(task)
        }
    }
    
    // MARK: Events management
    
    func handleDidReceiveAPDU(APDU: RemoteAPDU, fromDevice device: RemoteDeviceType) {
        workingQueue.addOperationWithBlock() { [weak self] in
            guard let strongSelf = self else { return }

            strongSelf.queue.handleReceivedAPDU(APDU)
        }
    }
    
    func handleDidFailToReceiveAPDUFromDevice(device: RemoteDeviceType) {
        workingQueue.addOperationWithBlock() { [weak self] in
            guard let strongSelf = self else { return }
            
            strongSelf.queue.handleError(.UnableToRead)
        }
    }
    
    func handleDidSendAPDU(APDU: RemoteAPDU, toDevice device: RemoteDeviceType) {
        workingQueue.addOperationWithBlock() { [weak self] in
            guard let strongSelf = self else { return }
            
            strongSelf.queue.handleSentAPDU(APDU)
        }
    }
    
    func handleDidFailToSendAPDUToDevice(device: RemoteDeviceType) {
        workingQueue.addOperationWithBlock() { [weak self] in
            guard let strongSelf = self else { return }
            
            strongSelf.queue.handleError(.UnableToWrite)
        }
    }
    
    func handleDidDisconnectDevice(device: RemoteDeviceType, withError error: RemoteDeviceError?) {
        workingQueue.addOperationWithBlock() { [weak self] in
            guard let strongSelf = self else { return }
            
            let finalError = error ?? .CancelledTask
            strongSelf.queue.handleError(finalError)
            strongSelf.queue.cancelAllTasks(cancelPendingTasks: true)
        }
    }
    
    // MARK: Initialization
    
    init(devicesCoordinator: RemoteDevicesCoordinator, servicesProvider: ServicesProviderType) {
        self.devicesCoordinator = devicesCoordinator
        self.servicesProvider = servicesProvider
        self.queue = RemoteDeviceAPIQueue(delegateQueue: workingQueue)
        self.queue.delegate = self
    }
    
    deinit {
        workingQueue.addOperationWithBlock() { [weak self] in
            self?.queue.cancelAllTasks(cancelPendingTasks: true)
        }
        workingQueue.waitUntilAllOperationsAreFinished()
    }
    
}

// MARK: - RemoteDeviceAPIQueueDelegate

extension RemoteDeviceAPI: RemoteDeviceAPIQueueDelegate {
    
    func deviceAPIQueue(deviceAPIQueue: RemoteDeviceAPIQueue, didTimeoutTask: RemoteDeviceAPITaskType) {
        devicesCoordinator.abortCurrentTransfer()
    }
    
}