//
//  PackageDownPresenter.m
//  CarLinkChannel
//
//  Created by job on 2023/3/30.
//

#import "PackageDownPresenter.h"
#import "SSZipArchive.h"
#import "NSData+Category.h"
#import "NetworkInterface.h"
#import <pthread.h>

@interface PackageDownPresenter()
{
    PackageDownloadInteractive * interactive;
    NSString * binFilePath;
    NSString * binPath;
    NSString * binUrl;
    NSArray * items;
    BOOL isExists;
    UIView * touchView;             // 开始下载时至下载完成或者下载失败期间遮挡在屏幕上，以免重复下载
}

@end
@implementation PackageDownPresenter

-(PackageDownloadInteractive*)getInteractive {
    if(interactive == nil){
        interactive = [PackageDownloadInteractive getInteractive];
    }
    return interactive;
}
-(void)startFileHandler {
    if(interactive == nil){
        [self getInteractive];
    }
 
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(fileStarDownloadNotify:) name:start_package_notify_name object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(fileDownProgressNotify:) name:down_package_notify_name object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(fileDonProgressNotify:) name:done_package_notify_name object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(failDownPackageFailNotify:) name:fail_down_package_notify_name object:nil];
    isExists = [self checkFileConfig];
}
#pragma mark 开始处理文件
-(Boolean)checkFileConfig {
   // NSString * txtPath = [[NSBundle mainBundle] pathForResource:@"list" ofType:@"txt"];
    
    NSString * configPath = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)[0];
    configPath = [configPath stringByAppendingFormat:@"/Package/BinFile"];
    NSFileManager * fm = [NSFileManager defaultManager];
    if(![fm fileExistsAtPath:configPath]){
        [fm createDirectoryAtPath:configPath withIntermediateDirectories:YES attributes:nil error:nil];
    }
        // 如果不存在，这里就该下载了        // 先创建一层vin目录
        binFilePath = [configPath stringByAppendingFormat:@"/%@",self.vinString];
        if(![fm fileExistsAtPath:binFilePath]){
            [fm createDirectoryAtPath:binFilePath withIntermediateDirectories:YES attributes:nil error:nil];
        }
    
        binFilePath = [[binFilePath stringByAppendingFormat:@"/%@",self.binaryName] stringByReplacingOccurrencesOfString:@".bin" withString:@""];
        binPath = [configPath stringByAppendingFormat:@"/%@",self.binaryName];
    
        binUrl = [NSString stringWithFormat:@"%@/%@",FILE_HOST,self.binaryName];
        if(![fm fileExistsAtPath:binFilePath]){

            return false;
        // 如果已经下载过了
        }else{
            self->items = [fm contentsOfDirectoryAtPath:binFilePath error:nil];
            self->items = [self->items sortedArrayUsingComparator:^(id obj1,id obj2){
                NSString * value1 = (NSString *)obj1;
                NSString * value2 = (NSString *)obj2;
                
                return [value1 compare:value2];
            }];
            return true;
            
        }
        
//    }
    return false;
}
-(Boolean)getFileExists{
    return isExists;
}

-(void)loadBinFile:(NSString *)fileName {
    // 需要先判断是否有更新
    NetworkInterface * interface = [NetworkInterface getInterface];
    NSLog(@"现在下载文件 : %@",self->binUrl);
    self->binUrl = [NSString stringWithFormat:@"%@/%@",FILE_HOST,fileName];
    [self->interactive loadFileWithUrl:self->binUrl];
    
}

-(NSInteger)getRowCount {
    return items.count;
}
-(NSString *)getRowString:(NSIndexPath *)indexPath{
    if(items.count > indexPath.row){
        return items[indexPath.row];
    }
    return nil;
}
-(NSString *)getTunePath:(NSIndexPath *)indexPath {
    
    NSString * configPath = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)[0];
    configPath = [configPath stringByAppendingFormat:@"/Package"];
    
    if(items.count > indexPath.row){
        return [NSString stringWithFormat:@"%@/%@",binFilePath,items[indexPath.row]];
    }
    return nil;
}
-(void)fileStarDownloadNotify:(NSNotification *)notify {
    NSString *Binname = notify.userInfo[@"name"];
    [self loadBinFile:Binname];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        if(self->touchView == nil){
            self->touchView = [[UIView alloc] initWithFrame:[UIScreen mainScreen].bounds];
        }
        if([[UIDevice currentDevice].systemVersion floatValue] >= 15.0){
            NSSet<UIWindowScene *> *scenes =  [[UIApplication sharedApplication] connectedScenes];
            
           UIWindowScene * scene = [scenes allObjects].firstObject;
           [scene.keyWindow addSubview:self->touchView];
        }else{
            UIWindow * window = [UIApplication sharedApplication].keyWindow;
            [window addSubview:self->touchView];
        }

    });
}

#pragma mark 文件下载进度通知和下载完成的通知
-(void)fileDownProgressNotify:(NSNotification *)notify {
    NSDictionary * dict = notify.userInfo;
    double progress = [dict[@"progress"] doubleValue];
    dispatch_async(dispatch_get_main_queue(), ^{
            self.downloadView.progressView.hidden = false;
            self.downloadView.progressView.progress = progress;
    });
    
}



