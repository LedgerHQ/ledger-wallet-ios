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

+ (NSString *)interfaceBuilderIdentifier;
+ (instancetype)instantiateFromMainStoryboard;
+ (instancetype)instantiateFromStoryboard:(UIStoryboard *)storyboard;
+ (instancetype)instantiateFromStoryboard:(UIStoryboard *)storyboard identifier:(NSString *)identifier;
+ (instancetype)instantiateFromNib;
+ (instancetype)instantiateFromNibNamed:(NSString *)name;
+ (instancetype)instantiateFromNibNamed:(NSString *)name bundle:(NSBundle *)bundle;

@end
