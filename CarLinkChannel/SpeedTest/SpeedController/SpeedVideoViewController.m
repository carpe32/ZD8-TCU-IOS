//
//  SpeedVideoViewController.m
//  CarLinkChannel
//
//  Created by job on 2023/4/25.
//

#import "SpeedVideoViewController.h"
#import "SpeedTestInteractive.h"
#import "AppDelegate.h"
#import "NavigationView.h"
#import "XTDebugControl.h"
#import "TcpSpeedTestHandler.h"
#import "ReplayKitManager.h"

@interface SpeedVideoViewController ()<NavigationViewDelegate>
{
    SpeedTestInteractive * interactive;
    TcpSpeedTestHandler * handler;
    long micro_second;
    dispatch_source_t animation_t_internet;
    CGFloat turbineWidth;
    CGFloat rpmWidth;
    CGFloat throttleWidth;
    NSString * timeString;
    BOOL iscounttimer;

    float ThrottleValue;
    float turboBoostValue;
    uint16_t engineRPMValue;
    uint8_t currentGear;
    uint8_t speedValue;
    
    BOOL isReading;  // 标记持续读取状态
    dispatch_queue_t readingQueue;  // 用于读取的队列
    dispatch_source_t Readtimer;  // 定时器
    BOOL SeroState;
}
@property(nonatomic,strong) UILabel * bmwLabel;
@property(nonatomic,strong) UILabel * ecuLabel;
@property(nonatomic,strong) UILabel * tcuLabel;
@property(nonatomic,strong) UILabel * gearLabel;
@property(nonatomic,strong) UILabel * speedLabel;
@property(nonatomic,strong) UILabel * turbineLabel;
@property(nonatomic,strong) UILabel * speed2Label;
@property(nonatomic,strong) UILabel * throttleLabel;
@property(nonatomic,strong) UILabel * timeLabel;
@property(nonatomic,strong) UIView *  turbineView;
@property(nonatomic,strong) UIView * rpmView;
@property(nonatomic,strong) UIView * throttleView;
@property(nonatomic,strong) UILabel * readyLabel;
@property(nonatomic,strong) UILabel * recoredTimeLabel;
@property(nonatomic,strong) UILabel * faileLabel;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *turbinetraillayout;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *rpmtaillayout;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *throttlelayout;
@property (nonatomic, strong) ReplayKitManager *replayKitManager;

@end

@implementation SpeedVideoViewController
-(void)addNavigationView {
    
    [self.navigationController setNavigationBarHidden:YES];
    NavigationView *  naviView = (NavigationView*)[[NSBundle mainBundle] loadNibNamed:@"NavigationView" owner:self options:nil][0];
    naviView.frame = CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.height, 80);
    naviView.delegate = self;
    naviView.titLabel.text = @"";
    naviView.backgroundColor = [UIColor redColor];

    [self.view addSubview:naviView];

}

-(void)viewWillDisappear:(BOOL)animated{
    if(animation_t_internet){
        dispatch_source_cancel(animation_t_internet);
    }
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [self setOrientationLandscape];
}
- (void)viewDidLoad {
    [super viewDidLoad];

    //[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(recvSpeedData:) name:recv_tcp_speed_test_notify_name object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(recvSpeedTestPacket1:) name:recv_speed_test_package_1_notify_name object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(recvSpeedTestPacket2Sero1:) name:recv_speed_test_package_2_sero_1_notify_name object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(recvSpeedTestPacket2Sero2:) name:recv_speed_test_package_2_sero_2_notify_name object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(recvSpeedTestPacket3Sero2:) name:recv_speed_test_package_3_sero_2_notify_name object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(recvstartimerNotify:) name:recv_speed_time_start_notify_name object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(recvreadyNotify:) name:recv_speed_ready_notify_name object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(recvStopTimerNotify:) name:recv_speed_stop_timer_notify_name object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(testFaileNotify:) name:recv_speed_test_timeout_notify_name object:nil];
    // Do any additional setup after loading the view.
//    NSFileManager * fm = [NSFileManager defaultManager];
//    NSString * path = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)[0];
//    NSError * error;
//    NSArray<NSString *> * files = [fm contentsOfDirectoryAtPath:path error:&error];
//    NSLog(@"files: %@",files);
    
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[[UIImage imageNamed:@"escimg"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal] style:UIBarButtonItemStyleDone target:self action:@selector(didTapEscButton)];
    
    iscounttimer = NO;
    micro_second = 0;
    handler = [[TcpSpeedTestHandler alloc] init];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
    self->SeroState = [self->handler startSpeedTest];
        dispatch_async(dispatch_get_main_queue(), ^{
        [self startCapture];
        [self addTopView];
        [self addBottomView];

        [self startReadingData];
        });
    });
}
-(void)viewWillAppear:(BOOL)animated{
    [self setOrientationLandscapeRight];
}
-(void)viewDidDisappear:(BOOL)animated{
    if(self->interactive){
        [self->interactive destoryTimer];
    }
}

