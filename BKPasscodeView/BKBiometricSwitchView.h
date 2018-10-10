//
//  BKBiometricSwitchView.h
//  BKPasscodeViewDemo
//
//  Created by Byungkook Jang on 2014. 10. 11..
//  Copyright (c) 2014년 Byungkook Jang. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol BKBiometricSwitchViewDelegate;


@interface BKBiometricSwitchView : UIView

@property (nonatomic, weak) id<BKBiometricSwitchViewDelegate> delegate;

@property (nonatomic, strong) UIView        *switchBackgroundView;
@property (nonatomic, strong) UILabel       *messageLabel;
@property (nonatomic, strong) UILabel       *titleLabel;
@property (nonatomic, strong) UISwitch      *biometricSwitch;
@property (nonatomic, strong) UIButton      *doneButton;

@end


@protocol BKBiometricSwitchViewDelegate <NSObject>

- (void)biometricSwitchViewDidPressDoneButton:(BKBiometricSwitchView *)view;

@end
