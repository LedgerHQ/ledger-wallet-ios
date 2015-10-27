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
        
        private static var minimumLegacyBytesLength: Int {
            return BytesLength.pin + BytesLength.fees + BytesLength.outputs + BytesLength.change + BytesLength.recipient
        }
        
        private static var requiredBytesLength: Int {
            return BytesLength.version + BytesLength.encryptionKey + BytesLength.checksum + BytesLength.flags +
                BytesLength.operationMode + BytesLength.coinVersion * 2 + BytesLength.pin
        }
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
            if let transactionInfo = extractTransactionInfoFromData(decryptedSecondFactorData, outputData: outputData) {
                return transactionInfo
            }
        }
        // try to extract transaction info from legacy protocol
        return extractTransactionInfoFromLegacyData(decryptedSecondFactorData)
    }
    
    private func extractTransactionInfoFromData(secondFactorData: NSData, outputData: NSData) -> PairingTransactionInfo? {
        // check that we have minimum bytes
        guard secondFactorData.length >= BytesLength.requiredBytesLength else {
            return nil
        }
        
        // get transaction data
        var offset = 0
        let versionData = secondFactorData.subdataWithRange(NSMakeRange(offset, BytesLength.version)); offset += BytesLength.version
        let encryptionKeyData = secondFactorData.subdataWithRange(NSMakeRange(offset, BytesLength.encryptionKey)); offset += BytesLength.encryptionKey
        let checksumData = secondFactorData.subdataWithRange(NSMakeRange(offset, BytesLength.checksum)); offset += BytesLength.checksum
        let _ = secondFactorData.subdataWithRange(NSMakeRange(offset, BytesLength.flags)); offset += BytesLength.flags
        let _ = secondFactorData.subdataWithRange(NSMakeRange(offset, BytesLength.operationMode)); offset += BytesLength.operationMode
        let regularCoinVersionData = secondFactorData.subdataWithRange(NSMakeRange(offset, BytesLength.coinVersion)); offset += BytesLength.coinVersion
        let P2SHCoinVersionData = secondFactorData.subdataWithRange(NSMakeRange(offset, BytesLength.coinVersion)); offset += BytesLength.coinVersion
        let pinCodeData = secondFactorData.subdataWithRange(NSMakeRange(offset, BytesLength.pin));

        // validate data
        guard String(data: versionData, encoding: NSUTF8StringEncoding) == "2FA1" else {
            return nil
        }
        guard let pinCode = NSString(data: pinCodeData, encoding: NSUTF8StringEncoding) else {
            return nil
        }
        guard let decryptedOutputData = decryptData(outputData, withKey: encryptionKeyData) else {
            return nil
        }
        
        // parse output data
        
        
        return nil
    }
    
    private func extractTransactionInfoFromLegacyData(secondFactorData: NSData) -> PairingTransactionInfo? {
        // check that we have minimum bytes
        guard secondFactorData.length > BytesLength.minimumLegacyBytesLength else {
            return nil
        }
        
        // get transaction data
        var offset = 0
        let pinCodeData = secondFactorData.subdataWithRange(NSMakeRange(offset, BytesLength.pin)); offset += BytesLength.pin
        let outputsData = secondFactorData.subdataWithRange(NSMakeRange(offset, BytesLength.outputs)); offset += BytesLength.outputs
        let feesData = secondFactorData.subdataWithRange(NSMakeRange(offset, BytesLength.fees)); offset += BytesLength.fees
        let changeData = secondFactorData.subdataWithRange(NSMakeRange(offset, BytesLength.change)); offset += BytesLength.change
        let recipientDataLengthData = secondFactorData.subdataWithRange(NSMakeRange(offset, BytesLength.recipient)); offset += BytesLength.recipient
        let recipientBytesLength = Int(UnsafePointer<UInt8>(recipientDataLengthData.bytes).memory)
        
        // check that we have enough left bytes
        guard (offset + recipientBytesLength) <= secondFactorData.length else {
            return nil
        }
        
        let recipientData = secondFactorData.subdataWithRange(NSMakeRange(offset, recipientBytesLength)); offset += recipientBytesLength
        
        // validate data
        let recipientAddress = NSString(data: recipientData, encoding: NSUTF8StringEncoding)
        let pinCode = NSString(data: pinCodeData, encoding: NSUTF8StringEncoding)
        guard pinCode != nil && recipientAddress != nil && BTCAddress(string: recipientAddress! as String) != nil else {
            return nil
        }
        
        return PairingTransactionInfo(pinCode: pinCode! as String, recipientAddress: recipientAddress! as String,
            changeAmount: BTCBigNumber(unsignedBigEndian: changeData).int64value, feesAmount: BTCBigNumber(unsignedBigEndian: feesData).int64value,
            outputsAmount: BTCBigNumber(unsignedBigEndian: outputsData).int64value, transactionDate: NSDate(), dongleName: nil)
    }
    
    // MARK: - Output data extraction
    
    
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