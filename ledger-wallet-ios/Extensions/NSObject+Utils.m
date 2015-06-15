//
//  NSObject+Utils.m
//  ledger-wallet-ios
//
//  Created by Nicolas Bigot on 23/01/2015.
//  Copyright (c) 2015 Ledger. All rights reserved.
//

#import "NSObject+Utils.h"

@implementation NSObject (Utils)

+ (NSString *)className
{
    return [[NSStringFromClass(self) componentsSeparatedByString:@"."] lastObject];
}

- (NSString *)className
{
    return [self.class className];
}

@end
