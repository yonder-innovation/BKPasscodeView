//
//  BKPasscodeViewController.m
//  BKPasscodeViewDemo
//
//  Created by Byungkook Jang on 2014. 4. 20..
//  Copyright (c) 2014년 Byungkook Jang. All rights reserved.
//

#import "BKPasscodeViewController.h"
#import "BKShiftingView.h"
#import "AFViewShaker.h"
#import "BKPasscodeUtils.h"

typedef enum : NSUInteger {
    BKPasscodeViewControllerStateUnknown,
    BKPasscodeViewControllerStateCheckPassword,
    BKPasscodeViewControllerStateInputPassword,
    BKPasscodeViewControllerStateReinputPassword
} BKPasscodeViewControllerState;

#define kBKPasscodeOneMinuteInSeconds           (60)
#define kBKPasscodeDefaultKeyboardHeight        (216)

@interface BKPasscodeViewController ()

@property (nonatomic, strong) BKShiftingView                *shiftingView;

@property (nonatomic) BKPasscodeViewControllerState         currentState;
@property (nonatomic, strong) NSString                      *oldPasscode;
@property (nonatomic, strong) NSString                      *theNewPasscode;
@property (nonatomic, strong) NSTimer                       *lockStateUpdateTimer;
@property (nonatomic) CGFloat                               keyboardHeight;
@property (nonatomic, strong) AFViewShaker                  *viewShaker;

@property (nonatomic) BOOL                                  promptingTouchID;
@property (nonatomic) BOOL                                  isAuthorizing;

@end

@implementation BKPasscodeViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // init state
        _type = BKPasscodeViewControllerNewPasscodeType;
        _currentState = BKPasscodeViewControllerStateInputPassword;
        
        // create shifting view
        self.shiftingView = [[BKShiftingView alloc] init];
        self.shiftingView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        self.shiftingView.currentView = [self instantiatePasscodeInputView];
        
        // create top left button
        _topLeftButton = [[UIButton alloc] init];
        [_topLeftButton addTarget:self action:@selector(topLeftButtonPressed) forControlEvents:UIControlEventTouchUpInside];
        
        // keyboard notifications
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didReceiveKeyboardWillShowHideNotification:) name:UIKeyboardWillShowNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didReceiveKeyboardWillShowHideNotification:) name:UIKeyboardWillHideNotification object:nil];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didReceiveApplicationWillEnterForegroundNotification:)
                                                     name:UIApplicationWillEnterForegroundNotification
                                                   object:nil];
        
        self.keyboardHeight = kBKPasscodeDefaultKeyboardHeight;      // sometimes keyboard notification is not posted at all. so setting default value.
    }
    return self;
}

- (void)dealloc
{
    [self.lockStateUpdateTimer invalidate];
    self.lockStateUpdateTimer = nil;
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)setType:(BKPasscodeViewControllerType)type
{
    if (_type == type) {
        return;
    }
    
    _type = type;
    
    switch (type) {
        case BKPasscodeViewControllerNewPasscodeType:
            self.currentState = BKPasscodeViewControllerStateInputPassword;
            break;
        default:
            self.currentState = BKPasscodeViewControllerStateCheckPassword;
            break;
    }
}

- (void)setIsTopLeftButtonVisible:(BOOL)isTopLeftButtonVisible
{
    _isTopLeftButtonVisible = isTopLeftButtonVisible;
    self.topLeftButton.hidden = !isTopLeftButtonVisible;
}

- (BKPasscodeInputView *)passcodeInputView
{
    if (NO == [self.shiftingView.currentView isKindOfClass:[BKPasscodeInputView class]]) {
        return nil;
    }
    
    return (BKPasscodeInputView *)self.shiftingView.currentView;
}

- (BKPasscodeInputView *)instantiatePasscodeInputView
{
    BKPasscodeInputView *view = [[BKPasscodeInputView alloc] init];
    view.delegate = self;
    view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    
    return view;
}

