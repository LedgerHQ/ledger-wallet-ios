//
//  WalletTransactionBuilder.swift
//  ledger-wallet-ios
//
//  Created by Nicolas Bigot on 23/02/2016.
//  Copyright © 2016 Ledger. All rights reserved.
//

import Foundation

enum WalletTransactionBuilderError: ErrorType {
    
    case InvalidState
    case InsufficientFunds
    case NoConnectedDevice
    case UnableToCollectUnspentOutputs
    case UnableToFetchRawTransaction
    case UnableToGetTrustedInput
    case UnableToBuildOutputs
    case UnableToGetCurrentInternalAddress
    case UnableToGetOutputScript
    case UnableToStartUntrustedHashTransactionInput
    case UnableToFinalizeFullUntrustedHashTransactionInput
    case UnableToSignUntrustedHashTransactionInput
    case UnableToBuildRawTransaction
    case UnableToCollectPublicKeys
    case UnableToPushRawTransaction
    
}

enum WalletTransactionBuilderState {
    
    case Idle
    case StartingTransaction
    case StartedTransaction
    case FinalizingTransaction
    case FinalizedTransaction
    
}

final class WalletTransactionBuilder {
    
    private(set) var state = WalletTransactionBuilderState.Idle
    private var rawTransaction = NSData()
    private var publicKeys: [NSData] = []
    private var unspentOutputs: [WalletUnspentTransactionOutput] = []
    private var unspentOutputIndex = 0
    private var trustedInputs: [NSData] = []
    private var trustedInputIndex = 0
    private var spendableOutputs: [WalletSpendableTransactionOutput] = []
    private var changeSpendableOutput: WalletSpendableTransactionOutput?
    private var inputSignatures: [NSData] = []
    private var amount: Int64 = 0
    private var address = ""
    private var fees: Int64 = 0
    private var accountIndex = 0
    private let transactionsManager: WalletTransactionsManagerType
    private let deviceCommunicator: RemoteDeviceCommunicator
    private let transactionsApiClient: WalletTransactionsAPIClient
    private let servicesProvider: ServicesProviderType
    private let workingQueue = NSOperationQueue(name: "WalletTransactionBuilder", maxConcurrentOperationCount: 1)
    private let logger = Logger.sharedInstance(name: "WalletTransactionBuilder")
    
    // MARK: Start transaction management
    
    func startTransaction(accountIndex accountIndex: Int, address: String, amount: Int64, fees: Int64, completionQueue: NSOperationQueue, completion: (Bool, WalletTransactionBuilderError?) -> Void) {
        workingQueue.addOperationWithBlock() { [weak self] in
            guard let strongSelf = self else { return }
            
            guard strongSelf.state == .Idle else {
                strongSelf.logger.error("Unable to start transaction, currently in \(strongSelf.state) state")
                completionQueue.addOperationWithBlock() { completion(false, .InvalidState) }
                return
            }
            
            strongSelf.logger.info("Starting transaction from account at index \(accountIndex) of amount \(amount) and fees \(fees) to address \(address)")
            strongSelf.state = .StartingTransaction
            strongSelf.address = address
            strongSelf.amount = amount
            strongSelf.fees = fees
            strongSelf.accountIndex = accountIndex
            
            // collect inputs
            strongSelf.processCollectTransactionUnspentOutputs(accountIndex: accountIndex) { [weak self] error in
                guard let strongSelf = self else { return }
                guard error == nil else {
                    strongSelf.logger.error("Unable to start transaction, got error \(error!), aborting")
                    strongSelf.resetState()
                    completionQueue.addOperationWithBlock() { completion(false, error!) }
                    return
                }
                
                // build outputs
                strongSelf.processBuildTransactionOutputs(accountIndex: accountIndex) { [weak self] error in
                    guard let strongSelf = self else { return }
                    guard error == nil else {
                        strongSelf.logger.error("Unable to start transaction, got error \(error!), aborting")
                        strongSelf.resetState()
                        completionQueue.addOperationWithBlock() { completion(false, error!) }
                        return
                    }
                    
                    strongSelf.logger.info("Successfully started transaction")
                    strongSelf.state = .StartedTransaction
                    completionQueue.addOperationWithBlock() { completion(true, nil) }
                }
            }
        }
    }
    