- (void)startReadingData {
    // 创建一个 GCD 定时器
    Readtimer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, readingQueue);
    
    // 设置定时器的触发时间和间隔：开始时间为 0 纳秒后，间隔为 10 毫秒
    dispatch_source_set_timer(Readtimer, DISPATCH_TIME_NOW, 10 * NSEC_PER_MSEC, 0);
    
    dispatch_source_set_event_handler(Readtimer, ^{
        
        NSDictionary *VehicleData = [self->handler ReadSpeedDataFromVehicle:self->SeroState];
        self->ThrottleValue =  [VehicleData[@"Throttle"] floatValue];
        self->turboBoostValue =  [VehicleData[@"turbo"] floatValue];
        self->engineRPMValue =  [VehicleData[@"rpm"] unsignedShortValue];
        self->currentGear =  [VehicleData[@"Gear"] unsignedCharValue];
        self->speedValue =  [VehicleData[@"Speed"] unsignedShortValue];
        int sero = [VehicleData[@"sero"] unsignedShortValue];
        BOOL isRecord = [[NSUserDefaults standardUserDefaults] boolForKey:@"isRecord"];
        NSLog(@"--------------> isRecord: %d",isRecord);

        if(isRecord == true){
            NSString * filename = [[NSUserDefaults standardUserDefaults] objectForKey:@"txtFilePath"];
            NSLog(@"txtFilename: %@",filename);
            NSFileHandle * fileHandler = [NSFileHandle fileHandleForWritingAtPath:filename];
            [fileHandler seekToEndOfFile];
            NSString * timeval = [NSString stringWithFormat:@"%.f",[NSDate date].timeIntervalSince1970 * 1000];
            // 如果是同一毫秒内，则只记录一次
            if(self->timeString && [self->timeString isEqualToString:timeval]){
                
            }else{
                //  38   个字符                wolun : 0-900
                //                      毫秒级时间戮: 油门 : 速度 ： 挡位 ： 涡轮 ： 转速
                //         NSString * itemString = @"[1685081935413:200:100:10:1400.4:9999]";
              //  NSLog(@"itemString.length: %ld",itemString.length);
                NSString * single = [NSString stringWithFormat:@"[%@:%06.1f:%03d:%02d:%06.1f:%04d]",timeval,self->ThrottleValue,self->speedValue,self->currentGear,self->turboBoostValue,self->engineRPMValue];
                NSLog(@"-------------> single: %@",single);
                NSData * singleData = [single dataUsingEncoding:NSUTF8StringEncoding];
                [fileHandler writeData:singleData];
                [fileHandler closeFile];
                self->timeString = timeval;
            }

        }
        
        int speed = self->speedValue;
        if(self->SeroState == 1){
            if ((speed > 1) && (speed <= 10))
            {
                speed += 1;
            }
            else if ((speed > 10) && (speed <= 20))
            {
                speed += 1;
            }
            else if ((speed > 20) && (speed <= 30))
            {
                speed += 2;
            }
            else if ((speed > 30) && (speed <= 40))
            {
                speed += 2;
            }
            else if ((speed > 40) && (speed <= 50))
            {
                speed += 2;
            }
            else if ((speed > 50) && (speed <= 60))
            {
                speed += 2;
            }
            else if ((speed > 60) && (speed <= 70))
            {
                speed += 4;
            }
            else if ((speed > 70) && (speed <= 80))
            {
                speed += 4;
            }
            else if ((speed > 80))
            {
                speed += 4;
            }
        }else{
            if ((speed > 1) && (speed <= 10))
            {
                speed += 1;
            }
            else if ((speed > 10) && (speed <= 20))
            {
                speed += 4;
            }
            else if ((speed > 20) && (speed <= 30))
            {
                speed += 8;
            }
            else if ((speed > 30) && (speed <= 40))
            {
                speed += 8;
            }
            else if ((speed > 40) && (speed <= 50))
            {
                speed += 12;
            }
            else if ((speed > 50) && (speed <= 60))
            {
                speed += 12;
            }
            else if ((speed > 60) && (speed <= 70))
            {
                speed += 14;
            }
            else if ((speed > 70) && (speed <= 80))
            {
                speed += 16;
            }
            else if ((speed > 80))
            {
                speed += 20;
            }
        }
        [self->interactive CarSpeedSero:self->SeroState CarSpeed:speed];
        dispatch_async(dispatch_get_main_queue(), ^{
            
            
            self.gearLabel.text = [NSString stringWithFormat:@"%d",self->currentGear];
            self.speedLabel.text = [NSString stringWithFormat:@"%d",speed];
            self.turbineLabel.text = [NSString stringWithFormat:@"%.1f",self->turboBoostValue];
            self.speed2Label.text = [NSString stringWithFormat:@"%d",self->engineRPMValue];
            self.throttleLabel.text = [NSString stringWithFormat:@"%d%%",(int)self->ThrottleValue];
            
            float value_wolun = self->turboBoostValue / 1500.0;
            float value_zhuanshu = self->engineRPMValue / 7000.0;
            float value_youmen = self->ThrottleValue / 100.0;
            
            CGRect turbinViewFrame = self.turbineView.frame;
            self.turbinetraillayout.constant = 20 + ([UIScreen mainScreen].bounds.size.width - turbinViewFrame.origin.x - 20) * (1.0- value_wolun);

            CGRect zhuanshuFrame = self.rpmView.frame;
            self.rpmtaillayout.constant = 20 + ([UIScreen mainScreen].bounds.size.width - zhuanshuFrame.origin.x - 20) *  (1.0 - value_zhuanshu);
            
            CGRect throttleFrame = self.throttleView.frame;
            self.throttlelayout.constant = 20 + ([UIScreen mainScreen].bounds.size.width - throttleFrame.origin.x - 20) * (1.0 - value_youmen);
            [self.view layoutIfNeeded];
            
        });
    });
    
    dispatch_resume(Readtimer);
}


