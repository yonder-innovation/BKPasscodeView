//
//  BKBiometricsManager.h
//  BKPasscodeViewDemo
//
//  Created by Kevin Mun on 10/10/2018.
//  Copyright © 2018 Byungkook Jang. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <LocalAuthentication/LocalAuthentication.h>

@interface BKBiometricsManager : NSObject

@property (nonatomic, strong, readonly) NSString                    *keychainServiceName;
@property (nonatomic, strong) NSString                              *promptText;
@property (nonatomic, readonly, getter=isBiometricsEnabled) BOOL    biometricsEnabled;

+ (BOOL)canUseBiometrics;

+ (LABiometryType)supportedBiometricType API_AVAILABLE(ios(11.0.1));

- (instancetype)initWithKeychainServiceName:(NSString *)serviceName;

- (void)savePasscode:(NSString *)passcode completionBlock:(void(^)(BOOL success))completionBlock;

- (void)loadPasscodeWithCompletionBlock:(void(^)(NSString *passcode))completionBlock;

- (void)deletePasscodeWithCompletionBlock:(void(^)(BOOL success))completionBlock;

@end