    private func processCollectTransactionUnspentOutputs(accountIndex accountIndex: Int, completion: (WalletTransactionBuilderError?) -> Void) {
        logger.info("Collecting unspent outputs from account at index \(accountIndex)")
        
        // collect utxo
        transactionsManager.collectUnspentOutputs(accountIndex: accountIndex, amount: amount + fees, completionQueue: workingQueue) { [weak self] outputs, error in
            guard let strongSelf = self else { return }
            
            if let error = error {
                strongSelf.logger.error("Unable to collect unspent outputs because of error \(error), aborting")
                switch error {
                case .AlreadyCollecting: completion(.UnableToCollectUnspentOutputs)
                case .InternalFailure: completion(.UnableToCollectUnspentOutputs)
                case .InsufficientFunds: completion(.InsufficientFunds)
                }
                return
            }
            
            guard let outputs = outputs where outputs.count > 0 else {
                strongSelf.logger.error("Unable to collect unspent outputs since no outputs were returned, aborting")
                completion(.UnableToCollectUnspentOutputs)
                return
            }
            
            let totalAmount = outputs.reduce(0) { return $0 + $1.output.value }
            strongSelf.logger.info("Successfully collected \(outputs.count) unspent output(s) for a total amount of \(totalAmount)")
            strongSelf.unspentOutputs = outputs
            completion(nil)
        }
    }
    
    private func processBuildTransactionOutputs(accountIndex accountIndex: Int, completion: (WalletTransactionBuilderError?) -> Void) {
        logger.info("Building outputs for desired amount and address")
        
        // build main output
        guard let mainBTCOutput = BTCTransactionOutput(value: amount, address: BTCAddress(string: address)), mainScript = mainBTCOutput.script.data else {
            logger.error("Unable to build main output, aborting")
            completion(.UnableToBuildOutputs)
            return
        }
        logger.info("Successfully built main output of amount \(amount) to address \(address)")
        let mainOutput = WalletSpendableTransactionOutput(index: 0, amount: amount, script: mainScript, address: nil)
        spendableOutputs.append(mainOutput)
        
        // build change if necessary
        let totalAmount = unspentOutputs.reduce(0) { return $0 + $1.output.value }
        let changeAmount = totalAmount - amount - fees
        guard changeAmount > 0 else {
            logger.info("Successfully built outputs")
            completion(nil)
            return
        }
        
        // fetch current internal address
        transactionsManager.fetchCurrentAddress(accountIndex: accountIndex, external: false, completionQueue: workingQueue) { [weak self] address in
            guard let strongSelf = self else { return }
            guard let changeAddress = address else {
                strongSelf.logger.error("Unable to fetch current internal address, aborting")
                completion(.UnableToGetCurrentInternalAddress)
                return
            }
            
            guard let changeBTCOutput = BTCTransactionOutput(value: changeAmount, address: BTCAddress(string: changeAddress.address)), changeScript = changeBTCOutput.script.data else {
                strongSelf.logger.error("Unable to build change output, aborting")
                completion(.UnableToBuildOutputs)
                return
            }
            strongSelf.logger.info("Successfully built change output of amount \(changeAmount) to address \(changeAddress.address)")
            let changeOutput = WalletSpendableTransactionOutput(index: 1, amount: changeAmount, script: changeScript, address: changeAddress)
            strongSelf.spendableOutputs.append(changeOutput)
            strongSelf.changeSpendableOutput = changeOutput
            
            strongSelf.logger.info("Successfully built outputs")
            completion(nil)
        }
    }
    
    // MARK: Finalize transaction management
    
