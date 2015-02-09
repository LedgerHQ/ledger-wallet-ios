//
//  PairingTransactionsCryptor.swift
//  ledger-wallet-ios
//
//  Created by Nicolas Bigot on 06/02/2015.
//  Copyright (c) 2015 Ledger. All rights reserved.
//

import Foundation

class PairingTransactionsCryptor {
    
    func transactionInfoFromEncryptedBlob(data: NSData, pairingKey: Crypto.Key) -> PairingTransactionInfo? {
        if (data.length == 0) {
            return nil
        }
        
        // get split pairing key
        let (key1, key2) = splitPairingKey(pairingKey)
        
        // decrypt blob
        let decryptedBlob = Crypto.Cipher.dataFromTripleDESCBC(data, key1: key1, key2: key2, key3: key1)
        
        // build transaction
        let transactionInfo = PairingTransactionInfo(decryptedBlob: decryptedBlob)
        return transactionInfo
    }
    
    func splitPairingKey(pairingKey: Crypto.Key) -> (Crypto.Key, Crypto.Key) {
        // split pairing key
        let (data1, data2) = Crypto.Data.splitDataInTwo(pairingKey.symmetricKey)
        let key1 = Crypto.Key(symmetricKey: data1)
        let key2 = Crypto.Key(symmetricKey: data2)
        return (key1, key2)
    }
    
}