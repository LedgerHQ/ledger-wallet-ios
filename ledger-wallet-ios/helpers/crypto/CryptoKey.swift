//
//  BitcoinKey.swift
//  ledger-wallet-ios
//
//  Created by Nicolas Bigot on 04/02/2015.
//  Copyright (c) 2015 Ledger. All rights reserved.
//

extension Crypto {
    
    class Key {
        
        var hasPublicKey: Bool { return publicKey.length > 0 }
        var hasPrivateKey: Bool { return privateKey.length > 0 }
        var hasSymmetricKey: Bool { return symmetricKey.length > 0 }
        private(set) var isSymmetric = false
        private(set) var isAsymmetric = false
        
        private(set) var publicKey = NSData()
        private(set) var privateKey = NSData()
        private(set) var symmetricKey = NSData()
        private var key: COpaquePointer = nil
        
        // MARK: Public methods
        
        func openSSLPublicKey() -> COpaquePointer {
            let pKey = EC_KEY_get0_public_key(key)
            if pKey != nil {
                return pKey
            }
            return nil
        }
        
        func openSSLPrivateKey() -> UnsafePointer<BIGNUM> {
            let prKey = EC_KEY_get0_private_key(key)
            if prKey != nil {
                return prKey
            }
            return nil
        }
        
        func openSSLKey() -> COpaquePointer {
            return key
        }
        
        // MARK: Private methods
        
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
                self.publicKey = NSData()
            }
        }
        
        private func definePublicKey(data: NSData) {
            // set public key
            var bytes = UnsafePointer<UInt8>(data.bytes)
            o2i_ECPublicKey(&key, &bytes, data.length)
        }
        
        private func definePrivateKey(data: NSData) {
            let group = EC_KEY_get0_group(key)
            let ctx = BN_CTX_new()
            let pKey = EC_POINT_new(group)
            let prKey = BN_bin2bn(UnsafePointer(data.bytes), Int32(data.length), BN_new())
    
            // compute new public key
            EC_POINT_mul(group, pKey, prKey, nil, nil, ctx)
            EC_KEY_set_private_key(key, prKey)
            EC_KEY_set_public_key(key, pKey)
            EC_POINT_free(pKey)
            BN_CTX_free(ctx)
        }
        
        // MARK: Initialization
        
        private init(publicKey: NSData, privateKey: NSData) {
            // create key
            key = EC_KEY_new_by_curve_name(NID_secp256k1)
            
            // define keys if provided
            if (publicKey.length > 0) {
                definePublicKey(publicKey)
            }
            else if (privateKey.length > 0) {
                definePrivateKey(privateKey)
            }
            else {
                EC_KEY_generate_key(key)
            }
    
            // compute data
            generateKeysData()
            
            isAsymmetric = true
        }
        
        convenience init() {
            self.init(publicKey: NSData(), privateKey: NSData())
        }
        
        convenience init(publicKey: NSData) {
            self.init(publicKey: publicKey, privateKey: NSData())
        }
        
        convenience init(privateKey: NSData) {
            self.init(publicKey: NSData(), privateKey: privateKey)
        }
        
        init(symmetricKey: NSData) {
            // define symmetric key
            self.symmetricKey = symmetricKey
            
            isSymmetric = true
        }
        
        deinit {
            if (key != nil) {
                EC_KEY_free(key)
            }
        }
        
    }
    
}