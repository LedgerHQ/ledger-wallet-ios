//
//  PairingTransactionsCryptor.swift
//  ledger-wallet-ios
//
//  Created by Nicolas Bigot on 06/02/2015.
//  Copyright (c) 2015 Ledger. All rights reserved.
//

import Foundation

final class PairingTransactionsCryptor {
    
    private struct BytesLength {
        static let version = 4
        static let encryptionKey = 16
        static let checksum = 2
        static let flags = 1
        static let operationMode = 1
        static let coinVersion = 1
        static let pin = 4
        static let fees = 8
        static let outputs = 8
        static let change = 8
        static let recipient = 1
        
        private static var legacyDataMinimumBytesLength: Int {
            return BytesLength.pin + BytesLength.fees + BytesLength.outputs + BytesLength.change + BytesLength.recipient
        }
        
        private static var newDataRequiredBytesLength: Int {
            return BytesLength.version + BytesLength.encryptionKey + BytesLength.checksum + BytesLength.flags +
                BytesLength.operationMode + BytesLength.coinVersion * 2 + BytesLength.pin
        }
    }
    
    private enum ContextKeys {
        case RegularCoinVersion
        case P2SHCoinVersion
        case PinCode
    }
    
    // MARK: - Transaction info extraction
    
    func transactionInfoFromRequestMessage(message: BasePairingManager.Message, pairingKey: NSData) -> PairingTransactionInfo? {
        // make sure second factor data is present
        guard let secondFactorDataString = message["second_factor_data"] as? String, secondFactorData = BTCDataFromHex(secondFactorDataString) else {
            return nil
        }

        // decrypt second factor data
        guard let decryptedSecondFactorData = decryptData(secondFactorData, withKey: pairingKey) else {
            return nil
        }
        
        // if output data, try to extract transaction info from new protocol
        if let outputDataString = message["output_data"] as? String, outputData = BTCDataFromHex(outputDataString) {
            return extractTransactionInfoFromNewData(decryptedSecondFactorData, outputData: outputData)
        }
        // try to extract transaction info from legacy protocol
        return extractTransactionInfoFromLegacyData(decryptedSecondFactorData)
    }
    
    private func extractTransactionInfoFromNewData(secondFactorData: NSData, outputData: NSData) -> PairingTransactionInfo? {
        // check that we have minimum bytes
        guard secondFactorData.length >= BytesLength.newDataRequiredBytesLength else {
            return nil
        }
        
        // get transaction data
        var offset = 0
        let versionData = secondFactorData.subdataWithRange(NSMakeRange(offset, BytesLength.version)); offset += BytesLength.version
        let encryptionKeyData = secondFactorData.subdataWithRange(NSMakeRange(offset, BytesLength.encryptionKey)); offset += BytesLength.encryptionKey
        let _ = secondFactorData.subdataWithRange(NSMakeRange(offset, BytesLength.checksum)); offset += BytesLength.checksum
        let _ = secondFactorData.subdataWithRange(NSMakeRange(offset, BytesLength.flags)); offset += BytesLength.flags
        let _ = secondFactorData.subdataWithRange(NSMakeRange(offset, BytesLength.operationMode)); offset += BytesLength.operationMode
        let regularCoinVersionData = secondFactorData.subdataWithRange(NSMakeRange(offset, BytesLength.coinVersion)); offset += BytesLength.coinVersion
        let P2SHCoinVersionData = secondFactorData.subdataWithRange(NSMakeRange(offset, BytesLength.coinVersion)); offset += BytesLength.coinVersion
        let pinCodeData = secondFactorData.subdataWithRange(NSMakeRange(offset, BytesLength.pin));
        
        // validate data
        guard String(data: versionData, encoding: NSUTF8StringEncoding) == "2FA1" else {
            return nil
        }
        guard let pinCode = String(data: pinCodeData, encoding: NSUTF8StringEncoding) else {
            return nil
        }
        guard let decryptedOutputData = decryptData(outputData, withKey: encryptionKeyData) else {
            return nil
        }
        
        // build context
        let context: [ContextKeys: AnyObject] = [
            .PinCode: pinCode,
            .RegularCoinVersion: regularCoinVersionData,
            .P2SHCoinVersion: P2SHCoinVersionData
        ]
        return buildTransactionInfoFromOutputData(decryptedOutputData, context: context)
    }
    
