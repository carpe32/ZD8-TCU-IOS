//
//  FTPInteractive.m
//  CarLinkChannel
//
//  Created by job on 2023/5/12.
//

#import "FTPInteractive.h"
@interface FTPInteractive()
{
    FTPManager* ftpManager;
    FMServer * vinftpServer;
}
@end

@implementation FTPInteractive
+(instancetype)loadFtpIneractive{
    static FTPInteractive * interactive = nil;
    if(interactive == nil){
        interactive = [[FTPInteractive alloc] init];
        interactive->ftpManager = [[FTPManager alloc] init];
        NSString * vinPath = [FTP_HOST stringByAppendingString:@"/VIN"];
        interactive->vinftpServer = [FMServer serverWithDestination:vinPath username:FTP_USER_NAME password:FTP_PASSWORD];
    }
    return interactive;
}
-(BOOL)uploadFileWithPath:(NSString *)filePath{
    BOOL isSuccess = false;
    NSLog(@"上传前");
    isSuccess = [ftpManager uploadFile:[NSURL fileURLWithPath:filePath] toServer:vinftpServer];
    NSLog(@"上传文件结果: %d",isSuccess);
    return isSuccess;
}
-(BOOL)downloadFileWithFileName:(NSString *)fileName localPath:(NSString *)localPath{
    BOOL isSuccess = false;
    isSuccess = [ftpManager downloadFile:fileName toDirectory:[NSURL fileURLWithPath:localPath] fromServer:vinftpServer];
    return isSuccess;
}
-(NSArray *)getContents{
    NSArray * contents = [ftpManager contentsOfServer:vinftpServer];
    return contents;
}
@end
