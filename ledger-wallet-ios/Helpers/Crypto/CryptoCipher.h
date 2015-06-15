//
//  CryptoCipher.h
//  ledger-wallet-ios
//
//  Created by Nicolas Bigot on 06/02/2015.
//  Copyright (c) 2015 Ledger. All rights reserved.
//

#ifndef ledger_wallet_ios_CryptoCipher_h
#define ledger_wallet_ios_CryptoCipher_h

#import <Foundation/Foundation.h>
#import <openssl/des.h>

NSData *objCTripleDESCBCFromData(NSData *data, NSData *key1, NSData *key2, NSData *key3);
NSData *objCDataFromTripleDESCBC(NSData *data, NSData *key1, NSData *key2, NSData *key3);

#endif
