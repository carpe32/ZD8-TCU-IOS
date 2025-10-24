//
//  XTDebugControl.m
//  WLX
//
//  Created by SU on 2019/6/26.
//  Copyright © 2019 smn. All rights reserved.
//

#import "XTDebugControl.h"
#import <objc/runtime.h>
#import "UIImage+ImageBuffer.h"
#import "UIViewController+Test.h"
#import "UIView+MJExtension.h"
#define HEXCOLOR(hex) [UIColor colorWithRed:((float)((hex & 0xFF0000) >> 16)) / 255.0 green:((float)((hex & 0xFF00) >> 8)) / 255.0 blue:((float)(hex & 0xFF)) / 255.0 alpha:1]
#define kScreenWidth [UIScreen mainScreen].bounds.size.width
#define kScreenHeight [UIScreen mainScreen].bounds.size.height
@implementation XTDebugControl

int kCornerRadius = 12;
int kButtonCount = 3;

+ (void)show {
    
    NSString *fileName = @"NSLog.log";
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentDirectory = paths.firstObject;
    NSString *saveFilePath = [documentDirectory stringByAppendingPathComponent:fileName];

    NSFileManager * fm = [NSFileManager defaultManager];
    [fm removeItemAtPath:saveFilePath error:nil];
    
    XTDebugControl *view = [[XTDebugControl alloc] initWithFrame:CGRectMake(0, 0, 100, kButtonCount * (30 + 10) + 10)];
    view.backgroundColor = HEXCOLOR(0xf9f9f9);
    
    NSArray *titles = @[@"记录日志", @"停止记录", @"分享日志"];
    
    for (int i = 0; i < kButtonCount; i++) {
        CGFloat Y = 10 + 40 * i;
        UIButton *btn = [[UIButton alloc] initWithFrame:CGRectMake(10, Y, 80, 30)];
        btn.tag = 1000 + i;
        btn.backgroundColor = HEXCOLOR(0xfcfcfc);
        btn.layer.cornerRadius = 6;
        btn.layer.masksToBounds = YES;
        btn.layer.borderWidth = 1.;
        btn.layer.borderColor = [UIColor lightGrayColor].CGColor;
        [btn addTarget:view action:@selector(action:) forControlEvents:UIControlEventTouchUpInside];
        [btn setTitleColor:[UIColor darkGrayColor] forState:UIControlStateNormal];
        [btn.titleLabel setFont:[UIFont systemFontOfSize:17]];
        [btn setBackgroundImage:[UIImage imageWithColor:HEXCOLOR(0xc8dafd)] forState:UIControlStateSelected];
        [btn setTitleColor:[UIColor whiteColor] forState:UIControlStateSelected];
        NSString *title = titles[i];
        [btn setTitle:title forState:UIControlStateNormal];
        [view addSubview:btn];
    }
    UIWindow * window;
    if([[UIDevice currentDevice].systemVersion floatValue] >= 13.0){
            NSSet<UIWindowScene *> *scenes =  [[UIApplication sharedApplication] connectedScenes];
            
            UIWindowScene * scene = [scenes allObjects].firstObject;
            window = scene.windows.firstObject;
    }else{
    
        window = [UIApplication sharedApplication].keyWindow;
    
    }
    
    [window addSubview:view];
    
    UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc] initWithTarget:view action:@selector(panGestureAction:)];
    [view addGestureRecognizer:pan];
    view.userInteractionEnabled = YES;
}

- (void)action:(UIButton *)sender {
    
    for (UIButton *btn in self.subviews) {
        if (![btn isKindOfClass:[UIButton class]]) continue;
        btn.selected = NO;
    }
    sender.selected = YES;
    
    if (sender.tag == 1000) {
        [self redirectLog];
    }else if (sender.tag == 1001) {
        [self stopRecord];
    }else if (sender.tag == 1002) {
        [self shareLog];
    }
}

- (void)redirectLog {
    
    NSString *filePath = [self logFilePath];
//    if (filePath) {
//        [[NSFileManager defaultManager] removeItemAtPath:filePath error:nil];
//    }
//    NSDate *currentDate = [NSDate date];
//    NSDateFormatter *dateformatter = [[NSDateFormatter alloc] init];
//    [dateformatter setDateFormat:@"_MMdd_HHmmss"];
//    NSString *formattedDate = [dateformatter stringFromDate:currentDate];
//
//    NSString *docPath = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)[0];
//    NSString *fileName = [NSString stringWithFormat:@"xt%@.log", formattedDate];
//    NSString *logFilePath = [docPath stringByAppendingPathComponent:fileName];
    
    NSString * logFilePath = filePath;
    
    freopen([logFilePath cStringUsingEncoding:NSUTF8StringEncoding], "a+", stdout);
    freopen([logFilePath cStringUsingEncoding:NSUTF8StringEncoding], "a+", stderr);
}

