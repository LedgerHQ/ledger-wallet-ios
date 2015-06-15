//
//  PairingTransactionInfo.swift
//  ledger-wallet-ios
//
//  Created by Nicolas Bigot on 09/02/2015.
//  Copyright (c) 2015 Ledger. All rights reserved.
//

import Foundation

final class PairingTransactionInfo: Mockable {
    
    let pinCode: String
    let recipientAddress: String
    let changeAmount: Bitcoin.Amount
    let feesAmount: Bitcoin.Amount
    let outputsAmount: Bitcoin.Amount
    let transactionDate: NSDate
    var dongleName: String = ""

    private let pinBytesLength = 4
    private let feesBytesLength = 8
    private let outputsBytesLength = 8
    private let changeBytesLength = 8
    private let recipientByteLength = 1
    
    init?(decryptedBlob: NSData) {
        // check that we have minimum bytes
        if decryptedBlob.length <= (pinBytesLength + feesBytesLength + outputsBytesLength + changeBytesLength + recipientByteLength) {
            self.recipientAddress = ""
            self.pinCode = ""
            self.changeAmount = 0
            self.feesAmount = 0
            self.outputsAmount = 0
            self.transactionDate = NSDate()
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
        if (offset + recipientBytesLength > decryptedBlob.length) {
            self.recipientAddress = ""
            self.pinCode = ""
            self.changeAmount = 0
            self.feesAmount = 0
            self.outputsAmount = 0
            self.transactionDate = NSDate()
            return nil
        }
        
        let recipientData = decryptedBlob.subdataWithRange(NSMakeRange(offset, recipientBytesLength)); offset += recipientBytesLength
        
        // validate data
        let recipientAddress = Crypto.Data.stringFromData(recipientData)
        let pinCode = Crypto.Data.stringFromData(pinCodeData)
        if pinCode != nil && recipientAddress != nil && Bitcoin.Address.verifyPublicAddress(recipientAddress!) == true {
            self.recipientAddress = recipientAddress!
            self.pinCode = pinCode!
            self.changeAmount = BTCBigNumber(unsignedBigEndian: changeData).int64value
            self.feesAmount = BTCBigNumber(unsignedBigEndian: feesData).int64value
            self.outputsAmount = BTCBigNumber(unsignedBigEndian: outputsData).int64value
            self.transactionDate = NSDate()
        }
        else {
            self.recipientAddress = ""
            self.pinCode = ""
            self.changeAmount = 0
            self.feesAmount = 0
            self.outputsAmount = 0
            self.transactionDate = NSDate()
            return nil
        }
    }
    
    // MARK: - Mock
    
    class func testObject() -> Self {
        return self()
    }
    
    private init() {
        recipientAddress = "1Ax9jk7pPt1ZcVcyAcgbYgE3k91443TLjU"
        pinCode = "abcd"
        changeAmount = 0
        feesAmount = 0
        outputsAmount = 123000000
        dongleName = "Sophie's Wallet"
        transactionDate = NSDate()
    }
    
}