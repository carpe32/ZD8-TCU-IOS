//
//  PopWindow.m
//  CarLinkChannel
//
//  Created by 刘润泽 on 2025/4/22.
//

#import "PopWindow.h"

@implementation PopWindow
+(void)showAlertWithTitle:(NSString *)title
                   message:(NSString *)message
                buttonTitle:(NSString *)buttonTitle {
    dispatch_async(dispatch_get_main_queue(), ^{
        UIAlertAction *action = [UIAlertAction actionWithTitle:buttonTitle
                                                         style:UIAlertActionStyleDefault
                                                       handler:nil];

        UIAlertController *alert = [UIAlertController alertControllerWithTitle:title
                                                                       message:message
                                                                preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:action];

        if (@available(iOS 15.0, *)) {
            NSSet<UIScene *> *scenes = [UIApplication sharedApplication].connectedScenes;
            UIWindowScene *scene = (UIWindowScene *)[scenes anyObject];
            UIWindow *window = scene.keyWindow;
            [window.rootViewController presentViewController:alert animated:YES completion:nil];
        } else {
            UIWindow *window = [UIApplication sharedApplication].keyWindow;
            [window.rootViewController presentViewController:alert animated:YES completion:nil];
        }
    });
}


+(void)showFlashErrorAlertWithErrorCode:(NSString *)tittle Code:(uint32_t)errorCode info:(NSString *)info {
    dispatch_async(dispatch_get_main_queue(), ^{
    // 构造错误码字符串
        NSString *errorMessage = [NSString stringWithFormat:@"Error code: %08X", errorCode];

        // 根据 info 判断内容
        NSString *message;
        if ([info isEqual:OperationBasicDeficiency]) {
            message = [NSString stringWithFormat:@"%@\r\n\r\n%@", FAIL_FLASH_BASE_CONTENT, errorMessage];
        } else {
            message = [NSString stringWithFormat:@"%@\r\n\r\n%@", FAIL_FLASH_FILE_CONTENT, errorMessage];
        }

        // 创建 UIAlertController
        UIAlertAction *action = [UIAlertAction actionWithTitle:DONE_WRITE_ALLOW_TEXT
                                                         style:UIAlertActionStyleDefault
                                                       handler:nil];
        
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:tittle
                                                                       message:message
                                                                preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:action];

        // 显示弹窗（兼容 iOS 15+）
        if (@available(iOS 15.0, *)) {
            NSSet<UIScene *> *scenes = [UIApplication sharedApplication].connectedScenes;
            UIWindowScene *scene = (UIWindowScene *)[scenes anyObject];
            UIWindow *window = scene.keyWindow;
            [window.rootViewController presentViewController:alert animated:YES completion:nil];
        } else {
            UIWindow *window = [UIApplication sharedApplication].keyWindow;
            [window.rootViewController presentViewController:alert animated:YES completion:nil];
        }
    });
}

+ (void)showFlashErrorAlertWithErrorCode:(NSString *)tittle
                                    Code:(uint32_t)errorCode
                                    info:(NSString *)info
                       secondButtonTitle:(NSString *)secondButtonTitle
                       secondButtonBlock:(void (^)(UIAlertAction *action))secondButtonBlock {
    dispatch_async(dispatch_get_main_queue(), ^{
        // 构造错误码字符串
        NSString *errorMessage = [NSString stringWithFormat:@"Error code: %08X", errorCode];

        // 根据 info 判断内容
        NSString *message;
        if([info isEqual:@"REBASE"])
        {
            message = [NSString stringWithFormat:@"%@", FAIL_FLASH_BASE_RECOVER];
        }
        else if ([info isEqual:OperationBasicDeficiency]) {
            message = [NSString stringWithFormat:@"%@\r\n\r\n%@", FAIL_FLASH_BASE_CONTENT, errorMessage];
        } else {
            message = [NSString stringWithFormat:@"%@\r\n\r\n%@", FAIL_FLASH_FILE_CONTENT, errorMessage];
        }

        // 创建 UIAlertController
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:tittle
                                                                       message:message
                                                                preferredStyle:UIAlertControllerStyleAlert];

        // 默认确定按钮
        UIAlertAction *action = [UIAlertAction actionWithTitle:DONE_WRITE_ALLOW_TEXT
                                                         style:UIAlertActionStyleDefault
                                                       handler:nil];
        [alert addAction:action];

        // 可选第二个按钮
        if (secondButtonTitle && secondButtonBlock) {
            UIAlertAction *secondAction = [UIAlertAction actionWithTitle:secondButtonTitle
                                                                   style:UIAlertActionStyleDefault
                                                                 handler:secondButtonBlock];
            [alert addAction:secondAction];
        }

        // 显示弹窗（兼容 iOS 15+）
        if (@available(iOS 15.0, *)) {
            NSSet<UIScene *> *scenes = [UIApplication sharedApplication].connectedScenes;
            UIWindowScene *scene = (UIWindowScene *)[scenes anyObject];
            UIWindow *window = scene.keyWindow;
            [window.rootViewController presentViewController:alert animated:YES completion:nil];
        } else {
            UIWindow *window = [UIApplication sharedApplication].keyWindow;
            [window.rootViewController presentViewController:alert animated:YES completion:nil];
        }
    });
}



+(void)showErrorAlertWithTitle:(NSString *)title
                        message:(NSString *)message
                   actionTitle:(NSString *)actionTitle
                  actionHandler:(void (^)(void))handler {
        dispatch_async(dispatch_get_main_queue(), ^{
        
        // 创建“自定义按钮”
        UIAlertAction *customAction = [UIAlertAction actionWithTitle:actionTitle
                                                               style:UIAlertActionStyleDefault
                                                             handler:^(UIAlertAction * _Nonnull action) {
            if (handler) {
                handler(); // 执行回调
            }
        }];
        
        // 创建“取消”按钮
        UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"Cancel"
                                                               style:UIAlertActionStyleCancel
                                                             handler:nil];
        
        // 创建 UIAlertController
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:title
                                                                       message:message
                                                                preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:cancelAction];
        [alert addAction:customAction];
        
        // 显示弹窗（iOS 15+ 支持 Scene）
        if (@available(iOS 15.0, *)) {
            NSSet<UIScene *> *scenes = [UIApplication sharedApplication].connectedScenes;
            UIWindowScene *scene = (UIWindowScene *)[scenes anyObject];
            UIWindow *window = scene.keyWindow;
            [window.rootViewController presentViewController:alert animated:YES completion:nil];
        } else {
            UIWindow *window = [UIApplication sharedApplication].keyWindow;
            [window.rootViewController presentViewController:alert animated:YES completion:nil];
        }
    });
}

@end
