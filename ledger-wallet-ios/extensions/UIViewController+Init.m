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
    return [self instantiateFromStoryboard:storyboard identifier:[self className]];
}

+ (instancetype)instantiateFromStoryboard:(UIStoryboard *)storyboard identifier:(NSString *)identifier
{
    return [storyboard instantiateViewControllerWithIdentifier:identifier];
}

+ (instancetype)instantiateFromNib
{
    return [self instantiateFromNibNamed:[self className]];
}

+ (instancetype)instantiateFromNibNamed:(NSString *)name
{
    return [self instantiateFromNibNamed:name bundle:nil];
}

+ (instancetype)instantiateFromNibNamed:(NSString *)name bundle:(NSBundle *)bundle
{
    return [[[self class] alloc] initWithNibName:name bundle:bundle];
}

@end