- (void)configureTopLeftButton
{
    [self.view addSubview:_topLeftButton];
    
    _topLeftButton.translatesAutoresizingMaskIntoConstraints = false;
    
    [_topLeftButton.leadingAnchor
     constraintEqualToAnchor:self.view.leadingAnchor constant: 15].active = true;
    
    if (@available(iOS 11, *)) {
        [_topLeftButton.topAnchor
         constraintEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor constant: 5].active = true;
    } else {
        [_topLeftButton.topAnchor
         constraintEqualToAnchor:self.view.topAnchor constant: 5].active = true;
    }
    
    _topLeftButton.hidden = false;
}

- (void)customizePasscodeInputView:(BKPasscodeInputView *)aPasscodeInputView
{
}


- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self.view setBackgroundColor:[UIColor colorWithRed:0.94 green:0.94 blue:0.96 alpha:1]];
    
    [self updatePasscodeInputViewTitle:self.passcodeInputView];
    
    [self customizePasscodeInputView:self.passcodeInputView];
    
    [self.view addSubview:self.shiftingView];
    
    [self configureTopLeftButton];
    
    [self lockIfNeeded];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    if (self.passcodeInputView.isEnabled) {
        [self startTouchIDAuthenticationIfPossible];
    }
    
    [self.passcodeInputView becomeFirstResponder];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    [self.view endEditing:YES];
}

- (void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
    
    CGRect frame = self.view.bounds;
    
    CGFloat topBarOffset = 0;
    if ([self respondsToSelector:@selector(topLayoutGuide)]) {
        topBarOffset = [self.topLayoutGuide length];
    }
    
    frame.origin.y += topBarOffset;
    frame.size.height -= (topBarOffset + self.keyboardHeight);
    
    self.shiftingView.frame = frame;
}

#pragma mark - Public methods

- (void)setPasscodeStyle:(BKPasscodeInputViewPasscodeStyle)passcodeStyle
{
    self.passcodeInputView.passcodeStyle = passcodeStyle;
}

- (BKPasscodeInputViewPasscodeStyle)passcodeStyle
{
    return self.passcodeInputView.passcodeStyle;
}

- (void)setKeyboardType:(UIKeyboardType)keyboardType
{
    self.passcodeInputView.keyboardType = keyboardType;
}

- (UIKeyboardType)keyboardType
{
    return self.passcodeInputView.keyboardType;
}

- (void)showLockMessageWithLockUntilDate:(NSDate *)lockUntil
{
    NSTimeInterval timeInterval = [lockUntil timeIntervalSinceNow];
    NSUInteger minutes = ceilf(timeInterval / 60.0f);
    
    BKPasscodeInputView *inputView = self.passcodeInputView;
    inputView.enabled = NO;
    
    if (minutes == 1) {
        inputView.title = NSLocalizedStringFromTable(@"Try again in 1 minute", @"BKPasscodeView", nil);
    } else {
        inputView.title = [NSString stringWithFormat:NSLocalizedStringFromTable(@"Try again in %d minutes", @"BKPasscodeView", nil), minutes];
    }
    
    NSUInteger numberOfFailedAttempts = [self.delegate passcodeViewControllerNumberOfFailedAttempts:self];
    
    [self showFailedAttemptsCount:numberOfFailedAttempts inputView:inputView];
    
    if (self.lockStateUpdateTimer == nil) {
        
        NSTimeInterval delay = timeInterval + kBKPasscodeOneMinuteInSeconds - (kBKPasscodeOneMinuteInSeconds * (NSTimeInterval)minutes);
        
        self.lockStateUpdateTimer = [[NSTimer alloc] initWithFireDate:[NSDate dateWithTimeIntervalSinceNow:delay]
                                                             interval:60.f
                                                               target:self
                                                             selector:@selector(lockStateUpdateTimerFired:)
                                                             userInfo:nil
                                                              repeats:YES];
        
        [[NSRunLoop currentRunLoop] addTimer:self.lockStateUpdateTimer forMode:NSDefaultRunLoopMode];
    }
}

- (BOOL)lockIfNeeded
{
    if (self.currentState != BKPasscodeViewControllerStateCheckPassword) {
        return NO;
    }
    
    if (NO == [self.delegate respondsToSelector:@selector(passcodeViewControllerLockUntilDate:)]) {
        return NO;
    }
    
    NSDate *lockUntil = [self.delegate passcodeViewControllerLockUntilDate:self];
    if (lockUntil == nil || [lockUntil timeIntervalSinceNow] < 0) {
        return NO;
    }
    
    [self showLockMessageWithLockUntilDate:lockUntil];
    
    return YES;
}

