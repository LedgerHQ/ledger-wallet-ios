//
//  PairingTransactionsCryptor.swift
//  ledger-wallet-ios
//
//  Created by Nicolas Bigot on 06/02/2015.
//  Copyright (c) 2015 Ledger. All rights reserved.
//

import Foundation

final class PairingTransactionsCryptor {
    
    func transactionInfoFromEncryptedBlob(data: NSData, pairingKey: NSData) -> PairingTransactionInfo? {
        if (data.length == 0) {
            return nil
        }
        
        // get split pairing key
        let (key1, key2) = pairingKey.splittedData!
        
        // decrypt blob
        let decryptedBlob = data.tripeDESCBCWithKeys(key1: key1, key2: key2, key3: key1, encrypt: false)!
        
        // build transaction
        let transactionInfo = PairingTransactionInfo(decryptedBlob: decryptedBlob)
        return transactionInfo
    }
    
}