    func finalizeTransaction(completionQueue completionQueue: NSOperationQueue, completion: (NSData?, WalletTransactionBuilderError?) -> Void) {
        workingQueue.addOperationWithBlock() { [weak self] in
            guard let strongSelf = self else { return }

            guard strongSelf.state == .StartedTransaction else {
                strongSelf.logger.error("Unable to finalize transaction, currently in \(strongSelf.state) state")
                completionQueue.addOperationWithBlock() { completion(nil, .InvalidState) }
                return
            }
            
            // get trusted inputs
            strongSelf.logger.info("Finalizing transaction")
            strongSelf.state = .FinalizingTransaction
            strongSelf.processGetTransactionTrustedInputs() { [weak self] error in
                guard let strongSelf = self else { return }
                guard error == nil else {
                    strongSelf.logger.error("Unable to finalize transaction, got error \(error!), aborting")
                    strongSelf.resetState()
                    completionQueue.addOperationWithBlock() { completion(nil, error!) }
                    return
                }
                
                // sign trusted inputs
                strongSelf.processSignTrustedTransactionInputs() { [weak self] error in
                    guard let strongSelf = self else { return }
                    guard error == nil else {
                        strongSelf.logger.error("Unable to finalize transaction, got error \(error!), aborting")
                        strongSelf.resetState()
                        completionQueue.addOperationWithBlock() { completion(nil, error!) }
                        return
                    }
                    
                    // build raw transaction
                    strongSelf.processBuildRawTransaction() { [weak self] error in
                        guard let strongSelf = self else { return }
                        guard error == nil else {
                            strongSelf.logger.error("Unable to finalize transaction, got error \(error!), aborting")
                            strongSelf.resetState()
                            completionQueue.addOperationWithBlock() { completion(nil, error!) }
                            return
                        }
                        
                        strongSelf.logger.info("Successfully finalized transaction")
                        strongSelf.state = .FinalizedTransaction
                        completionQueue.addOperationWithBlock() { completion(strongSelf.rawTransaction, nil) }
                    }
                }
            }
        }
    }
    
    // MARK: Trusted inputs management
    
    private func processGetTransactionTrustedInputs(completion completion: (WalletTransactionBuilderError?) -> Void) {
        logger.info("Getting trusted inputs from started transaction")
        processNextUnspentOutput(completion: completion)
    }
    
    private func processNextUnspentOutput(completion completion: (WalletTransactionBuilderError?) -> Void) {
        guard unspentOutputIndex < unspentOutputs.count else {
            logger.info("Successfully got trusted inputs from started transaction")
            completion(nil)
            return
        }
        
        logger.info("Processing next pending unspent output")
        let unspentOutput = unspentOutputs[unspentOutputIndex]
        processFetchRawTransaction(unspentOutputIndex: unspentOutputIndex, unspentOutput: unspentOutput, completion: completion)
        unspentOutputIndex += 1
    }
    
    private func processFetchRawTransaction(unspentOutputIndex unspentOutputIndex: Int, unspentOutput: WalletUnspentTransactionOutput, completion: (WalletTransactionBuilderError?) -> Void) {
        logger.info("Fetching raw transaction from hash \(unspentOutput.output.transactionHash) for unspent output at index \(unspentOutputIndex)")
        transactionsApiClient.fetchRawTransactionFromHash(unspentOutput.output.transactionHash) { [weak self] rawTransaction in
            guard let strongSelf = self else { return }
            
            guard let rawTransaction = rawTransaction else {
                strongSelf.logger.error("Unable to fetch raw transaction from hash, aborting")
                completion(.UnableToFetchRawTransaction)
                return
            }
            
            strongSelf.logger.info("Fetched raw transaction, getting trusted input")
            strongSelf.processGetTransactionTrustedInput(unspentOutputIndex: unspentOutputIndex, unspentOutput: unspentOutput, rawTransaction: rawTransaction, completion: completion)
        }
    }
    
    private func processGetTransactionTrustedInput(unspentOutputIndex unspentOutputIndex: Int, unspentOutput: WalletUnspentTransactionOutput, rawTransaction: NSData, completion: (WalletTransactionBuilderError?) -> Void) {
        logger.info("Getting trusted input from raw transaction with output index \(unspentOutput.output.index) for unspent output at index \(unspentOutputIndex)")
        guard let deviceAPI = deviceCommunicator.deviceAPI else {
            logger.error("Unable to get trusted input from raw transaction, no connected device, aborting")
            completion(.NoConnectedDevice)
            return
        }
        
        deviceAPI.getTrustedInput(rawTransaction: rawTransaction, outputIndex: unspentOutput.output.index, completionQueue: workingQueue) { [weak self] trustedInput, error in
            guard let strongSelf = self else { return }
            
            if let error = error {
                strongSelf.logger.error("Unable to get trusted input from raw transaction, got error from device \(error), aborting")
                completion(.UnableToGetTrustedInput)
                return
            }
            
            guard let trustedInput = trustedInput else {
                strongSelf.logger.error("Unable to get trusted input from raw transaction, device returned no data, aborting")
                completion(.UnableToGetTrustedInput)
                return
            }
            
            strongSelf.logger.info("Got trusted input from raw transaction, processing next unspent output if any")
            strongSelf.trustedInputs.append(trustedInput)
            strongSelf.processNextUnspentOutput(completion: completion)
        }
    }
    