- (void)updateLockMessageOrUnlockIfNeeded
{
    if (self.currentState != BKPasscodeViewControllerStateCheckPassword) {
        return;
    }
    
    if (NO == [self.delegate respondsToSelector:@selector(passcodeViewControllerLockUntilDate:)]) {
        return;
    }
    
    BKPasscodeInputView *inputView = self.passcodeInputView;
    
    NSDate *lockUntil = [self.delegate passcodeViewControllerLockUntilDate:self];
    
    if (lockUntil == nil || [lockUntil timeIntervalSinceNow] < 0) {
        
        // invalidate timer
        [self.lockStateUpdateTimer invalidate];
        self.lockStateUpdateTimer = nil;
        
        [self updatePasscodeInputViewTitle:inputView];
        
        inputView.enabled = YES;
        
    } else {
        [self showLockMessageWithLockUntilDate:lockUntil];
    }
}

- (void)lockStateUpdateTimerFired:(NSTimer *)timer
{
    [self updateLockMessageOrUnlockIfNeeded];
}

- (void)startTouchIDAuthenticationIfPossible
{
    [self startTouchIDAuthenticationIfPossible:nil];
}

- (void)startTouchIDAuthenticationIfPossible:(void (^)(BOOL))aCompletionBlock
{
    if (NO == [self canAuthenticateWithTouchID] || self.isAuthorizing) {
        if (aCompletionBlock) {
            aCompletionBlock(NO);
        }
        return;
    }
    
    self.promptingTouchID = YES;
    
    [self.biometricsManager loadPasscodeWithCompletionBlock:^(NSString *passcode) {
        
        self.promptingTouchID = NO;
        
        if (passcode) {
            
            self.passcodeInputView.passcode = passcode;
            
            [self passcodeInputViewDidFinish:self.passcodeInputView];
        }
        
        if (aCompletionBlock) {
            aCompletionBlock(YES);
        }
    }];
}

#pragma mark - Private methods

-(void)topLeftButtonPressed
{
    if ([self.delegate respondsToSelector:@selector(passcodeViewControllerDidPressTopLeftButton:)]) {
        [self.delegate passcodeViewControllerDidPressTopLeftButton:self];
    }
}

- (void) updatePasscodeInputViewTitle:(BKPasscodeInputView *)passcodeInputView
{
    switch (self.currentState) {
        case BKPasscodeViewControllerStateCheckPassword:
            if (self.type == BKPasscodeViewControllerChangePasscodeType) {
                passcodeInputView.title = NSLocalizedStringFromTable(@"Enter your old passcode", @"BKPasscodeView",nil);
            } else {
                passcodeInputView.title = NSLocalizedStringFromTable(@"Enter your passcode", @"BKPasscodeView", nil);
            }
            break;
            
        case BKPasscodeViewControllerStateInputPassword:
            if (self.type == BKPasscodeViewControllerChangePasscodeType) {
                passcodeInputView.title = NSLocalizedStringFromTable(@"Enter your new passcode", @"BKPasscodeView", nil);
            } else {
                passcodeInputView.title = NSLocalizedStringFromTable(@"Enter a passcode", @"BKPasscodeView", nil);
            }
            break;
            
        case BKPasscodeViewControllerStateReinputPassword:
            passcodeInputView.title = NSLocalizedStringFromTable(@"Re-enter your passcode", @"BKPasscodeView", nil);
            break;
            
        default:
            break;
    }
}

- (void)showFailedAttemptsCount:(NSUInteger)failCount inputView:(BKPasscodeInputView *)aInputView
{
    if (failCount == 0) {
        aInputView.errorMessage = NSLocalizedStringFromTable(@"Invalid Passcode", @"BKPasscodeView", nil);
    } else if (failCount == 1) {
        aInputView.errorMessage = NSLocalizedStringFromTable(@"1 Failed Passcode Attempt", @"BKPasscodeView", nil);
    } else {
        aInputView.errorMessage = [NSString stringWithFormat:NSLocalizedStringFromTable(@"%d Failed Passcode Attempts", @"BKPasscodeView", nil), failCount];
    }
}

