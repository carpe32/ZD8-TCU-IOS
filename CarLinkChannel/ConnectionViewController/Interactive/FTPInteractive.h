//
//  FTPInteractive.h
//  CarLinkChannel
//
//  Created by job on 2023/5/12.
//

#import <Foundation/Foundation.h>
#import "FTPManager.h"

NS_ASSUME_NONNULL_BEGIN

@interface FTPInteractive : NSObject
+(instancetype)loadFtpIneractive;
-(BOOL)uploadFileWithPath:(NSString *)filePath;
-(BOOL)downloadFileWithFileName:(NSString *)fileName localPath:(NSString *)localPath;
-(NSArray *)getContents;
@end

NS_ASSUME_NONNULL_END
