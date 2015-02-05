//
//  BitcoinKey.swift
//  ledger-wallet-ios
//
//  Created by Nicolas Bigot on 04/02/2015.
//  Copyright (c) 2015 Ledger. All rights reserved.
//

class BitcoinKey {

    private(set) var publicKey = NSData()
    private(set) var privateKey = NSData()
    private var key = EC_KEY_new_by_curve_name(NID_secp256k1)
    
    // MARK: Key agreement
    
    private func generateKeyPair() {
        // generate new key pair
        EC_KEY_generate_key(key)
    }
    
    private func generateKeysData() {
        // get private key
        let prKey = EC_KEY_get0_private_key(key)
        if (prKey != nil) {
            let prKeyBytes = (BN_num_bits(prKey) + 7) / 8
            let privateKey = NSMutableData(length: Int(prKeyBytes))!
            BN_bn2bin(prKey, UnsafeMutablePointer(privateKey.mutableBytes))
            self.privateKey = privateKey
        }
        else {
            self.privateKey = NSData()
        }
        
        // get public key
        let pKey = EC_KEY_get0_public_key(key)
        if (pKey != nil) {
            EC_KEY_set_conv_form(key, POINT_CONVERSION_UNCOMPRESSED)
            let pKeyBytes = i2o_ECPublicKey(key, nil)
            var publicKeyPointer = UnsafeMutablePointer<UInt8>.null()
            i2o_ECPublicKey(key, &publicKeyPointer)
            let publicKey = NSData(bytes: publicKeyPointer, length: Int(pKeyBytes))
            CRYPTO_free(publicKeyPointer)
            self.publicKey = publicKey
        }
        else {
            if (self.privateKey.length == 0) {
                self.publicKey = NSData()
            }
            else {
                // compute public key from private key
                // TODO:
            }
        }
    }

    // MARK: Initialization
    
    init() {
        generateKeyPair()
        generateKeysData()
    }
    
    deinit {
        if (key != nil) {
            EC_KEY_free(key)
        }
    }
    
}