- (void)showBiometricSwitchView
{
    BKBiometricSwitchView *view = [[BKBiometricSwitchView alloc] init];
    view.delegate = self;
    view.biometricSwitch.on = self.biometricsManager.isBiometricsEnabled;
    
    [self.shiftingView showView:view withDirection:BKShiftingDirectionForward];
}

- (BOOL)canAuthenticateWithTouchID
{
    if (NO == [BKBiometricsManager canUseBiometrics]) {
        return NO;
    }
    
    if (self.type != BKPasscodeViewControllerCheckPasscodeType) {
        return NO;
    }
    
    if (nil == self.biometricsManager || NO == self.biometricsManager.isBiometricsEnabled) {
        return NO;
    }
    
    if (self.promptingTouchID) {
        return NO;
    }
    
    if ([UIApplication sharedApplication].applicationState == UIApplicationStateInactive) {
        return NO;
    }
    
    return YES;
}

#pragma mark - BKPasscodeInputViewDelegate

- (void)passcodeInputViewDidFinish:(BKPasscodeInputView *)aInputView
{
    NSString *passcode = aInputView.passcode;
    
    switch (self.currentState) {
        case BKPasscodeViewControllerStateCheckPassword:
        {
            if (self.promptingTouchID) {
                
                return;
                
            }
            
            self.isAuthorizing = YES;
            
            NSAssert([self.delegate respondsToSelector:@selector(passcodeViewController:authenticatePasscode:resultHandler:)],
                     @"delegate must implement passcodeViewController:authenticatePasscode:resultHandler:");
            
            [self.delegate passcodeViewController:self authenticatePasscode:passcode resultHandler:^(BOOL succeed) {
                
                self.isAuthorizing = NO;
                NSAssert([NSThread isMainThread], @"you must invoke result handler in main thread.");
                
                if (succeed) {
                    
                    if (self.type == BKPasscodeViewControllerChangePasscodeType) {
                        
                        self.oldPasscode = passcode;
                        self.currentState = BKPasscodeViewControllerStateInputPassword;
                        
                        BKPasscodeInputView *newPasscodeInputView = [self.passcodeInputView copy];
                        
                        [self customizePasscodeInputView:newPasscodeInputView];
                        
                        [self updatePasscodeInputViewTitle:newPasscodeInputView];
                        [self.shiftingView showView:newPasscodeInputView withDirection:BKShiftingDirectionForward];
                        
                        [self.passcodeInputView becomeFirstResponder];
                        
                    } else {
                        
                        [self.delegate passcodeViewController:self didFinishWithPasscode:passcode];
                        
                    }
                    
                } else {
                    
                    if ([self.delegate respondsToSelector:@selector(passcodeViewControllerDidFailAttempt:)]) {
                        [self.delegate passcodeViewControllerDidFailAttempt:self];
                    }
                    
                    NSUInteger failCount = 0;
                    
                    if ([self.delegate respondsToSelector:@selector(passcodeViewControllerNumberOfFailedAttempts:)]) {
                        failCount = [self.delegate passcodeViewControllerNumberOfFailedAttempts:self];
                    }
                    
                    [self showFailedAttemptsCount:failCount inputView:aInputView];
                    
                    // reset entered passcode
                    aInputView.passcode = nil;
                    
                    // shake
                    self.viewShaker = [[AFViewShaker alloc] initWithView:aInputView.passcodeField];
                    [self.viewShaker shakeWithDuration:0.5f completion:nil];
                    
                    // lock if needed
                    if ([self.delegate respondsToSelector:@selector(passcodeViewControllerLockUntilDate:)]) {
                        NSDate *lockUntilDate = [self.delegate passcodeViewControllerLockUntilDate:self];
                        if (lockUntilDate != nil) {
                            [self showLockMessageWithLockUntilDate:lockUntilDate];
                        }
                    }
                    
                }
            }];
            
            break;
        }
        case BKPasscodeViewControllerStateInputPassword:
        {
            if (self.type == BKPasscodeViewControllerChangePasscodeType && [self.oldPasscode isEqualToString:passcode]) {
                
                aInputView.passcode = nil;
                aInputView.message = NSLocalizedStringFromTable(@"Enter a different passcode. Cannot re-use the same passcode.", @"BKPasscodeView", nil);
                
            } else {
                
                self.theNewPasscode = passcode;
                self.currentState = BKPasscodeViewControllerStateReinputPassword;
                
                BKPasscodeInputView *newPasscodeInputView = [self.passcodeInputView copy];
                
                [self customizePasscodeInputView:newPasscodeInputView];
                
                [self updatePasscodeInputViewTitle:newPasscodeInputView];
                [self.shiftingView showView:newPasscodeInputView withDirection:BKShiftingDirectionForward];
                
                [self.passcodeInputView becomeFirstResponder];
            }
            
            break;
        }
        case BKPasscodeViewControllerStateReinputPassword:
        {
            if ([passcode isEqualToString:self.theNewPasscode]) {
                
                if (self.biometricsManager && [BKBiometricsManager canUseBiometrics]) {
                    [self showBiometricSwitchView];
                } else {
                    [self.delegate passcodeViewController:self didFinishWithPasscode:passcode];
                }
                
            } else {
                
                self.currentState = BKPasscodeViewControllerStateInputPassword;
                
                BKPasscodeInputView *newPasscodeInputView = [self.passcodeInputView copy];
                
                [self customizePasscodeInputView:newPasscodeInputView];
                
                [self updatePasscodeInputViewTitle:newPasscodeInputView];
                
                newPasscodeInputView.message = NSLocalizedStringFromTable(@"Passcodes did not match.\nTry again.", @"BKPasscodeView", nil);
                
                [self.shiftingView showView:newPasscodeInputView withDirection:BKShiftingDirectionBackward];
                
                [self.passcodeInputView becomeFirstResponder];
            }
            break;
        }
        default:
            break;
    }
}

