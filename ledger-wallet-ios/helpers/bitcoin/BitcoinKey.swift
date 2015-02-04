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
    
    // MARK: Key agreement
    
    private func generateNewKeyPair() {
        // generate key
        let key = EC_KEY_new_by_curve_name(NID_secp256k1)
        //EC_KEY_generate_key(key)
        
        let secret = NSMutableData(length: 32)!
        RAND_bytes(UnsafeMutablePointer(secret.mutableBytes), 32)
        let bignum_p = BN_bin2bn(UnsafeMutablePointer(secret.mutableBytes), Int32(secret.length), BN_new())

        
        let group = EC_KEY_get0_group(key)
        var ctx = BN_CTX_new()
        let pub_key = EC_POINT_new(group)
        EC_POINT_mul(group, pub_key, bignum_p, nil, nil, ctx)
        EC_KEY_set_private_key(key, bignum_p)
        EC_KEY_set_public_key(key, pub_key)
        EC_POINT_free(pub_key)
        BN_CTX_free(ctx)
    
        // get private key
        var bigNum = bignum_p
        var numBytes = (BN_num_bits(bigNum) + 7) / 8
        var data = NSMutableData(length: Int(numBytes))!
        var copiedBytes = BN_bn2bin(bigNum, UnsafeMutablePointer(data.mutableBytes))
        privateKey = data
        
        // get public key
        var point = EC_KEY_get0_public_key(key)
        EC_KEY_set_conv_form(key, POINT_CONVERSION_UNCOMPRESSED)
        numBytes = i2o_ECPublicKey(key, nil)
        data = NSMutableData(length: Int(numBytes))!
        i2o_ECPublicKey(key, UnsafeMutablePointer(data.mutableBytes))
        publicKey = data
        
        
        println(privateKey)
        println(publicKey)
        
        
        // free key
        EC_KEY_free(key)
    }
    
    func keyAgreementWithPublicKey(publicKey: NSData) -> NSData {
        
        return NSData()
    }
    
    // MARK: Initialization
    
    init() {
        generateNewKeyPair()
    }
    
    deinit {
        
    }
    
}