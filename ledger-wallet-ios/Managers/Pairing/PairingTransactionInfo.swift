//
//  PairingTransactionInfo.swift
//  ledger-wallet-ios
//
//  Created by Nicolas Bigot on 09/02/2015.
//  Copyright (c) 2015 Ledger. All rights reserved.
//

import Foundation

struct PairingTransactionInfo: Equatable {
    
    let pinCode: String
    let recipientAddress: String
    let changeAmount: BTCAmount
    let feesAmount: BTCAmount
    let outputsAmount: BTCAmount
    let transactionDate: NSDate
    var dongleName: String?

    private let pinBytesLength = 4
    private let feesBytesLength = 8
    private let outputsBytesLength = 8
    private let changeBytesLength = 8
    private let recipientByteLength = 1
    
    init?(decryptedBlob: NSData) {
        // check that we have minimum bytes
        guard decryptedBlob.length > (pinBytesLength + feesBytesLength + outputsBytesLength + changeBytesLength + recipientByteLength) else {
            return nil
        }
        
        // get transaction data
        var offset = 0
        let pinCodeData = decryptedBlob.subdataWithRange(NSMakeRange(offset, pinBytesLength)); offset += pinBytesLength
        let outputsData = decryptedBlob.subdataWithRange(NSMakeRange(offset, outputsBytesLength)); offset += outputsBytesLength
        let feesData = decryptedBlob.subdataWithRange(NSMakeRange(offset, feesBytesLength)); offset += feesBytesLength
        let changeData = decryptedBlob.subdataWithRange(NSMakeRange(offset, changeBytesLength)); offset += changeBytesLength
        let recipientDataLengthData = decryptedBlob.subdataWithRange(NSMakeRange(offset, recipientByteLength)); offset += recipientByteLength
        let recipientBytesLength = Int(UnsafePointer<UInt8>(recipientDataLengthData.bytes).memory)
        
        // check that we have enough left bytes
        guard (offset + recipientBytesLength) <= decryptedBlob.length else {
            return nil
        }
        
        let recipientData = decryptedBlob.subdataWithRange(NSMakeRange(offset, recipientBytesLength)); offset += recipientBytesLength
        
        // validate data
        let recipientAddress = NSString(data: recipientData, encoding: NSUTF8StringEncoding)
        let pinCode = NSString(data: pinCodeData, encoding: NSUTF8StringEncoding)
        guard pinCode != nil && recipientAddress != nil && BTCAddress(string: recipientAddress! as String) != nil else {
            return nil
        }
    
        self.recipientAddress = recipientAddress! as String
        self.pinCode = pinCode! as String
        self.changeAmount = BTCBigNumber(unsignedBigEndian: changeData).int64value
        self.feesAmount = BTCBigNumber(unsignedBigEndian: feesData).int64value
        self.outputsAmount = BTCBigNumber(unsignedBigEndian: outputsData).int64value
        self.transactionDate = NSDate()
    }
    
}

func ==(lhs: PairingTransactionInfo, rhs: PairingTransactionInfo) -> Bool {
    return lhs.pinCode == rhs.pinCode && lhs.recipientAddress == rhs.recipientAddress && lhs.changeAmount == rhs.changeAmount &&
    lhs.feesAmount == rhs.feesAmount && lhs.outputsAmount == rhs.outputsAmount && lhs.transactionDate.isEqualToDate(rhs.transactionDate) &&
    lhs.dongleName == rhs.dongleName
}
    