//
//  BKBiometricSwitchView.m
//  BKPasscodeViewDemo
//
//  Created by Byungkook Jang on 2014. 10. 11..
//  Copyright (c) 2014년 Byungkook Jang. All rights reserved.
//

#import "BKBiometricSwitchView.h"
#import "BKBiometricsManager.h"

@implementation BKBiometricSwitchView

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self _initialize];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self _initialize];
    }
    return self;
}

- (void)_initialize
{
    self.switchBackgroundView = [[UIView alloc] init];
    self.switchBackgroundView.backgroundColor = [UIColor whiteColor];
    self.switchBackgroundView.layer.borderColor = [UIColor lightGrayColor].CGColor;
    self.switchBackgroundView.layer.borderWidth = .5f;
    [self addSubview:self.switchBackgroundView];
    
    self.messageLabel = [[UILabel alloc] init];
    self.messageLabel.numberOfLines = 0;
    self.messageLabel.lineBreakMode = NSLineBreakByWordWrapping;
    self.messageLabel.textAlignment = NSTextAlignmentCenter;
    self.messageLabel.text = NSLocalizedStringFromTable(@"Do you want to use Touch ID for authentication?", @"BKPasscodeView", @"Touch ID를 사용하시겠습니까?");
    if (@available(iOS 11.0, *)) {
        if ([BKBiometricsManager supportedBiometricType] == LABiometryTypeFaceID) {
            self.messageLabel.text = NSLocalizedStringFromTable(@"Do you want to use Face ID for authentication?", @"BKPasscodeView", @"Face ID를 사용하시겠습니까?");
        }
    }
    self.messageLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleHeadline];
    [self addSubview:self.messageLabel];
    
    self.titleLabel = [[UILabel alloc] init];
    self.titleLabel.text = NSLocalizedStringFromTable(@"Enable Touch ID", @"BKPasscodeView", @"Touch ID 사용");
    if (@available(iOS 11.0, *)) {
        if ([BKBiometricsManager supportedBiometricType] == LABiometryTypeFaceID) {
            self.titleLabel.text = NSLocalizedStringFromTable(@"Enable Face ID", @"BKPasscodeView", @"Face ID 사용");
        }
    }
    self.titleLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleBody];
    [self addSubview:self.titleLabel];
    
    self.biometricSwitch = [[UISwitch alloc] init];
    [self addSubview:self.biometricSwitch];
    
    self.doneButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [self.doneButton.titleLabel setFont:[UIFont systemFontOfSize:20.f]];
    [self.doneButton setTitle:NSLocalizedStringFromTable(@"Done", @"BKPasscodeView", @"확인") forState:UIControlStateNormal];
    [self.doneButton addTarget:self action:@selector(doneButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:self.doneButton];
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    UIEdgeInsets contentInset = UIEdgeInsetsMake(20, 20, 20, 20);
    static CGFloat verticalSpaces[] = { 40, 30 };
    
    CGRect contentBounds = UIEdgeInsetsInsetRect(self.bounds, contentInset);
    
    self.messageLabel.frame = CGRectMake(0, 0, CGRectGetWidth(contentBounds), 0);
    [self.messageLabel sizeToFit];
    
    [self.titleLabel sizeToFit];
    
    [self.doneButton sizeToFit];
    
    CGFloat contentHeight = (CGRectGetHeight(self.messageLabel.frame) + verticalSpaces[0] +
                             CGRectGetHeight(self.biometricSwitch.frame) + verticalSpaces[1] +
                             CGRectGetHeight(self.doneButton.frame));
    
    CGFloat offsetY = floorf((CGRectGetHeight(self.frame) - contentHeight) * 0.5f);
    
    CGRect rect;
    
    rect = self.messageLabel.frame;
    rect.origin = CGPointMake(contentInset.left, offsetY);
    rect.size.width = CGRectGetWidth(contentBounds);
    self.messageLabel.frame = rect;
    
    offsetY += CGRectGetHeight(rect) + verticalSpaces[0];

    rect = self.biometricSwitch.frame;
    rect.origin = CGPointMake(CGRectGetMaxX(contentBounds) - CGRectGetWidth(self.biometricSwitch.frame), offsetY);
    self.biometricSwitch.frame = rect;
    
    rect = self.titleLabel.frame;
    rect.origin = CGPointMake(contentInset.left, offsetY);
    rect.size.height = CGRectGetHeight(self.biometricSwitch.frame);
    self.titleLabel.frame = rect;
    
    offsetY += CGRectGetHeight(rect) + verticalSpaces[1];
    
    rect = self.doneButton.frame;
    rect.size.width += 10;
    rect.size.height += 10;
    rect.origin.x = floorf((CGRectGetWidth(self.frame) - CGRectGetWidth(rect)) * 0.5f);
    rect.origin.y = offsetY;
    self.doneButton.frame = rect;
    
    self.switchBackgroundView.frame = CGRectMake(-1,
                                                 CGRectGetMinY(self.biometricSwitch.frame) - 12,
                                                 CGRectGetWidth(self.frame) + 2,
                                                 CGRectGetHeight(self.biometricSwitch.frame) + 24);
    
}

- (void)doneButtonPressed:(id)sender
{
    if ([self.delegate respondsToSelector:@selector(biometricSwitchViewDidPressDoneButton:)]) {
        [self.delegate biometricSwitchViewDidPressDoneButton:self];
    }
}

@end