    // MARK: Input signatures management

    private func processSignTrustedTransactionInputs(completion completion: (WalletTransactionBuilderError?) -> Void) {
        logger.info("Signing trusted inputs from started transaction")
        processNextPendingTrustedInput(completion: completion)
    }

    private func processNextPendingTrustedInput(completion completion: (WalletTransactionBuilderError?) -> Void) {
        guard trustedInputIndex < trustedInputs.count else {
            logger.info("Successfully signed trusted inputs from started transaction")
            completion(nil)
            return
        }
        
        logger.info("Processing next pending trusted input")
        let unspentOutput = unspentOutputs[trustedInputIndex]
        guard let outputScript = BTCDataFromHex(unspentOutput.output.scriptHex) else {
            logger.error("Unable to build data from output script, aborting")
            completion(.UnableToGetOutputScript)
            return
        }
        
        processStartUntrustedHashTransactionInput(trustedInputIndex: trustedInputIndex, outputScript: outputScript, completion: completion)
        trustedInputIndex += 1
    }
    
    private func processStartUntrustedHashTransactionInput(trustedInputIndex trustedInputIndex: Int, outputScript: NSData, completion: (WalletTransactionBuilderError?) -> Void) {
        logger.info("Starting untrusted transaction hash for trusted input at index \(trustedInputIndex)")
        guard let deviceAPI = deviceCommunicator.deviceAPI else {
            logger.error("Unable to start untrusted transaction input hash, no connected device, aborting")
            completion(.NoConnectedDevice)
            return
        }
        
        deviceAPI.startUntrustedHashTransactionInput(trustedInputs: trustedInputs, trustedInputIndex: trustedInputIndex, outputScript: outputScript, completionQueue: workingQueue) { [weak self] success, error in
            guard let strongSelf = self else { return }
            
            if !success || error != nil {
                strongSelf.logger.error("Unable to start untrusted transaction input hash, got error from device \(error!), aborting")
                completion(.UnableToStartUntrustedHashTransactionInput)
                return
            }
            
            strongSelf.logger.info("Started untrusted transaction hash for trusted input, finalizing full")
            strongSelf.processFinalizeFullUntrustedHashTransactionInput(trustedInputIndex: trustedInputIndex, completion: completion)
        }
    }

    private func processFinalizeFullUntrustedHashTransactionInput(trustedInputIndex trustedInputIndex: Int, completion: (WalletTransactionBuilderError?) -> Void) {
        logger.info("Finalizing full untrusted transaction hash for trusted input at index \(trustedInputIndex)")
        guard let deviceAPI = deviceCommunicator.deviceAPI else {
            logger.error("Unable to finalize full untrusted transaction input hash, no connected device, aborting")
            completion(.NoConnectedDevice)
            return
        }
        
        deviceAPI.finalizeFullUntrustedHashTransactionInput(spendableOutputs: spendableOutputs, changeOutput: changeSpendableOutput, completionQueue: workingQueue) { [weak self] success, error in
            guard let strongSelf = self else { return }

            if !success || error != nil {
                strongSelf.logger.error("Unable to finalize full untrusted transaction input hash, got error from device \(error!), aborting")
                completion(.UnableToFinalizeFullUntrustedHashTransactionInput)
                return
            }

            strongSelf.logger.info("Finalized full untrusted transaction input hash, signing")
            strongSelf.processSignUntrustedTransactionHash(trustedInputIndex: trustedInputIndex, completion: completion)
        }
    }
    
