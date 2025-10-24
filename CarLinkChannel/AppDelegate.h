//
//  AppDelegate.h
//  CarLinkChannel
//
//  Created by job on 2023/3/22.
//

#import <UIKit/UIKit.h>

@interface AppDelegate : UIResponder <UIApplicationDelegate>
@property(nonatomic) int state;         // 0.竖屏    1. 横屏
@property (strong, nonatomic) DDFileLogger *fileLogger;
@end

