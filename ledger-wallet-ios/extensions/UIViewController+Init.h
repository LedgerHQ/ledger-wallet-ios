//
//  UIViewController+Init.h
//  ledger-wallet-ios
//
//  Created by Nicolas Bigot on 13/01/2015.
//  Copyright (c) 2015 Ledger. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "UIViewController+Init.h"

@interface UIViewController (Init)

+ (instancetype)instantiateFromStoryboard:(UIStoryboard *)storyboard;
+ (instancetype)instantiateFromNib;
+ (instancetype)instantiateFromNibNamed:(NSString *)name;

@end
