//
//  UIViewController+Init.h
//  ledger-wallet-ios
//
//  Created by Nicolas Bigot on 13/01/2015.
//  Copyright (c) 2015 Ledger. All rights reserved.
//

#import "UIViewController+Init.h"

@implementation UIViewController (Init)

+ (NSString *)className {
    return [[NSStringFromClass(self) componentsSeparatedByString:@"."] lastObject];
}

+ (instancetype)instantiateFromStoryboard:(UIStoryboard *)storyboard
{
    return [storyboard instantiateViewControllerWithIdentifier:[self className]];
}

@end