#pragma mark - BKTouchIDSwitchViewDelegate

- (void)biometricSwitchViewDidPressDoneButton:(BKBiometricSwitchView *)view
{
    BOOL enabled = view.biometricSwitch.isOn;
    
    if (enabled) {
        
        [self.biometricsManager savePasscode:self.theNewPasscode completionBlock:^(BOOL success) {
            if (success) {
                [self.delegate passcodeViewController:self didFinishWithPasscode:self.theNewPasscode];
            } else {
                if ([self.delegate respondsToSelector:@selector(passcodeViewControllerDidFailTouchIDKeychainOperation:)]) {
                    [self.delegate passcodeViewControllerDidFailTouchIDKeychainOperation:self];
                }
            }
        }];
        
    } else {
        
        [self.biometricsManager deletePasscodeWithCompletionBlock:^(BOOL success) {
            if (success) {
                [self.delegate passcodeViewController:self didFinishWithPasscode:self.theNewPasscode];
            } else {
                if ([self.delegate respondsToSelector:@selector(passcodeViewControllerDidFailTouchIDKeychainOperation:)]) {
                    [self.delegate passcodeViewControllerDidFailTouchIDKeychainOperation:self];
                }
            }
        }];
    }
}

#pragma mark - Notifications

- (void)didReceiveKeyboardWillShowHideNotification:(NSNotification *)notification
{
    CGRect keyboardRect = [notification.userInfo[UIKeyboardFrameEndUserInfoKey] CGRectValue];
    
    if (SYSTEM_VERSION_LESS_THAN(@"8.0")) {
        UIInterfaceOrientation statusBarOrientation = [[UIApplication sharedApplication] statusBarOrientation];
        self.keyboardHeight = UIInterfaceOrientationIsPortrait(statusBarOrientation) ? CGRectGetHeight(keyboardRect) : CGRectGetWidth(keyboardRect);
    } else {
        self.keyboardHeight = CGRectGetHeight(keyboardRect);
    }
    
    [self.view setNeedsLayout];
}

- (void)didReceiveApplicationWillEnterForegroundNotification:(NSNotification *)notification
{
    [self startTouchIDAuthenticationIfPossible];
}

@end