    private func processSignUntrustedTransactionHash(trustedInputIndex trustedInputIndex: Int, completion: (WalletTransactionBuilderError?) -> Void) {
        logger.info("Signing untrusted transaction hash for trusted input at index \(trustedInputIndex)")
        guard let deviceAPI = deviceCommunicator.deviceAPI else {
            logger.error("Unable to sign untrusted transaction hash, no connected device, aborting")
            completion(.NoConnectedDevice)
            return
        }
        
        let unspentOutput = unspentOutputs[trustedInputIndex]
        guard let signaturePath = unspentOutput.address.path.BIP44PathWithCoinNetwork(servicesProvider.coinNetwork) else {
            logger.error("Unable to sign untrusted transaction hash, cannot build BIP 44 signature path, aborting")
            completion(.UnableToSignUntrustedHashTransactionInput)
            return
        }
        deviceAPI.signUntrustedTransactionHash(inputAddressPath: signaturePath, completionQueue: workingQueue) { [weak self] signature, sigHashType, error in
            guard let strongSelf = self else { return }
            
            if let error = error {
                strongSelf.logger.error("Unable to sign untrusted transaction hash, got error from device \(error), aborting")
                completion(.UnableToSignUntrustedHashTransactionInput)
                return
            }
            
            guard let signature = signature, sigHashType = sigHashType else {
                strongSelf.logger.error("Unable to sign untrusted transaction hash, device returned no data, aborting")
                completion(.UnableToSignUntrustedHashTransactionInput)
                return
            }
            
            guard let finalSignature = strongSelf.canonicalizeSignature(signature, includeSigHashType: true, sigHashType: sigHashType) else {
                strongSelf.logger.error("Unable to canonicalize untrusted transaction hash signature, aborting")
                completion(.UnableToSignUntrustedHashTransactionInput)
                return
            }
            
            strongSelf.logger.info("Signed untrusted transaction hash, processing next pending trusted input if any")
            strongSelf.inputSignatures.append(finalSignature)
            strongSelf.processNextPendingTrustedInput(completion: completion)
        }
    }
    
    private func canonicalizeSignature(signature: NSData, includeSigHashType: Bool, sigHashType: UInt8) -> NSData? {
        guard let
            order = BTCBigNumber(unsignedBigEndian: BTCDataFromHex("FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141")),
            halfOrder = BTCBigNumber(unsignedBigEndian: BTCDataFromHex("7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0"))
        else {
            return nil
        }
        
        let reader = DataReader(data: signature)
        guard let
            sequence = reader.readNextUInt8(),
            _ = reader.readNextUInt8(),
            rByte = reader.readNextUInt8(),
            rLength = reader.readNextUInt8(),
            rData = reader.readNextDataOfLength(Int(rLength)),
            sByte = reader.readNextUInt8(),
            sLength = reader.readNextUInt8(),
            sData = reader.readNextDataOfLength(Int(sLength)),
            _ = BTCBigNumber(unsignedBigEndian: rData),
            sBigNumber = BTCBigNumber(unsignedBigEndian: sData)
        where
            sequence == 0x30 && rByte == 0x02 && sByte == 0x02
        else {
            return nil
        }
        
        let writer = DataWriter()
        if sBigNumber.greater(halfOrder) {
            let newSBigNumber = order.mutableCopy().subtract(sBigNumber)
            writer.writeNextUInt8(sequence)
            writer.writeNextUInt8(2 + rLength + 2 + UInt8(newSBigNumber.unsignedBigEndian.length))
            writer.writeNextUInt8(0x02)
            writer.writeNextUInt8(rLength)
            writer.writeNextData(rData)
            writer.writeNextUInt8(0x02)
            writer.writeNextUInt8(UInt8(newSBigNumber.unsignedBigEndian.length))
            writer.writeNextData(newSBigNumber.unsignedBigEndian)
        }
        else {
            writer.writeNextData(signature)
        }
        if includeSigHashType {
            writer.writeNextUInt8(sigHashType)
        }
        return writer.data
    }
    
    // MARK: Raw transaction management
    
    private func processBuildRawTransaction(completion completion: (WalletTransactionBuilderError?) -> Void) {
        logger.info("Building raw transaction from inputs, outputs and signatures")
        
        // collect all public keys
        processCollectPublicKeys() { [weak self] error in
            guard let strongSelf = self else { return }

            // build raw tx
            let writer = DataWriter()
            writer.writeNextLittleEndianUInt32(0x00000001)
            
            // write inputs
            writer.writeNextVarInteger(UInt64(strongSelf.trustedInputs.count))
            for index in 0..<strongSelf.trustedInputs.count {
                let unspentOutput = strongSelf.unspentOutputs[index]
                guard let
                    previousTransactionHash = BTCDataFromHex(unspentOutput.output.transactionHash)
                else {
                    strongSelf.logger.error("Unable to build input previous transaction hash, aborting")
                    completion(.UnableToBuildRawTransaction)
                    return
                }
                writer.writeNextReversedData(previousTransactionHash)
                writer.writeNextLittleEndianUInt32(unspentOutput.output.index)
                let signature = strongSelf.inputSignatures[index]
                let publicKey = strongSelf.publicKeys[index]
                writer.writeNextVarInteger(UInt64(signature.length + publicKey.length + 2))
                writer.writeNextUInt8(UInt8(signature.length))
                writer.writeNextData(signature)
                writer.writeNextUInt8(UInt8(publicKey.length))
                writer.writeNextData(publicKey)
                writer.writeNextLittleEndianUInt32(0xFFFFFFFF)
            }
            
            // write outputs
            writer.writeNextVarInteger(UInt64(strongSelf.spendableOutputs.count))
            for output in strongSelf.spendableOutputs {
                writer.writeNextLittleEndianInt64(output.amount)
                writer.writeNextVarInteger(UInt64(output.script.length))
                writer.writeNextData(output.script)
            }
            
            writer.writeNextLittleEndianUInt32(0x00000000)
            strongSelf.logger.info("Successfully built raw tx \(writer.data)")
            strongSelf.rawTransaction = writer.data
            completion(nil)
        }
    }
    
