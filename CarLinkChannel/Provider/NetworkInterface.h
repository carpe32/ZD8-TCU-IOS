//
//  NetworkInterface.h
//  CarLinkChannel
//
//  Created by job on 2023/3/29.
//

#import <Foundation/Foundation.h>
#import "HttpClient.h"

NS_ASSUME_NONNULL_BEGIN

@interface NetworkInterface : NSObject


+ (NetworkInterface*)getInterface;
-(void)checkVin:(NSString *)vin isValid:(void(^)(Boolean result))resultBlock withError:(void(^)(NSError* error))errorBlock;
-(void)ValidWithVin:(NSString *)vin Code:(NSString *)code returnBlock:(void(^)(Boolean result))resultBlock withError:(void(^)(NSError* error))errorBlock;
-(void)getanquansuanfabtld:(NSString *)btldValue parmarsvar3:(NSString *)var3 doneBlock:(void(^)(NSString *anquan))resultBlock withError:(void(^)(NSError *error))errorBlock;
// 获取list规则文件
-(void)getListFileDoneBlock:(void(^)(NSString *liststring))resultBlock withError:(void(^)(NSError *error))errorBlock;

-(void)getUpdateBinFile:(NSString *)vin requestBlock:(void(^)(NSString* result))resultBlock withError:(void(^)(NSError * error))errorBlock;
-(void)RegisterFileNameFormVin:(NSString *)Vin DownloadFileName:(NSString *)FileName;
@end

NS_ASSUME_NONNULL_END
