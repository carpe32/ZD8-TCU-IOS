//
//  UIViewController+Test.m
//  SealTalk
//
//  Created by SU-Work on 2018/10/25.
//  Copyright © 2018 RongCloud. All rights reserved.
//

#import "UIViewController+Test.h"
#import <objc/runtime.h>

@implementation UIViewController (Test)

+ (UIViewController *)current {
//    UIViewController *rootViewController = [[UIApplication sharedApplication].delegate.window rootViewController];
    UIWindow * window;
    if([[UIDevice currentDevice].systemVersion floatValue] >= 15.0){
//        if (@available(iOS 13.0, *)) {
            NSSet<UIWindowScene *> *scenes =  [[UIApplication sharedApplication] connectedScenes];
            
            UIWindowScene * scene = [scenes allObjects].firstObject;
        window = scene.keyWindow;
//        } else {
//            // Fallback on earlier versions
//        }

    }else{
    
        window = [UIApplication sharedApplication].keyWindow;
    
    }
    UIViewController *rootViewController = window.rootViewController;
    return [self getVisibleViewController:rootViewController];
//    return rootViewController;
}

+ (UIViewController *)getVisibleViewController:(UIViewController *)vc {
    if ([vc isKindOfClass:[UINavigationController class]]) {
        return [self getVisibleViewController:[((UINavigationController *)vc) visibleViewController]];
    }else if ([vc isKindOfClass:[UITabBarController class]]) {
        return [self getVisibleViewController:[((UITabBarController *)vc) selectedViewController]];
    }else {
        if (vc.presentedViewController) {
            return [self getVisibleViewController:vc.presentedViewController];
        }else {
            return vc;
        }
    }
}

//
//
//+ (void)load {
//#ifdef DEBUG
//    Method origin = class_getInstanceMethod([self class], @selector(viewWillAppear:));
//    Method other = class_getInstanceMethod([self class], @selector(su_viewWillAppear:));
//    method_exchangeImplementations(origin, other);
//#endif
//}
//
//- (void)su_viewWillAppear:(BOOL)animated {
//    NSLog(@"sudebug 当前控制器：%@", NSStringFromClass([self class]));
//    [self su_viewWillAppear:animated];
//}
//
//
//@end
//
//
//@interface UIControl (Test) @end @implementation UIControl (Test)
//
//+ (void)load {
//#ifdef DEBUG
//    Method origin = class_getInstanceMethod([self class], @selector(sendAction:to:forEvent:));
//    Method other = class_getInstanceMethod([self class], @selector(su_sendAction:to:forEvent:));
//    method_exchangeImplementations(origin, other);
//#endif
//}
//
//- (void)su_sendAction:(SEL)action to:(id)target forEvent:(UIEvent *)event {
//
//    NSLog(@"\nsudebug 点击了 %@\n", NSStringFromClass([self class]));
//    NSLog(@"sudebug 调用方法: %@\n", NSStringFromSelector(action));
//    NSLog(@"sudebug 响应者: %@\n", target);
//
//    [self su_sendAction:action to:target forEvent:event];
//
//}
//
//



@end


