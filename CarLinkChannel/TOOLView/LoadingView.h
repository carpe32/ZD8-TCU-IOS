//
//  LoadingView.h
//  CarLinkChannel
//
//  Created by 刘润泽 on 2024/9/29.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface LoadingView : UIView
@property (nonatomic, strong) UIActivityIndicatorView *activityIndicator;
@property (nonatomic, strong) UILabel *messageLabel;

- (instancetype)initWithMessage:(NSString *)message;
@end

NS_ASSUME_NONNULL_END