-(void)fileDonProgressNotify:(NSNotification *)notify {
    NSLog(@"收到下载完成通知");
    NSDictionary * dict = notify.userInfo;
    NSString * url = dict[@"url"];
    NSFileManager * fm = [NSFileManager defaultManager];
    NSLog(@"self.binFilePath: %@",self->binFilePath);
    // 需要先删除目录下面的文件
    if([fm fileExistsAtPath:self->binFilePath]){
        NSError * error;
        [fm removeItemAtPath:self->binFilePath error:&error];
        NSLog(@"self.binFilepath 存在, 现在删除: %@",error);
    }
    NSData * fileData = [NSData dataWithContentsOfFile:url];
    NSError * error;
    NSString *  zipPath = [binFilePath stringByAppendingString:@".zip"];
    [fm copyItemAtPath:url toPath:zipPath error:&error];
    [SSZipArchive unzipFileAtPath:zipPath toDestination:binFilePath];
    [fm removeItemAtPath:zipPath error:nil];

    NSString *StageDirPath1 = [self->binFilePath stringByAppendingPathComponent:@"xHP Tuning style Stage 1"];
    NSString *StageDirPath2 = [self->binFilePath stringByAppendingPathComponent:@"xHP Tuning style Stage 2"];
    NSString *StageDirPath3 = [self->binFilePath stringByAppendingPathComponent:@"xHP Tuning style Stage 3"];

    NSArray *contents = [fm contentsOfDirectoryAtPath:self->binFilePath error:&error];
    if (error) {
        NSLog(@"读取目录失败: %@", error.localizedDescription);
    } else {
        NSLog(@"%@ 目录下的文件/子目录:", self->binFilePath);
        for (NSString *item in contents) {
            NSString *fullItemPath = [self->binFilePath stringByAppendingPathComponent:item];

           BOOL isDir = NO;
           if ([fm fileExistsAtPath:fullItemPath isDirectory:&isDir] && isDir) {
               // 检查目录名是否包含指定字符串
               if ([item isEqual:@"Stage 1"]) {
                   NSLog(@"找到目录: %@", item);
                   // 复制目录并重命名
                   [fm copyItemAtPath:fullItemPath toPath:StageDirPath1 error:&error];
                   NSString *stage1ShowPath = [StageDirPath1 stringByAppendingPathComponent:@"show.txt"];
                   [@"xHP Tuning style Stage 1" writeToFile:stage1ShowPath
                                               atomically:YES
                                                 encoding:NSUTF8StringEncoding
                                                    error:&error];

               }
               else if ([item isEqual:@"Stage 2"]) {
                   NSLog(@"找到目录: %@", item);
                   // 复制目录并重命名
                   [fm copyItemAtPath:fullItemPath toPath:StageDirPath2 error:&error];
                   NSString *stage2ShowPath = [StageDirPath2 stringByAppendingPathComponent:@"show.txt"];
                   [@"xHP Tuning style Stage 2" writeToFile:stage2ShowPath
                                               atomically:YES
                                                 encoding:NSUTF8StringEncoding
                                                    error:&error];
               }
               else if ([item isEqual:@"Stage 3"]) {
                   NSLog(@"找到目录: %@", item);
                   // 复制目录并重命名
                   [fm copyItemAtPath:fullItemPath toPath:StageDirPath3 error:&error];
                   NSString *stage3ShowPath = [StageDirPath3 stringByAppendingPathComponent:@"show.txt"];
                   [@"xHP Tuning style Stage 3" writeToFile:stage3ShowPath
                                               atomically:YES
                                                 encoding:NSUTF8StringEncoding
                                                    error:&error];
               }
           }
        }
    }
    
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH,0), ^{
        UploadManager *uploadManager = [UploadManager sharedInstance];
        [uploadManager SaveAndUploadDownloadFileName:[[self->binFilePath lastPathComponent] stringByAppendingString:@".bin"]];
    });

    dispatch_async(dispatch_get_main_queue(), ^{
        
        [UIView animateWithDuration:0.25 animations:^{
            self.downloadView.frame = CGRectMake(0, [UIScreen mainScreen].bounds.size.height, [UIScreen mainScreen].bounds.size.width, self.downloadView.frame.size.height);
            
                } completion:^(bool finish){
                   self->isExists = [self checkFileConfig];
                    NSLog(@"self.item.count : %ld",self->items.count);
                    [self.tableView reloadData];
                    [self->touchView removeFromSuperview];
                }];
        
    });
}
-(void)failDownPackageFailNotify:(NSNotification *)notify {
    NSLog(@"收到下载失败通知");
    dispatch_async(dispatch_get_main_queue(), ^{
        
        [UIView animateWithDuration:0.25 animations:^{
            self.downloadView.frame = CGRectMake(0, [UIScreen mainScreen].bounds.size.height, [UIScreen mainScreen].bounds.size.width, self.downloadView.frame.size.height);
            
                } completion:^(bool finish){
                   self->isExists = [self checkFileConfig];
                    [self.tableView reloadData];
                    [self->touchView removeFromSuperview];
                }];
        
    });
}
@end