    private func extractTransactionInfoFromLegacyData(secondFactorData: NSData) -> PairingTransactionInfo? {
        // check that we have minimum bytes
        guard secondFactorData.length > BytesLength.legacyDataMinimumBytesLength else {
            return nil
        }
        
        // get transaction data
        var offset = 0
        let pinCodeData = secondFactorData.subdataWithRange(NSMakeRange(offset, BytesLength.pin)); offset += BytesLength.pin
        let outputsData = secondFactorData.subdataWithRange(NSMakeRange(offset, BytesLength.outputs)); offset += BytesLength.outputs
        let _ = secondFactorData.subdataWithRange(NSMakeRange(offset, BytesLength.fees)); offset += BytesLength.fees
        let _ = secondFactorData.subdataWithRange(NSMakeRange(offset, BytesLength.change)); offset += BytesLength.change
        let recipientDataLengthData = secondFactorData.subdataWithRange(NSMakeRange(offset, BytesLength.recipient)); offset += BytesLength.recipient
        let recipientBytesLength = Int(UnsafePointer<UInt8>(recipientDataLengthData.bytes).memory)
        
        // check that we have enough left bytes
        guard (offset + recipientBytesLength) <= secondFactorData.length else {
            return nil
        }
        
        let recipientData = secondFactorData.subdataWithRange(NSMakeRange(offset, recipientBytesLength)); offset += recipientBytesLength
        
        // validate data
        guard let pinCode = String(data: pinCodeData, encoding: NSUTF8StringEncoding),
            recipientAddress = String(data: recipientData, encoding: NSUTF8StringEncoding) where
            BTCAddress(string: recipientAddress as String) != nil else {
            return nil
        }
        
        // build transaction info
        return PairingTransactionInfo(
            pinCode: pinCode,
            recipientAddress: recipientAddress,
            amount: BTCBigNumber(unsignedBigEndian: outputsData).int64value
        )
    }
    
    // MARK: - Output data extraction
    
    private func buildTransactionInfoFromOutputData(outputData: NSData, context: [ContextKeys: AnyObject]) -> PairingTransactionInfo? {
        // read number of outputs
        var numberOfOutputs: UInt64 = 0
        let offset = Int(BTCProtocolSerialization.readVarInt(&numberOfOutputs, fromData: outputData))
        guard offset > 0 && numberOfOutputs > 0 else {
            return nil
        }
        
        // parse first output
        guard let transactionOutput = BTCTransactionOutput(data: outputData.subdataWithRange(NSMakeRange(offset, outputData.length - offset))) else {
            return nil
        }
        
        // validate data
        guard transactionOutput.value != -1 && transactionOutput.script != nil &&
            (transactionOutput.script.isPayToPublicKeyHashScript || transactionOutput.script.isPayToScriptHashScript) else {
            return nil
        }
        
        // extract hash
        var extractedHashData: NSData? = nil
        transactionOutput.script.enumerateOperations { (index: UInt, opCode: BTCOpcode, data: NSData?, stop: UnsafeMutablePointer<ObjCBool>) in
            if opCode == BTCOpcode.OP_INVALIDOPCODE && data != nil && data!.length > 0 {
                extractedHashData = data!
                stop.memory = true
            }
        }
        guard let hashData = extractedHashData else {
            return nil
        }
        
        // add prefix + suffix
        let versionPrefix = transactionOutput.script.isPayToPublicKeyHashScript ? context[.RegularCoinVersion] as! NSData : context[.P2SHCoinVersion] as! NSData
        let addressData = NSMutableData(data: versionPrefix)
        addressData.appendData(hashData)
        
        // compute final base 58 check
        guard let finalAddress = BTCBase58CheckStringWithData(addressData) else {
            return nil
        }
        
        // build transaction info
        return PairingTransactionInfo(
            pinCode: context[.PinCode] as! String,
            recipientAddress: finalAddress,
            amount: transactionOutput.value
        )
    }
    
    // MARK: - Utilities
    
    private func decryptData(data: NSData, withKey key: NSData) -> NSData? {
        // get splitted key
        guard let (key1, key2) = key.splittedData else {
            return nil
        }
        
        // decrypt blob
        guard let decryptedData = data.tripeDESCBCWithKeys(key1: key1, key2: key2, key3: key1, encrypt: false) else {
            return nil
        }
        
        return decryptedData
    }
    
}