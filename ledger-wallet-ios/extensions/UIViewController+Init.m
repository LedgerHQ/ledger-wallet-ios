//
//  UIViewController+Init.h
//  ledger-wallet-ios
//
//  Created by Nicolas Bigot on 13/01/2015.
//  Copyright (c) 2015 Ledger. All rights reserved.
//

#import "UIViewController+Init.h"
#import "NSObject+Utils.h"

@implementation UIViewController (Init)

+ (instancetype)instantiateFromStoryboard:(UIStoryboard *)storyboard
{
    return [storyboard instantiateViewControllerWithIdentifier:[self className]];
}

+ (instancetype)instantiateFromNib
{
    return [self instantiateFromNibNamed:[self className]];
}

+ (instancetype)instantiateFromNibNamed:(NSString *)name
{
    return [[[self class] alloc] initWithNibName:name bundle:nil];
}

@end