-(void)recvreadyNotify:(NSNotification *) notify {
    
    NSLog(@"收到准备的通知");
    dispatch_async(dispatch_get_main_queue(), ^{
        [self readyLabelView];
    });
}
-(void)recvstartimerNotify:(NSNotification *) notify {
    
    iscounttimer = YES;
    NSLog(@"开始速度计时");
    [self removereadyLabel];
    [self timerFunc];
    
}
-(void)readyLabelView{
    
    if(self.readyLabel){
        [self.readyLabel removeFromSuperview];
    }
    iscounttimer = NO;
    
    self.readyLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 400, 100)];
    self.readyLabel.font = [UIFont boldSystemFontOfSize:60];
    self.readyLabel.textColor = [UIColor whiteColor];
    self.readyLabel.textAlignment = NSTextAlignmentCenter;
    self.readyLabel.text = @"READY";
    self.readyLabel.center = CGPointMake([UIScreen mainScreen].bounds.size.width / 2, [UIScreen mainScreen].bounds.size.height / 2);
    
    [self.view addSubview:self.readyLabel];
    
}
-(void)removereadyLabel{
    NSLog(@"将ready移除");
    dispatch_async(dispatch_get_main_queue(), ^{
        if(self.readyLabel){
            [self.readyLabel removeFromSuperview];
        }
    });
}
-(void)recvStopTimerNotify:(NSNotification *) notify {
    
    iscounttimer = NO;
    if(animation_t_internet){
        dispatch_source_cancel(animation_t_internet);
        animation_t_internet = nil;
    }
    [self removereadyLabel];
    NSLog(@"收到结束计时的通知");
    NSDictionary * data = notify.userInfo;
    CGFloat time = [data[@"time"] floatValue];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        self.speedLabel.text = @"100";
        [self endTimerFunc:time];
    });
    
}
-(void)endTimerFunc:(CGFloat) time {
    if(self.recoredTimeLabel){
        [self.recoredTimeLabel removeFromSuperview];
    }
    
    self.recoredTimeLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 400, 100)];
    self.recoredTimeLabel.center = CGPointMake([UIScreen mainScreen].bounds.size.width / 2, [UIScreen mainScreen].bounds.size.height / 2);
    self.recoredTimeLabel.font = [UIFont boldSystemFontOfSize:60.0];
    self.recoredTimeLabel.textColor = [UIColor whiteColor];
    self.recoredTimeLabel.textAlignment = NSTextAlignmentCenter;
    self.recoredTimeLabel.text = [NSString stringWithFormat:@"%.2f s",time];
    
    [self.view addSubview:self.recoredTimeLabel];
    
    
