//
//  SofawareDownloadView.m
//  CarLinkChannel
//
//  Created by job on 2023/3/29.
//

#import "SoftwareDownloadView.h"
static const DDLogLevel ddLogLevel = DDLogLevelVerbose;
@implementation SoftwareDownloadView

-(void)initView {
    NSString * desc = @"Whether to download/update the program will take a few minutes for you.\n\nPlease keep the network unblocked and do not close the app.";
    self.descTextView.text = desc;
}
- (IBAction)okButtonTarget:(id)sender {
    NSLog(@"点击了下载按钮");
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH,0), ^{
        UploadManager *uploadManager = [UploadManager sharedInstance];
        [uploadManager UploadMidFromServer];
        MidSetBin *SetState = [uploadManager CheckWhetherSetBIN];
        if(SetState.status == ResponseXmlMidNeedSetFile)
        {
            self.BinName = SetState.BINName;
        }
        [uploadManager DownloadFlashFile:self.BinName];
        DDLogInfo(@"Download file : %@",self.BinName);
        NSDictionary *BinfileMsg = @{@"name":self.BinName};
        [[NSNotificationCenter defaultCenter] postNotificationName:start_package_notify_name object:nil userInfo:BinfileMsg];
    });
}
@end
