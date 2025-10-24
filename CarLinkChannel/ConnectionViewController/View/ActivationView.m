//
//  ActivationView.m
//  CarLinkChannel
//
//  Created by job on 2023/3/29.
//

#import "ActivationView.h"
@interface ActivationView ()
@property (nonatomic, assign) CGFloat normalBottomY; // 正常状态下的Y位置（屏幕高度 - 视图高度）
@property (nonatomic, assign) BOOL isShowing; // 是否正在显示
@end
@implementation ActivationView


- (void)awakeFromNib {
    [super awakeFromNib];
    [self setupKeyboardNotifications];
    self.isShowing = NO;
}

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self setupKeyboardNotifications];
        self.isShowing = NO;
    }
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - Public Methods

// 显示视图时调用
- (void)showView {
    self.isShowing = YES;
    NSLog(@"开始显示视图");
}

// 隐藏视图时调用
- (void)hideView {
    self.isShowing = NO;
    NSLog(@"开始隐藏视图");
}

#pragma mark - Keyboard Notifications

- (void)setupKeyboardNotifications {
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillShow:)
                                                 name:UIKeyboardWillShowNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillHide:)
                                                 name:UIKeyboardWillHideNotification
                                               object:nil];
}

- (void)keyboardWillShow:(NSNotification *)notification {
    if (!self.isShowing) return;
    
    NSDictionary *userInfo = notification.userInfo;
    CGRect keyboardFrame = [[userInfo objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue];
    NSTimeInterval animationDuration = [[userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey] doubleValue];
    
    // 计算键盘高度
    CGFloat keyboardHeight = keyboardFrame.size.height;
    
    // 计算安全区域（如果有的话）
    CGFloat safeAreaBottom = 0;
    if (@available(iOS 11.0, *)) {
        safeAreaBottom = self.superview.safeAreaInsets.bottom;
    }
    
    // 添加额外的边距，让视图不被键盘挡住
    CGFloat extraMargin = 20.0; // 你可以调整这个值，比如改成 15.0 或 20.0
    
    // 计算目标位置：父视图高度 - 视图高度 - 键盘高度 + 安全区域 - 额外边距
    CGFloat targetY = self.superview.bounds.size.height - self.frame.size.height - keyboardHeight + safeAreaBottom - extraMargin;
    
    // 确保不超出屏幕顶部
    targetY = MAX(targetY, 0);
    
    NSLog(@"键盘显示 - 键盘高度: %.2f, 父视图高度: %.2f, 视图高度: %.2f, 额外边距: %.2f, 目标Y: %.2f",
          keyboardHeight, self.superview.bounds.size.height, self.frame.size.height, extraMargin, targetY);
    
    [UIView animateWithDuration:animationDuration animations:^{
        CGRect frame = self.frame;
        frame.origin.y = targetY;
        self.frame = frame;
        NSLog(@"键盘显示动画 - 设置Y: %.2f", targetY);
    }];
}

- (void)keyboardWillHide:(NSNotification *)notification {
    if (!self.isShowing) return;
    
    NSDictionary *userInfo = notification.userInfo;
    NSTimeInterval animationDuration = [[userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey] doubleValue];
    
    // 回到底部位置
    CGFloat targetY = self.superview.bounds.size.height - self.frame.size.height;
    
    NSLog(@"键盘隐藏 - 目标Y: %.2f", targetY);
    
    [UIView animateWithDuration:animationDuration animations:^{
        CGRect frame = self.frame;
        frame.origin.y = targetY;
        self.frame = frame;
        NSLog(@"键盘隐藏动画 - 设置Y: %.2f", targetY);
    }];
}



- (IBAction)activationButtonTarget:(id)sender {
    
    NSString * code = [self.codeField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    NSDictionary * data = @{@"code":code};
    NSLog(@"发送激活通知: %@",data);
    [[NSNotificationCenter defaultCenter] postNotificationName:activation_notify_name object:nil userInfo:data];
}

@end
