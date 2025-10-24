//
//  PackageDownloadInteractive.m
//  CarLinkChannel
//
//  Created by job on 2023/3/30.
//

#import "PackageDownloadInteractive.h"

@interface PackageDownloadInteractive()
{
    NSString * binUrl;
}

@end

@implementation PackageDownloadInteractive

+(PackageDownloadInteractive*)getInteractive {
    PackageDownloadInteractive * interactive = [[PackageDownloadInteractive alloc] init];
    return interactive;
}

-(void)loadFileWithUrl:(NSString * )fileUrl{
    binUrl = fileUrl;
    NSURLRequest * request = [NSURLRequest requestWithURL:[NSURL URLWithString:fileUrl]];
    NSURLSessionDownloadTask * downTask = [[NSURLSession sharedSession] downloadTaskWithRequest:request completionHandler:^(NSURL * url,NSURLResponse * reponse,NSError * error){
        if(!error){
           
            NSString * path = url.path;
            NSFileManager * fm = [NSFileManager defaultManager];
            if([fm fileExistsAtPath:path]){
                NSLog(@"文件存在");
            }
            if([fm fileExistsAtPath:url.absoluteString]){
                NSLog(@"url文件存在");
            }
            NSString * tempPath = NSTemporaryDirectory();
            NSArray * paths = [fm subpathsAtPath:tempPath];
            NSData * data = [fm contentsAtPath:path];
            NSData * fileData = [NSData dataWithContentsOfFile:url];
            NSLog(@"现在 %@ 文件下载完成 ,url: %@ , path: %@ error: %@ filesize: %ld",self->binUrl,url,url,error,fileData.length);
            [[NSNotificationCenter defaultCenter] postNotificationName:done_package_notify_name object:nil userInfo:@{@"url":path}];
        }else{
            NSLog(@"现在 %@ 文件下载失败,url: %@ , error: %@",self->binUrl,url,error);
            [[NSNotificationCenter defaultCenter] postNotificationName:fail_down_package_notify_name object:nil userInfo:@{@"url":@""}];
        }
    }];
    [downTask addObserver:self forKeyPath:@"progress.fractionCompleted" options:NSKeyValueObservingOptionNew context:(__bridge  void * _Nullable)(binUrl)];
    [downTask resume];

}
-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context{
   // NSString * fileUrl = (NSString *)CFBridgingRelease(context);
    NSNumber * num = change[@"new"];
//    double complete = [num doubleValue];
    [[NSNotificationCenter defaultCenter] postNotificationName:down_package_notify_name object:nil userInfo:@{@"progress":num,@"url":binUrl}];
}

@end