- (void)stopRecord {
    freopen("/dev/null", "a+", stdout);
    freopen("/dev/null", "a+", stderr);
}

- (NSString *)logFilePath {
    
//    NSFileManager *fileManager = [NSFileManager defaultManager];
//    NSString *logPath = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)[0];
//    NSArray *fileList = [[NSArray alloc] initWithArray:[fileManager contentsOfDirectoryAtPath:logPath error:nil]];
//    for (NSString *fileName in fileList) {
//        if (fileName.length < 3 || ![[fileName substringWithRange:NSMakeRange(0, 3)] isEqualToString:@"xt_"]) {
//            continue;
//        }
//        return [logPath stringByAppendingPathComponent:fileName];
//    }
//    return nil;
    
    NSString *fileName = @"NSLog.log";
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentDirectory = paths.firstObject;
    NSString *saveFilePath = [documentDirectory stringByAppendingPathComponent:fileName];
//
////    NSString * str = [NSString stringWithContentsOfFile:saveFilePath encoding:NSUTF8StringEncoding error:nil];
//    return saveFilePath;
    return [documentDirectory stringByAppendingPathComponent:@"Movie/04-08-2023 15:56.txt"];
//
//    NSString * path = [[NSUserDefaults standardUserDefaults] objectForKey:@"path"];
//    return path;
//    return saveFilePath;
    
//    NSString *documentDirectory = paths.firstObject;
//    saveFilePath = [documentDirectory stringByAppendingPathComponent:fileName];
//    NSString * moviepath = [documentDirectory stringByAppendingPathComponent:@"Movie"];
//    NSFileManager * fm = [NSFileManager defaultManager];
//    NSArray<NSString *> * files = [fm contentsOfDirectoryAtPath:moviepath error:nil];
//    NSLog(@"files : %@",files);
//    NSString * txtpath = [moviepath stringByAppendingPathComponent:@"29-05-2023 15:55_origin_0.mp4t"];
////    return txtpath;
//    return txtpath;
}

- (void)shareLog {
    
    NSString *filePath = [self logFilePath];
    if (filePath == nil) return;
    
    NSArray *urls = @[[NSURL fileURLWithPath:filePath]];    
    UIActivityViewController *activityVC = [[UIActivityViewController alloc] initWithActivityItems:urls applicationActivities:nil];
    NSArray *cludeActivitys = @[UIActivityTypeMail];
    activityVC.excludedActivityTypes = cludeActivitys;
    if ([activityVC respondsToSelector:@selector(popoverPresentationController)]) {        activityVC.popoverPresentationController.sourceView = [UIApplication sharedApplication].keyWindow;
        activityVC.popoverPresentationController.sourceRect = CGRectMake(0, kScreenHeight, kScreenWidth, kScreenHeight);
    }
    [[UIViewController current] presentViewController:activityVC animated:YES completion:nil];
}

- (void)panGestureAction:(UIPanGestureRecognizer *)pan {
    
    switch (pan.state) {
        case UIGestureRecognizerStateBegan:
        case UIGestureRecognizerStateChanged: {
            [UIView animateWithDuration:0.1 animations:^{
                self.mj_x += [pan translationInView:self.superview].x;
                self.mj_y += [pan translationInView:self.superview].y;
            }];
            [pan setTranslation:CGPointZero inView:self.superview];
            break;
        }
        case UIGestureRecognizerStateEnded:
        case UIGestureRecognizerStateFailed:
        case UIGestureRecognizerStateCancelled: {
            [self animateWithActions:^{
                if (self.mj_x + 0.5 * self.mj_w < 0.5 * kScreenWidth) {
                    self.mj_x = 0;
                }else {
                    self.mj_x = kScreenWidth - self.mj_w;
                }
            }];
            break;
        }
        default:
            break;
    }
}

- (void)animateWithActions:(void (^)(void))actions {
    [UIView beginAnimations:nil context:nil];
    [UIView setAnimationCurve:7];
    [UIView setAnimationDelegate:self];
    if (actions) {
        actions();
    }
    [UIView commitAnimations];
}


@end
