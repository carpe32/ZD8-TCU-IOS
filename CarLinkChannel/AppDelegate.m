//
//  AppDelegate.m
//  CarLinkChannel
//
//  Created by job on 2023/3/22.
//

#import "AppDelegate.h"
#import "UploadManager.h"
#import "CustomLogFormatter.h"
#import "SSZipArchive.h"
#import "TCUAPIService.h"
#import "TCUAPIConfig.h"
#import "TCUAlamofireManager.h"  // ✅ 导入纯OC版本
#import "TCUCFNetworkManager.h"
@interface AppDelegate ()

@end

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    
    // 日志配置
    self.fileLogger = [[DDFileLogger alloc] init];
    self.fileLogger.rollingFrequency = 60 * 60 * 24; // 每 24 小时创建一个新日志文件
    self.fileLogger.logFileManager.maximumNumberOfLogFiles = 3;
    CustomLogFormatter *formatter = [[CustomLogFormatter alloc] init];
    [self.fileLogger setLogFormatter:formatter];
    [DDLog addLogger:self.fileLogger];
    
    
     // 1. 配置SSL
     TCUAPIService *service = [TCUAPIService sharedService];
     BOOL success = [service setupSSLWithCertName:@"CLIENT-IOS-001"
                                         password:@"Q1w2e3r4@#$"];
     
     if (!success) {
         NSLog(@"❌ SSL配置失败");
         return YES;
     }
     
     // 2. 测试连接
//     [service testConnection];
    
    return YES;
}
- (void)applicationWillTerminate:(UIApplication *)application {
    // 使用之前创建的 fileLogger
    NSArray<NSString *> *logFilePaths = [self.fileLogger.logFileManager sortedLogFilePaths];

    // 使用后台任务确保上传能完成
    __block UIBackgroundTaskIdentifier bgTask = [application beginBackgroundTaskWithExpirationHandler:^{
        [application endBackgroundTask:bgTask];
        bgTask = UIBackgroundTaskInvalid;
    }];

    // 上传日志文件
    [self uploadLogFiles:logFilePaths completion:^{
        [application endBackgroundTask:bgTask];
        bgTask = UIBackgroundTaskInvalid;
    }];
}

- (void)uploadLogFiles:(NSArray<NSString *> *)logFilePaths completion:(void (^)(void))completion {
    if (logFilePaths.count > 0) {
        NSString *zipFilePath = [NSTemporaryDirectory() stringByAppendingPathComponent:@"logs.zip"];
        
        // 压缩日志文件
        [SSZipArchive createZipFileAtPath:zipFilePath withFilesAtPaths:logFilePaths];
        UploadManager *uploadManager = [UploadManager sharedInstance];
        [uploadManager uploadLogFile:zipFilePath];
    }
    
    // 上传完成后调用 completion 回调
    if (completion) {
        completion();
    }
}

#pragma mark - UISceneSession lifecycle


- (UISceneConfiguration *)application:(UIApplication *)application configurationForConnectingSceneSession:(UISceneSession *)connectingSceneSession options:(UISceneConnectionOptions *)options {
    // Called when a new scene session is being created.
    // Use this method to select a configuration to create the new scene with.
    return [[UISceneConfiguration alloc] initWithName:@"Default Configuration" sessionRole:connectingSceneSession.role];
}


- (void)application:(UIApplication *)application didDiscardSceneSessions:(NSSet<UISceneSession *> *)sceneSessions {
    // Called when the user discards a scene session.
    // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
    // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
}
- (UIInterfaceOrientationMask)application:(UIApplication *)application supportedInterfaceOrientationsForWindow:(nullable UIWindow *)window {

 //   NSLog(@"self.state: %d",self.state);
    
    if(self.state == 100)return UIInterfaceOrientationMaskLandscapeRight;

    return UIInterfaceOrientationMaskPortrait;
}

@end
