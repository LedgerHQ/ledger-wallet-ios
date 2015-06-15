//
//  CryptoCipher.m
//  ledger-wallet-ios
//
//  Created by Nicolas Bigot on 06/02/2015.
//  Copyright (c) 2015 Ledger. All rights reserved.
//

#import "CryptoCipher.h"

NSInteger valueGreaterOrEqualThan(NSInteger value, NSInteger modulo) {
    if (value % modulo == 0) { return value; }
    return (value + modulo) - ((value + modulo) % modulo);
}

NSData *tripleDESCBCEncryptDecrypt(NSData *data, NSData *key1, NSData *key2, NSData *key3, BOOL encrypt) {
    if (data.length == 0 || key1.length != 8 || key2.length != 8 || key3.length != 8) {
        return [NSData new];
    }
    
    NSMutableData *cipher = [[NSMutableData alloc] initWithLength:valueGreaterOrEqualThan(data.length, 8)];
    DES_cblock init = { 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00 };
    DES_key_schedule sKey1;
    DES_key_schedule sKey2;
    DES_key_schedule sKey3;
    memset(&sKey1, 0, sizeof(DES_key_schedule));
    memset(&sKey2, 0, sizeof(DES_key_schedule));
    memset(&sKey3, 0, sizeof(DES_key_schedule));
    DES_set_key((DES_cblock *)key1.bytes, &sKey1);
    DES_set_key((DES_cblock *)key2.bytes, &sKey2);
    DES_set_key((DES_cblock *)key3.bytes, &sKey3);
    DES_ede3_cbc_encrypt(data.bytes, cipher.mutableBytes, data.length, &sKey1, &sKey2, &sKey3, &init, encrypt ? DES_ENCRYPT : DES_DECRYPT);
    return cipher;
}

NSData *objCTripleDESCBCFromData(NSData *data, NSData *key1, NSData *key2, NSData *key3) {
    return tripleDESCBCEncryptDecrypt(data, key1, key2, key3, YES);
}

NSData *objCDataFromTripleDESCBC(NSData *data, NSData *key1, NSData *key2, NSData *key3) {
    return tripleDESCBCEncryptDecrypt(data, key1, key2, key3, NO);
}