//
//  EcuInstallView.m
//  CarLinkChannel
//
//  Created by job on 2023/3/30.
//

#import "EcuInstallView.h"
#import "UIImageView+Tool.h"

@interface EcuInstallView()
{
    NSInteger totalCount;             // 当前安装的包的总数
    NSInteger performanceCount;        //已完成的计数
    NSInteger Percent;
    int installCount;           // 当前已经安装的包的数量
    int fileCount;              // 总共需要读取的文件数量
    int fileInstallCount;       // 当前已经读取安装的文件数量
}

@end

@implementation EcuInstallView

-(void)initView {
    [self.ballView initWithFrame:CGRectMake(0, 0, 125, 27)];
   // [self.ballView setFrame:CGRectMake(0, 0, 125, 27)];
    [self.ballView setAnimatorDuration:1.5f];
    [self.ballView setAnimatorDistance:30];
    [self.ballView startAnimator];
    [self.progresslabel setText:@""];
    
//  BallRotationProgressBar * v =  [self.ballView initWithFrame:CGRectMake(0, 0, 125, 27)];
//  [v setAnimatorDuration:1.5f];
//  [v setAnimatorDistance:30];
//  [v startAnimator];
    
}
-(void)initViewState {
    [self.progresslabel setText:@"Flash Initialize, Please Wait"];
    [self.DataLabel setText:@""];
}
-(void)beginLogoAnimation {
    
    NSString * imagepath = [[NSBundle mainBundle] pathForResource:@"zd8-5" ofType:@"gif"];
    NSURL * imageUrl = [NSURL fileURLWithPath:imagepath];
    
    [self.LogoImageView yh_setImage:imageUrl];
    
}
-(void)setNormalDescription {
    self.descriptionLabel.text = @"Please do not turn off the app,do not answer not make calls,keep the network stable,do not turn off your phone,and the vehicle remains powered on.";
}
-(void)setCafdDescription {
    self.descriptionLabel.text = @" CAFD Restore Process\r\n Please waiting 10 seconds...";
}
-(void)setPackageDataCount:(int)count{
    self->fileCount = count;
}

-(void)setPackageDataInstallCount:(int)count{
    self->fileInstallCount = count;
    self.DataLabel.text = [NSString stringWithFormat:@"Data (%d/%d)",self->fileInstallCount,self->fileCount];
}

-(void)setPackageTotalMount:(NSInteger)count{
    performanceCount = 0;
    self->totalCount = count;
  //  self.progresslabel.text = [NSString stringWithFormat:@"Completing Section %d/%d.",count,totalCount];
}

-(void)setCurrentPackageInstallCount:(int)count{
    installCount = count;
//    self.progresslabel.text = [NSString stringWithFormat:@"Completing Section %d/%d.",count,totalCount];
}

-(void)setEcuFileDoneInstall {
    //self.DataLabel.text = @"";
    self.progresslabel.text = @"Finalize ECU process";
}

-(void)setCurrentPackageInstallCount{
    performanceCount++;
    [self UpdateLabelhandle:performanceCount];
}

-(void)UpdateLabelhandle:(NSInteger)NowCount{    // 计算百分比
    self->Percent = (NowCount * (NSInteger)100) / self->totalCount;
    self.progresslabel.text = [NSString stringWithFormat:@"%ld%% Completed.", (long)self->Percent]; // 使用%d代表整数，%%代表百分号
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

@end