    private func processCollectPublicKeys(completion completion: (WalletTransactionBuilderError?) -> Void) {
        logger.info("Collecting public keys to build raw transaction inputs")
        
        // fetch extended public key
        transactionsManager.fetchExtendedPublicKey(accountIndex: accountIndex, completionQueue: workingQueue) { [weak self] extendedPublicKey in
            guard let strongSelf = self else { return }
            guard let extendedPublicKey = extendedPublicKey else {
                strongSelf.logger.error("Unable to fetch extended public key at index \(strongSelf.accountIndex), aborting")
                completion(.UnableToCollectPublicKeys)
                return
            }
            
            // build keychain
            let addresses = strongSelf.unspentOutputs.map() { $0.address }
            guard let keychain = BTCKeychain(extendedKey: extendedPublicKey) else {
                strongSelf.logger.error("Unable to build keychain from extended public key, aborting")
                completion(.UnableToCollectPublicKeys)
                return
            }
            
            // extract public keys
            var publicKeys: [NSData] = []
            for address in addresses {
                guard let
                    chainPath = address.path.pathDroppingFirst(1),
                    key = keychain.keyWithPath(chainPath.representativeString()),
                    publicKey = key.compressedPublicKey
                else {
                    strongSelf.logger.error("Unable to compute public keys from extended public key, aborting")
                    completion(.UnableToCollectPublicKeys)
                    return
                }
                
                publicKeys.append(publicKey)
            }
            
            strongSelf.publicKeys = publicKeys
            completion(nil)
        }
    }
    
    // MARK: Push transaction management
    
    func pushTransaction(rawTransaction: NSData, completionQueue: NSOperationQueue, completion: (Bool, WalletTransactionBuilderError?) -> Void) {
        workingQueue.addOperationWithBlock() { [weak self] in
            guard let strongSelf = self else { return }

            guard strongSelf.state == .FinalizedTransaction else {
                strongSelf.logger.error("Unable to push transaction, currently in \(strongSelf.state) state")
                completionQueue.addOperationWithBlock() { completion(false, .InvalidState) }
                return
            }
            
            // push transaction
            strongSelf.transactionsApiClient.pushRawTransaction(rawTransaction) { success in
                if success {
                	completionQueue.addOperationWithBlock() { completion(true, nil) }
                }
                else {
                    completionQueue.addOperationWithBlock() { completion(false, .UnableToPushRawTransaction) }
                }
            }
        }
    }
    
    // MARK: Initialization
    
    init(servicesProvider: ServicesProviderType, transactionsManager: WalletTransactionsManagerType, deviceCommunicator: RemoteDeviceCommunicator) {
        self.servicesProvider = servicesProvider
        self.transactionsManager = transactionsManager
        self.deviceCommunicator = deviceCommunicator
        self.transactionsApiClient = WalletTransactionsAPIClient(servicesProvider: servicesProvider, delegateQueue: workingQueue)
        resetState()
    }
    
    private func resetState() {
        state = .Idle
        unspentOutputs = []
        trustedInputs = []
        unspentOutputIndex = 0
        trustedInputIndex = 0
        spendableOutputs = []
        changeSpendableOutput = nil
        inputSignatures = []
        publicKeys = []
        rawTransaction = NSData()
        amount = 0
        fees = 0
        address = ""
        accountIndex = 0
    }
    
}