//    NSString * timeString = [NSString stringWithFormat:@"00:00:%05.2f0",time];
    NSString * timeString = [NSString stringWithFormat:@"00:00:%06.3f",time];
    
    //设置时间间隔
    double delay = 100;
    int64_t delta = (int64_t)delay * NSEC_PER_MSEC;
    dispatch_time_t poptime = dispatch_time(DISPATCH_TIME_NOW, delta);
    dispatch_after(poptime, dispatch_get_main_queue(), ^{
        self.timeLabel.text = timeString;
    });
}
-(void)testFaileNotify:(NSNotification *) notify {
    [self removereadyLabel];
    dispatch_async(dispatch_get_main_queue(), ^{
        [self addFailLabel];
    });
    iscounttimer = NO;
    if(animation_t_internet){
        dispatch_source_cancel(animation_t_internet);
        animation_t_internet = nil;
    }
    NSLog(@"收到测速超时失败的通知");
    dispatch_async(dispatch_get_main_queue(), ^{
        NSString * timeString = [NSString stringWithFormat:@"00:00:00.000"];
        
        //设置时间间隔
        double delay = 100;
        int64_t delta = (int64_t)delay * NSEC_PER_MSEC;
        dispatch_time_t poptime = dispatch_time(DISPATCH_TIME_NOW, delta);
        dispatch_after(poptime, dispatch_get_main_queue(), ^{
            self.timeLabel.text = timeString;
        });
    });
}
-(void)addFailLabel {
    if(self.faileLabel){
        [self.faileLabel removeFromSuperview];
    }
    
    self.faileLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 400, 100)];
    self.faileLabel.center = CGPointMake([UIScreen mainScreen].bounds.size.width / 2, [UIScreen mainScreen].bounds.size.height / 2);
    self.faileLabel.font = [UIFont boldSystemFontOfSize:60.0];
    self.faileLabel.textColor = [UIColor whiteColor];
    self.faileLabel.textAlignment = NSTextAlignmentCenter;
    self.faileLabel.text = @"TEST FAIL";
    
    [self.view addSubview:self.faileLabel];
}
-(void)timerFunc {
    
    if(self->animation_t_internet){
        dispatch_source_cancel(self->animation_t_internet);
        self->animation_t_internet = nil;
    }
    self->micro_second = 0;
    //设置时间间隔
    NSTimeInterval period = 0.001f;
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    animation_t_internet = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, queue);
    
    // 第一次不会立刻执行，会等到间隔时间后再执行
    //    dispatch_time_t start = dispatch_time(DISPATCH_TIME_NOW, period * NSEC_PER_SEC);
    //    dispatch_source_set_timer(_timer, start, period * NSEC_PER_SEC, 0);
    
    // 第一次会立刻执行，然后再间隔执行
    dispatch_source_set_timer(animation_t_internet, dispatch_walltime(NULL, 0), period * NSEC_PER_SEC, 0);
    // 事件回调
    dispatch_source_set_event_handler(animation_t_internet, ^{
        if(self->iscounttimer == NO){
            if(self->animation_t_internet){
                dispatch_source_cancel(self->animation_t_internet);
                self->animation_t_internet = nil;
            }
            self->micro_second = 0;
            dispatch_async(dispatch_get_main_queue(), ^{
                self.timeLabel.text = [NSString stringWithFormat:@"00:00:00.000"];
            });
            
        }else{
            self->micro_second++;
            int second_micro = self->micro_second % 1000;
            int second = (int)(self->micro_second / 1000);
            int minute = second / 60;
            int hour = minute / 60;
            
            int show_second = second % 60;
            int show_minute = minute % 60;
            int show_hour = hour;
            dispatch_async(dispatch_get_main_queue(), ^{
                self.timeLabel.text = [NSString stringWithFormat:@"%02d:%02d:%02d.%03d",show_hour,show_minute,show_second,second_micro];
            });
        }

    });
    
    // 开启定时器
    if (animation_t_internet) {
        dispatch_resume(animation_t_internet);
    }

}
-(void)recvSpeedTestPacket1:(NSNotification *) notify {
    NSLog(@"收到第一个数据包的通知");
    [handler sendSpeedTestPacket2];
}
-(void)recvSpeedTestPacket2Sero1:(NSNotification * ) notify {
    [handler sendspeedTest];
}
-(void)recvSpeedTestPacket2Sero2:(NSNotification * ) notify {
    [handler sendSpeedTestPacket3Sero2];
}
-(void)recvSpeedTestPacket3Sero2:(NSNotification * ) notify {
    [handler sendspeedTest];
}
-(void)recvSpeedData:(NSNotification *) notify {
    
    double delay = 10;
    int64_t delta = (int64_t)delay * NSEC_PER_MSEC;
    dispatch_time_t poptime = dispatch_time(DISPATCH_TIME_NOW, delta);
    dispatch_after(poptime, dispatch_get_global_queue(0, 0), ^{
        [self sendSpeedTestPacket];
    });

    
    NSDictionary * data = notify.userInfo;
    NSLog(@"收到测速数据通知: %@",data);

    int youmen = [data[@"youmen1"] intValue];
    float wolun = [data[@"wolun"] floatValue];
    int zhuanshu = [data[@"zhuanshu"] intValue];
    int dangwei = [data[@"dangwei"] intValue];
    int shudu = [data[@"shudu"] intValue];
    int sero = [data[@"sero"] intValue];
    
    if(zhuanshu >= 7000){
        zhuanshu = 7000;
    }
    if(zhuanshu <= 0){
        zhuanshu = 0;
    }
    if(youmen >= 100){
        youmen = 100;
    }
    if(youmen <= 0){
        youmen = 0;
    }
    if(dangwei > 99){
        dangwei = 99;
    }
    if(dangwei < 1){
        dangwei = 1;
    }
    if(wolun >= 1500){
        wolun = 1500;
    }
    if(wolun <= 0){
        wolun = 0;
    }
    
    
    BOOL isRecord = [[NSUserDefaults standardUserDefaults] boolForKey:@"isRecord"];
    NSLog(@"--------------> isRecord: %d",isRecord);
    if(isRecord == true){
        NSString * filename = [[NSUserDefaults standardUserDefaults] objectForKey:@"txtFilePath"];
        NSLog(@"txtFilename: %@",filename);
        NSFileHandle * fileHandler = [NSFileHandle fileHandleForWritingAtPath:filename];
        [fileHandler seekToEndOfFile];
        NSString * timeval = [NSString stringWithFormat:@"%.f",[NSDate date].timeIntervalSince1970 * 1000];
        // 如果是同一毫秒内，则只记录一次
        if(timeString && [timeString isEqualToString:timeval]){
            
        }else{
            //  38   个字符                wolun : 0-900
            //                      毫秒级时间戮: 油门 : 速度 ： 挡位 ： 涡轮 ： 转速
            //         NSString * itemString = @"[1685081935413:200:100:10:1400.4:9999]";
          //  NSLog(@"itemString.length: %ld",itemString.length);
            NSString * single = [NSString stringWithFormat:@"[%@:%03d:%03d:%02d:%06.1f:%04d]",timeval,youmen,shudu,dangwei,wolun,zhuanshu];
            NSLog(@"-------------> single: %@",single);
            NSData * singleData = [single dataUsingEncoding:NSUTF8StringEncoding];
            [fileHandler writeData:singleData];
            [fileHandler closeFile];
            timeString = timeval;
        }

    }
    
    

    

    int speed = shudu;
    if(sero == 1){
        if ((speed > 1) && (speed <= 10))
        {
            speed += 1;
        }
        else if ((speed > 10) && (speed <= 20))
        {
            speed += 1;
        }
        else if ((speed > 20) && (speed <= 30))
        {
            speed += 2;
        }
        else if ((speed > 30) && (speed <= 40))
        {
            speed += 2;
        }
        else if ((speed > 40) && (speed <= 50))
        {
            speed += 2;
        }
        else if ((speed > 50) && (speed <= 60))
        {
            speed += 2;
        }
        else if ((speed > 60) && (speed <= 70))
        {
            speed += 4;
        }
        else if ((speed > 70) && (speed <= 80))
        {
            speed += 4;
        }
        else if ((speed > 80))
        {
            speed += 4;
        }
    }else{
        if ((speed > 1) && (speed <= 10))
        {
            speed += 1;
        }
        else if ((speed > 10) && (speed <= 20))
        {
            speed += 4;
        }
        else if ((speed > 20) && (speed <= 30))
        {
            speed += 8;
        }
        else if ((speed > 30) && (speed <= 40))
        {
            speed += 8;
        }
        else if ((speed > 40) && (speed <= 50))
        {
            speed += 12;
        }
        else if ((speed > 50) && (speed <= 60))
        {
            speed += 12;
        }
        else if ((speed > 60) && (speed <= 70))
        {
            speed += 14;
        }
        else if ((speed > 70) && (speed <= 80))
        {
            speed += 16;
        }
        else if ((speed > 80))
        {
            speed += 20;
        }
    }
    
    [interactive CarSpeedSero:sero CarSpeed:speed];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        
        
        self.gearLabel.text = [NSString stringWithFormat:@"%d",dangwei];
        self.speedLabel.text = [NSString stringWithFormat:@"%d",speed];
        self.turbineLabel.text = [NSString stringWithFormat:@"%.1f",wolun];
        self.speed2Label.text = [NSString stringWithFormat:@"%d",zhuanshu];
        self.throttleLabel.text = [NSString stringWithFormat:@"%d%%",youmen];
        
        float value_wolun = wolun / 1500.0;
        float value_zhuanshu = zhuanshu / 7000.0;
        float value_youmen = youmen / 100.0;
        
        CGRect turbinViewFrame = self.turbineView.frame;
        self.turbinetraillayout.constant = 20 + ([UIScreen mainScreen].bounds.size.width - turbinViewFrame.origin.x - 20) * (1.0- value_wolun);

        
        CGRect zhuanshuFrame = self.rpmView.frame;
        self.rpmtaillayout.constant = 20 + ([UIScreen mainScreen].bounds.size.width - zhuanshuFrame.origin.x - 20) *  (1.0 - value_zhuanshu);
        
        CGRect throttleFrame = self.throttleView.frame;
        self.throttlelayout.constant = 20 + ([UIScreen mainScreen].bounds.size.width - throttleFrame.origin.x - 20) * (1.0 - value_youmen);
    });
    
}
-(void)setOrientationLandscapeRight{
    if ([[UIDevice currentDevice] respondsToSelector:@selector(setOrientation:)]) {

        AppDelegate *ape = (AppDelegate*)[[UIApplication sharedApplication] delegate];
        ape.state = 100;
        SEL selector = NSSelectorFromString(@"setOrientation:");
          NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:[UIDevice instanceMethodSignatureForSelector:selector]];

        [invocation setSelector:selector];

        [invocation setTarget:[UIDevice currentDevice]];

        int val = UIInterfaceOrientationLandscapeRight;

        [invocation setArgument:&val atIndex:2];

        [invocation invoke];

    }
}
-(void)setOrientationLandscape{
    if ([[UIDevice currentDevice] respondsToSelector:@selector(setOrientation:)]) {

        AppDelegate *ape = (AppDelegate*)[[UIApplication sharedApplication] delegate];
        ape.state = 200;
        SEL selector = NSSelectorFromString(@"setOrientation:");
          NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:[UIDevice instanceMethodSignatureForSelector:selector]];

        [invocation setSelector:selector];

        [invocation setTarget:[UIDevice currentDevice]];

        int val = UIInterfaceOrientationPortrait;

        [invocation setArgument:&val atIndex:2];

        [invocation invoke];

    }
}
-(void)startCapture {
    interactive = [[SpeedTestInteractive alloc] init];
    [interactive initAudioInput:self.view];

}
-(void)sendSpeedTestPacket {
    NSLog(@"调用发送测速包方法");
    [handler sendspeedTest];
}
-(void)addTopView {
    UIView * v = [[NSBundle mainBundle] loadNibNamed:@"SpeedTestTopView" owner:nil options:nil][0];
    
    CGSize size = [UIScreen mainScreen].bounds.size;
    CGFloat width_video = size.width > size.height ? size.width : size.height;
    CGFloat height_video = size.width > size.height ? size.height : size.width;
    
    UIView * v1 = [[UIView alloc] init];
    v1.frame = CGRectMake(0, 0, width_video, 60);
    v.frame = v1.bounds;
    [v1 addSubview:v];
    v1.backgroundColor = [UIColor redColor];
    [self.view addSubview:v1];
    
}
-(void)addBottomView {
    
    UIView * v = [[NSBundle mainBundle] loadNibNamed:@"SpeedTestBottomView" owner:self options:nil][0];
    
    
    self.bmwLabel = [v viewWithTag:1];
    self.ecuLabel = [v viewWithTag:2];
    self.tcuLabel = [v viewWithTag:3];
    
    self.gearLabel = [v viewWithTag:100];
    self.speedLabel = [v viewWithTag:200];
    self.turbineLabel = [v viewWithTag:300];
    self.speed2Label = [v viewWithTag:400];
    self.throttleLabel = [v viewWithTag:500];
    self.timeLabel = [v viewWithTag:1000];
    
    self.turbineView = [v viewWithTag:666];
    self.rpmView = [v viewWithTag:6666];
    self.throttleView = [v viewWithTag:66666];
    
    turbineWidth = self.turbineView.frame.size.width;
    rpmWidth = self.rpmView.frame.size.width;
    throttleWidth = self.throttleView.frame.size.width;
    
    CGRect zeroWidthRect = self.turbineView.frame;
    self.throttlelayout.constant = 20 + zeroWidthRect.size.width;
    
    zeroWidthRect = self.rpmView.frame;
    self.rpmtaillayout.constant = 20 + zeroWidthRect.size.width;
    
    zeroWidthRect = self.throttleView.frame;
    self.throttlelayout.constant = 20 + zeroWidthRect.size.width;
    
    self.turbineLabel.text = @"";
    self.speed2Label.text = @"";
    self.throttleLabel.text = @"";
    
    CGSize size = [UIScreen mainScreen].bounds.size;
    CGFloat width_video = size.width > size.height ? size.width : size.height;
    CGFloat height_video = size.width > size.height ? size.height : size.width;
    
    UIView * v1 = [[UIView alloc] init];
    v1.frame = CGRectMake(0, height_video - 100, width_video, 100);
    v.frame = v1.bounds;
    [v1 addSubview:v];
    v1.backgroundColor = [UIColor redColor];
    [self.view addSubview:v1];
    
    
    NSString * vechicletype = [[NSUserDefaults standardUserDefaults] objectForKey:@"vehicleType"];
    NSString * ecutuning = [[NSUserDefaults standardUserDefaults] objectForKey:@"ecutuning"];
    NSString * tcutuning = [[NSUserDefaults standardUserDefaults] objectForKey:@"tcutuning"];
    
    if(vechicletype == nil){
        self.bmwLabel.text = [NSString stringWithFormat:@"BMW 320i"];
    }else{
        self.bmwLabel.text = [NSString stringWithFormat:@"BMW %@",vechicletype];
    }
    
    if(ecutuning == nil || [ecutuning containsString:@"Unknown"]){
        self.ecuLabel.text = [NSString stringWithFormat:@"ECU:ZD8"];
    }else{
        self.ecuLabel.text = [NSString stringWithFormat:@"ECU:%@",ecutuning];
    }
    
    if(tcutuning == nil || [tcutuning containsString:@"Unknown"]){
        self.tcuLabel.text = [NSString stringWithFormat:@"TCU:Stock"];
    }else{
        self.tcuLabel.text = [NSString stringWithFormat:@"TCU:%@",tcutuning];
    }

}
-(void)didTapEscButton {
    if (Readtimer) {
        dispatch_source_cancel(Readtimer);
        Readtimer = nil;
    }
    [self.navigationController popViewControllerAnimated:YES];
    AppDelegate *ape = (AppDelegate*)[[UIApplication sharedApplication] delegate];
    ape.state = 0;
}











/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
