//
//  PopWindow.h
//  CarLinkChannel
//
//  Created by 刘润泽 on 2025/4/22.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "VehicleTypeProgramming.h"
NS_ASSUME_NONNULL_BEGIN

@interface PopWindow : NSObject
+(void)showAlertWithTitle:(NSString *)title
                   message:(NSString *)message
              buttonTitle:(NSString *)buttonTitle;
+(void)showFlashErrorAlertWithErrorCode:(NSString *)tittle Code:(uint32_t)errorCode info:(NSString *)info;

+ (void)showFlashErrorAlertWithErrorCode:(NSString *)tittle
                                    Code:(uint32_t)errorCode
                                    info:(NSString *)info
                       secondButtonTitle:(NSString *)secondButtonTitle
                       secondButtonBlock:(void (^)(UIAlertAction *action))secondButtonBlock ;

+(void)showErrorAlertWithTitle:(NSString *)title
                        message:(NSString *)message
                   actionTitle:(NSString *)actionTitle
                  actionHandler:(void (^)(void))handler ;
@end

NS_ASSUME_NONNULL_END
