//
//  LoadingView.m
//  CarLinkChannel
//
//  Created by 刘润泽 on 2024/9/29.
//

#import "LoadingView.h"

@implementation LoadingView
- (instancetype)initWithMessage:(NSString *)message {
    self = [super initWithFrame:CGRectZero];
    if (self) {
        // 设置背景颜色为半透明
        self.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.8];

        // 初始化并设置转圈动画
        self.activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleLarge];
        self.activityIndicator.color = [UIColor whiteColor];
        self.activityIndicator.translatesAutoresizingMaskIntoConstraints = NO;
        self.activityIndicator.transform = CGAffineTransformMakeScale(1.5, 1.5);
        [self.activityIndicator startAnimating];
        [self addSubview:self.activityIndicator];

        // 初始化并设置提示文字标签
        self.messageLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        self.messageLabel.text = message;
        self.messageLabel.textColor = [UIColor whiteColor];
        self.messageLabel.font = [UIFont boldSystemFontOfSize:17];
        self.messageLabel.translatesAutoresizingMaskIntoConstraints = NO;
        self.messageLabel.textAlignment = NSTextAlignmentCenter;
        [self addSubview:self.messageLabel];

        // 添加自动布局约束
        [self setupConstraints];
    }
    return self;
}

- (void)setupConstraints {
    // 将转圈动画放在视图中央
    [self addConstraint:[NSLayoutConstraint constraintWithItem:self.activityIndicator
                                                     attribute:NSLayoutAttributeCenterX
                                                     relatedBy:NSLayoutRelationEqual
                                                        toItem:self
                                                     attribute:NSLayoutAttributeCenterX
                                                    multiplier:1.0
                                                      constant:0]];

    [self addConstraint:[NSLayoutConstraint constraintWithItem:self.activityIndicator
                                                     attribute:NSLayoutAttributeCenterY
                                                     relatedBy:NSLayoutRelationEqual
                                                        toItem:self
                                                     attribute:NSLayoutAttributeCenterY
                                                    multiplier:1.0
                                                      constant:-20]];

    // 将提示文字放在转圈动画的下方
    [self addConstraint:[NSLayoutConstraint constraintWithItem:self.messageLabel
                                                     attribute:NSLayoutAttributeTop
                                                     relatedBy:NSLayoutRelationEqual
                                                        toItem:self.activityIndicator
                                                     attribute:NSLayoutAttributeBottom
                                                    multiplier:1.0
                                                      constant:60]];

    [self addConstraint:[NSLayoutConstraint constraintWithItem:self.messageLabel
                                                     attribute:NSLayoutAttributeCenterX
                                                     relatedBy:NSLayoutRelationEqual
                                                        toItem:self
                                                     attribute:NSLayoutAttributeCenterX
                                                    multiplier:1.0
                                                      constant:0]];
}


@end
