//
//  SpeedView.m
//  CarLinkChannel
//
//  Created by job on 2023/5/22.
//

#import "SpeedView.h"
#import <AVFoundation/AVFoundation.h>
#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>
NSFileHandle * fileHandler;
@interface SpeedView()
{
    dispatch_semaphore_t t;
//    dispatch_source_t timeout_t;
//    int count;
    double count_progress;
    double progress;
    NSMutableArray * avassetExportArray;
    NSTimer * timer;
    NSTimeInterval speedStartTimeStamp;             // 记录的有速度开始时的时间戮
    __block CGFloat durationReady;
    __block CGFloat startvalue;
    __block CGFloat durationvalue;
    NSArray<NSString *> * stringSero;
    int youmen;
    int sudu;
    int dangwei;
    float wolun;
    int zhuanshu;
//    int count;
//    NSString * videopartpath;
//    __block CMTime startTime;
//    __block CMTime durTime;
    int sero;
}

@end

@implementation SpeedView

- (CALayer *)addTopLayerWithVideoSize:(CGSize)size {
    CALayer * topLayer = [CALayer layer];
    topLayer.backgroundColor = [UIColor blackColor].CGColor;
    [topLayer setFrame:CGRectMake(0, 0, size.width, 80)];
    

    CFStringRef fontName = (__bridge  CFStringRef)@".SFUI-Semibold";
    CGFontRef fontRef = CGFontCreateWithFontName(fontName);
    
    CATextLayer * leftLayer = [CATextLayer layer];
    leftLayer.fontSize = 20.0;
    leftLayer.font = fontRef;
    leftLayer.string = @"Automatic Video Recording";
    leftLayer.contentsGravity = kCAGravityCenter;
    leftLayer.alignmentMode = kCAAlignmentCenter;
    leftLayer.contentsRect = CGRectMake(0, -0.3, 1, 1);
    leftLayer.backgroundColor = [UIColor clearColor].CGColor;
    leftLayer.foregroundColor = [UIColor whiteColor].CGColor;
    leftLayer.frame = CGRectMake(0, 20, size.width / 2 - 100, 40);
    
    // 2. 添加zd8的logo
    
    CALayer * logoLayer = [CALayer layer];
    logoLayer.frame = CGRectMake(size.width / 2 - 60, 20, 120, 40);
    logoLayer.contents = (id)[UIImage imageNamed:@"77"].CGImage;
    

    CATextLayer * titleLayer = [CATextLayer layer];
    [titleLayer setFontSize:20.0];
    [titleLayer setFont:fontRef];
    [titleLayer setString:@"ZD8 is a Professional ECU TCU calibration brand!"];
    titleLayer.contentsGravity = kCAGravityCenter;
    titleLayer.alignmentMode = kCAAlignmentCenter;
    titleLayer.contentsRect = CGRectMake(0, -0.3, 1, 1);
    [titleLayer setBackgroundColor:[UIColor clearColor].CGColor];
    [titleLayer setForegroundColor:[UIColor whiteColor].CGColor];
    [titleLayer setFrame:CGRectMake(size.width / 2 + 100, 20, size.width / 2 -  100, 40)];
    
    [topLayer addSublayer:leftLayer];
    [topLayer addSublayer:logoLayer];
    [topLayer addSublayer:titleLayer];
    
    return topLayer;
}
//+(CALayer *)
- (CALayer *)addBottomLayerWithVideoSize:(CGSize)size starttime:(CGFloat)stime endtime:(float)dtime seroString:(int)sero txtFilePath:(NSString *) path{
    CALayer * bottomLayer = [CALayer layer];
    bottomLayer.backgroundColor = [UIColor blackColor].CGColor;
    bottomLayer.frame = CGRectMake(0, size.height - 180, size.width, 180);
    
    // 添加几个标题
   // [path drawInRect:<#(CGRect)#> withAttributes:<#(nullable NSDictionary<NSAttributedStringKey,id> *)#>];
    CATextLayer * bmwLayer = [CATextLayer layer];
    
//    UIFont * font = [UIFont boldSystemFontOfSize:20];
//    CFStringRef fontName = (__bridge CFStringRef)font.fontName;
//    CFStringRef fontName = (__bridge  CFStringRef)@".SFUI-Bold";
    CFStringRef fontName = (__bridge  CFStringRef)@"ArialRoundedMTBold";
    CGFontRef fontRef = CGFontCreateWithFontName(fontName);

    [bmwLayer setFont:fontRef];
    [bmwLayer setFontSize:22];
    [bmwLayer setForegroundColor:[UIColor whiteColor].CGColor];
    [bmwLayer setString:@"BMW 320li"];
    [bmwLayer setFrame:CGRectMake(20, 45, 220, 30)];
    
    CATextLayer *  ecuLayer = [CATextLayer layer];
    
    [ecuLayer setFont:fontRef];
    [ecuLayer setFontSize:22];
    [ecuLayer setForegroundColor:[UIColor whiteColor].CGColor];
    [ecuLayer setString:@"ECU: ZD8 Stage 1"];
    [ecuLayer setFrame:CGRectMake(20, 75, 220, 30)];
    
    CATextLayer * tcuLayer = [CATextLayer layer];
    
    [tcuLayer setFont:fontRef];
    [tcuLayer setFontSize:22];
    [tcuLayer setForegroundColor:[UIColor whiteColor].CGColor];
    [tcuLayer setString:@"TCU: Stock"];
    [tcuLayer setFrame:CGRectMake(20, 105, 220, 30)];
    
    NSString * vechicletype = [[NSUserDefaults standardUserDefaults] objectForKey:@"vehicleType"];
    NSString * ecutuning = [[NSUserDefaults standardUserDefaults] objectForKey:@"ecutuning"];
    NSString * tcutuning = [[NSUserDefaults standardUserDefaults] objectForKey:@"tcutuning"];
    
    if(vechicletype == nil){
        bmwLayer.string = [NSString stringWithFormat:@"BMW xxx"];
    }else{
        bmwLayer.string = [NSString stringWithFormat:@"BMW %@",vechicletype];
    }
    
    if(ecutuning == nil || [ecutuning containsString:@"Unknown"]){
        ecuLayer.string = [NSString stringWithFormat:@"ECU: ZD8"];
    }else{
        ecuLayer.string = [NSString stringWithFormat:@"ECU: %@",ecutuning];
    }
    
    if(tcutuning == nil || [tcutuning containsString:@"Unknown"]){
        tcuLayer.string = [NSString stringWithFormat:@"TCU: ZD8"];
    }else{
        tcuLayer.string = [NSString stringWithFormat:@"TCU: %@",tcutuning];
    }
    
    
    // 1. 首先添加 gear
    
    CATextLayer * valueGearLayer = [CATextLayer layer];
    [valueGearLayer setFontSize:50];
    valueGearLayer.alignmentMode = kCAAlignmentCenter;
    [valueGearLayer setForegroundColor:[UIColor whiteColor].CGColor];
    [valueGearLayer setFrame: CGRectMake(240, 20, 90, 60)];
    [valueGearLayer setString:@""];
    
    CATextLayer * gearTagLayer = [CATextLayer layer];
    //    CF_BRIDGED_TYPE([UIFont boldSystemFontOfSize:20]);
    //    CFStringRef s = (__bridge CFStringRef)@"System";
    //    CGFontRef font = CGFontCreateWithFontName(s);
    //    [gearTagLayer setFont:CGFontRetain(font)];
    gearTagLayer.font = fontRef;
    [gearTagLayer setFontSize:24];
    [gearTagLayer setString:@"GEAR"];
    gearTagLayer.alignmentMode = kCAAlignmentCenter;
    [gearTagLayer setForegroundColor:[UIColor whiteColor].CGColor];
    [gearTagLayer setBackgroundColor:[UIColor clearColor].CGColor];
    [gearTagLayer setFrame:CGRectMake(240, 100, 90, 60)];
    gearTagLayer.allowsFontSubpixelQuantization = YES;
    
    // 2. 添加 speed
    
    
    CATextLayer * speedTextValueLayer = [CATextLayer layer];
    speedTextValueLayer.alignmentMode = kCAAlignmentCenter;
    [speedTextValueLayer setString:@""];
    [speedTextValueLayer setFontSize:50];
    [speedTextValueLayer setForegroundColor:[UIColor whiteColor].CGColor];
    [speedTextValueLayer setFrame:CGRectMake(330, 20, 90, 60)];
    
    CATextLayer * speedLayer = [CATextLayer layer];
    [speedLayer setFontSize:24];
    [speedLayer setString:@"SPEED"];
    speedLayer.font = fontRef;
    speedLayer.alignmentMode = kCAAlignmentCenter;
    [speedLayer setForegroundColor:[UIColor whiteColor].CGColor];
    [speedLayer setBackgroundColor:[UIColor clearColor].CGColor];
    [speedLayer setFrame:CGRectMake(330, 100, 90, 60)];
    
    // 3. 添加 zendao logo
    CALayer * zendaologoLayer = [CALayer layer];
    zendaologoLayer.frame = CGRectMake(size.width / 2 - 153, 100, 306, 60);
    zendaologoLayer.contents = (id)[UIImage imageNamed:@"66"].CGImage;
    
    // 4. 添加右侧的 3个 进度条
    
    CATextLayer * gurbineLayer = [CATextLayer layer];
    
    [gurbineLayer setFont:fontRef];
    [gurbineLayer setFontSize:24];
    [gurbineLayer setString:@"Turbine"];
    [gurbineLayer setContentsRect:CGRectMake(0, -0.3, 1, 1)];
    [gurbineLayer setBackgroundColor:[UIColor clearColor].CGColor];
    [gurbineLayer setForegroundColor:[UIColor whiteColor].CGColor];
    [gurbineLayer setFrame:CGRectMake(size.width / 2 + 90 + 100 + 20 + 50 + 10
                                      , 15, 120, 50)];
    
    
    CATextLayer * gurbineValueLayer = [CATextLayer layer];
    [gurbineValueLayer setFontSize:20];
    [gurbineValueLayer setString:@""];
    [gurbineValueLayer setForegroundColor:[UIColor whiteColor].CGColor];
    [gurbineValueLayer setBackgroundColor:[UIColor clearColor].CGColor];
    [gurbineValueLayer setContentsRect:CGRectMake(0, -0.3, 1, 1)];
    [gurbineValueLayer setAlignmentMode:kCAAlignmentRight];
    [gurbineValueLayer setFrame:CGRectMake(size.width / 2 + 90 + 100 + 20 + 50 + 20 + 100 + 10, 0, 60, 50)];
    
    CATextLayer * speedtagLayer = [CATextLayer layer];
    
    [speedtagLayer setFont:fontRef];
    [speedtagLayer setFontSize:24];
    [speedtagLayer setString:@"RPM"];
    [speedtagLayer setContentsRect:CGRectMake(0, -0.3, 1, 1)];
    [speedtagLayer setForegroundColor:[UIColor whiteColor].CGColor];
    [speedtagLayer setBackgroundColor:[UIColor clearColor].CGColor];
    [speedtagLayer setFrame:CGRectMake(size.width / 2 +  90 + 100 + 20 + 50  + 10, 65 , 120, 50)];
    
    CATextLayer * speedtagValueLayer = [CATextLayer layer];
    [speedtagValueLayer setFontSize:20];
    [speedtagValueLayer setString:@""];
    [speedtagValueLayer setAlignmentMode:kCAAlignmentRight];
    [speedtagValueLayer setContentsRect:CGRectMake(0, -0.3, 1, 1)];
    [speedtagValueLayer setForegroundColor:[UIColor whiteColor].CGColor];
    [speedtagValueLayer setBackgroundColor:[UIColor clearColor].CGColor];
    [speedtagValueLayer setFrame:CGRectMake(size.width / 2 + 90 + 100 + 20 + 50 + 20 + 100 + 10, 50, 60, 50)];
    
    CATextLayer * ghrottleLayer = [CATextLayer layer];
    
    [ghrottleLayer setFont:fontRef];
    [ghrottleLayer setFontSize:24];
    [ghrottleLayer setString:@"Throttle"];
    [ghrottleLayer setContentsRect:CGRectMake(0, -0.3, 1, 1)];
    [ghrottleLayer setForegroundColor:[UIColor whiteColor].CGColor];
    [ghrottleLayer setBackgroundColor:[UIColor clearColor].CGColor];
    [ghrottleLayer setFrame:CGRectMake(size.width / 2 +  90 + 100 + 20 + 50 + 10, 115, 120, 50)];
    
    CATextLayer * ghrottleValueLayer = [CATextLayer layer];
    [ghrottleValueLayer setFontSize:20];
    [ghrottleValueLayer setString:@""];
    [ghrottleValueLayer setContentsRect:CGRectMake(0, -0.3, 1, 1)];
    [ghrottleValueLayer setAlignmentMode:kCAAlignmentRight];
    [ghrottleValueLayer setForegroundColor:[UIColor whiteColor].CGColor];
    [ghrottleValueLayer setBackgroundColor:[UIColor clearColor].CGColor];
    [ghrottleValueLayer setFrame:CGRectMake(size.width / 2 + 90 + 100 + 20 + 50 + 20 + 100 + 10, 100, 60, 50)];
    
    
    // 添加进度条
    CALayer * turbineprogressLayer = [CALayer layer];
//    turbineprogressLayer.backgroundColor = [UIColor systemPinkColor].CGColor;
    [turbineprogressLayer setFrame:CGRectMake(size.width / 2 + 90 + 100 + 20 + 20 + 50 + 100, 4, 150, 40)];
    turbineprogressLayer.anchorPoint = CGPointMake(0, 0);
    
    CALayer * speedprogressLayer = [CALayer layer];
//    speedprogressLayer.backgroundColor = [UIColor systemPurpleColor].CGColor;
    [speedprogressLayer setFrame:CGRectMake(size.width / 2 + 90 + 100 + 20 + + 20 + 50 + 100, 50, 150, 40)];
    speedprogressLayer.anchorPoint = CGPointZero;
    
    CALayer * throttleprogresslayer = [CALayer layer];
//    throttleprogresslayer.backgroundColor = [UIColor blueColor].CGColor;
    [throttleprogresslayer setFrame:CGRectMake(size.width / 2 + 90 + 100 + 20 + 20 + 50 + 100, 100, 150, 40)];
    throttleprogresslayer.anchorPoint = CGPointZero;
    
 
    NSData * data = nil;
    double startTime = 0;
    double currentTime = 0;
    double end_time_speed = 0;
    double end_time_gear = 0;
    double end_time_wolun = 0;
    double end_time_zhuansu = 0;
    double end_time_throttle = 0;
    
    bool isSpeedAnimation = false;
    bool isGearAnimation = false;
    bool isTurbinAnimation = false;
    bool isZhuansuAnimation = false;
    bool isThrottoleAnimation = false;
    
    
    
    double timestamp_origin = 0;
    BOOL youmen_state = NO;
    BOOL sudu_state = NO;
    BOOL dangwei_state = NO;
    BOOL wolun_state = NO;
    BOOL zhuanshu_state = NO;
    BOOL isNoData = false;
    
    int youmen_origin = 0;
    int sudu_origin = 0;
    int dangwei_origin = 0;
    float wolun_origin = 0;
    int zhuanshu_origin = 0;
    
    float youmen_time_start = 0;
    float sudu_time_start = 0;
    float dangwei_time_start = 0;
    float wolun_time_start = 0;
    float zhuanshu_time_start = 0;
    
    
    NSMutableArray * dangweiValueArray = [NSMutableArray array];
    NSMutableArray * dangweiTimeArray = [NSMutableArray array];
    
    NSMutableArray * speedValueArray = [NSMutableArray array];
    NSMutableArray * speedTimeArray = [NSMutableArray array];
    
//    NSMutableArray *
    
    // 油门的值数组和时间数组
    NSMutableArray * wolunValueArray = [NSMutableArray array];
    NSMutableArray * wolunTimeArray = [NSMutableArray array];
    
    NSMutableArray * wolunProgressArray = [NSMutableArray array];
    
    NSMutableArray * zhuansuValueArray = [NSMutableArray array];
    NSMutableArray * zhuansuTimeArray = [NSMutableArray array];
    
    NSMutableArray * zhuansuProgressArray = [NSMutableArray array];
    
    NSMutableArray * youmenValueArray = [NSMutableArray array];
    NSMutableArray * youmenTimeArray = [NSMutableArray array];
    
    NSMutableArray * youmenProgressArray = [NSMutableArray array];
    
    
    int danwei = 10;
    int count = 0;
    do {
        data = [fileHandler readDataOfLength:41];
        
        if(data.length > 0){
            count ++;
            NSString * itemString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];

            itemString = [itemString stringByReplacingOccurrencesOfString:@"[" withString:@""];
            itemString = [itemString stringByReplacingOccurrencesOfString:@"]" withString:@""];
            itemString = [itemString stringByReplacingOccurrencesOfString:@" " withString:@""];
            
            // 这可能是在视频加速到100km/h后
            if(itemString.length < 36){


                currentTime = dtime * 1000;
                isNoData = true;
                break;
            }
            NSArray<NSString *> * valueArray = [itemString componentsSeparatedByString:@":"];
            if(valueArray.count < 6){
                currentTime = dtime * 1000;
                isNoData = true;
                break;
            }
            NSString * timestampString = [valueArray objectAtIndex:0];
            NSString * youmenString = [valueArray objectAtIndex:1];
            NSString * suduString = [valueArray objectAtIndex:2];
            NSString * dangweiString = [valueArray objectAtIndex:3];
            NSString * wolunString = [valueArray objectAtIndex:4];
            NSString * zhuanshuString = [valueArray objectAtIndex:5];
            
            double timestamp = [timestampString doubleValue];
            //            NSLog(@"timeStamp: %f",timestamp);
            youmen = [youmenString intValue];
            sudu = [suduString intValue];
            dangwei = [dangweiString intValue];
            wolun = [wolunString floatValue];
            zhuanshu = [zhuanshuString intValue];
            if(sero >= 10){
                sero = sero / 10;
            }
            sudu = [self speedTransferSero:sero shudu:sudu];
            
            
            if(dangwei < 1){
                dangwei = 1;
            }
            if(wolun >= 1500){
                wolun = 1500;
            }
            if(wolun <= 0){
                wolun = 0;
            }
            
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
            if(startTime == 0){
                startTime = timestamp;

            }
            
            if(dangwei ==2)
            {
                NSLog(@"%f",timestamp);
                NSLog(@"%f",wolun);
                NSLog(@"%d",youmen);
            }
            
            
            currentTime = timestamp - startTime;
            double videoTime = timestamp - speedStartTimeStamp;
            
//            if(currentTime >= dtime * 1000){
            if(videoTime > (stime + dtime) * 1000){
                //NSLog(@"view 超出范围 currentTime: %f,starttime: %f",currentTime,startTime);
                [fileHandler seekToFileOffset:fileHandler.offsetInFile-41];
                //                return bottomLayer;
                break;
            }
        }else{
            currentTime = dtime * 1000;
            isNoData = true;
            break;
        }

            

        
            if(youmen_origin == 0 && youmen_state == NO){
                youmen_origin = youmen;

  
                
                UIImage * youmenImage = [self createOtherMerchantImage:[NSString stringWithFormat:@"%d%%",youmen_origin] alignment:NSTextAlignmentRight strFont:24 size:ghrottleValueLayer.frame.size];
                [youmenValueArray addObject:(__bridge id _Nullable)youmenImage.CGImage];
                
                [youmenTimeArray addObject:[NSNumber numberWithFloat:currentTime / 100.0]];
                
                UIImage * youmenProgressImage = [self createProgressView:youmen / 100.0 color:[UIColor colorWithRed:2/255.0 green:87/255.0 blue:165/255.0 alpha:1.0] size:throttleprogresslayer.frame.size];
                
                [youmenProgressArray addObject:(__bridge id _Nullable)youmenProgressImage.CGImage];

                youmen_state = YES;
            }
            if(sudu_origin == 0 && sudu_state == NO){
                sudu_origin = sudu;

                sudu_time_start = currentTime;
                
                
                [speedValueArray addObject:(__bridge id _Nullable)[self createOtherMerchantImage:[NSString stringWithFormat:@"%d",sudu_origin] alignment:NSTextAlignmentCenter strFont:56  size:CGSizeMake(speedTextValueLayer.frame.size.width, speedTextValueLayer.frame.size.height)].CGImage];
                [speedTimeArray addObject:[NSNumber numberWithFloat:currentTime / 100.0]];
                
                
                sudu_state = YES;
            }
            if(dangwei_origin == 0 && dangwei_state == NO){
                dangwei_origin = dangwei;

                dangwei_time_start = currentTime;
                
                UIImage * dangweiImage = [self createOtherMerchantImage:[NSString stringWithFormat:@"%d",dangwei_origin] alignment:NSTextAlignmentCenter strFont:56 size:CGSizeMake(valueGearLayer.frame.size.width, valueGearLayer.frame.size.height)];
                
                [dangweiValueArray addObject:(__bridge id _Nullable)dangweiImage.CGImage];
                [dangweiTimeArray addObject:[NSNumber numberWithFloat:currentTime / 100.0]];
                
                dangwei_state = YES;
            }
            if(wolun_origin == 0 && wolun_state == NO){
                wolun_origin = wolun;

                
                [wolunTimeArray addObject:[NSNumber numberWithFloat:currentTime/100.0]];
                
                UIImage * wolunImage = [self createOtherMerchantImage:[NSString stringWithFormat:@"%.f",wolun] alignment:NSTextAlignmentRight  strFont:24 size:gurbineValueLayer.frame.size];
                [wolunValueArray addObject:(__bridge id _Nullable)wolunImage.CGImage];
                
                UIImage * wolunProgressImage = [self createProgressView:wolun/1500.0 color:[UIColor systemPinkColor] size:turbineprogressLayer.frame.size];
                [wolunProgressArray addObject:(__bridge id _Nullable)wolunProgressImage.CGImage];

                wolun_time_start = currentTime;
                wolun_state = YES;
            }
            if(zhuanshu_origin == 0 && zhuanshu_state == NO){
                zhuanshu_origin = zhuanshu;
              
                UIImage * zhuanImage = [self createOtherMerchantImage:[NSString stringWithFormat:@"%d",zhuanshu] alignment:NSTextAlignmentRight  strFont:24 size:speedtagValueLayer.frame.size];
                [zhuansuValueArray addObject:(__bridge id _Nullable)zhuanImage.CGImage];
                
                [zhuansuTimeArray addObject:[NSNumber numberWithFloat:currentTime / 100.0]];
                
                UIImage * zhuansuProgressImage = [self createProgressView:zhuanshu / 7000.0 color:[UIColor colorWithRed:1/255.0 green:50/255.0 blue:111/255.0 alpha:1.0]  size:speedprogressLayer.frame.size];
                [zhuansuProgressArray addObject:(__bridge id _Nullable)zhuansuProgressImage.CGImage];

                zhuanshu_time_start = currentTime;
                zhuanshu_state = YES;
            }



            if(youmen_origin != youmen){

                UIImage * youmenImage = [self createOtherMerchantImage:[NSString stringWithFormat:@"%d%%",youmen] alignment:NSTextAlignmentRight  strFont:24  size:ghrottleValueLayer.frame.size];
                [youmenValueArray addObject:(__bridge id _Nullable)youmenImage.CGImage];
                
                [youmenTimeArray addObject:[NSNumber numberWithFloat:currentTime / 100.0]];
                
                UIImage * youmenProgressImage = [self createProgressView:youmen/100.0 color:[UIColor colorWithRed:2/255.0 green:87/255.0 blue:165/255.0 alpha:1.0] size:ghrottleValueLayer.frame.size];
                [youmenProgressArray addObject:(__bridge id _Nullable)youmenProgressImage.CGImage];

                youmen_time_start = currentTime;
                youmen_origin = youmen;
            }else{
                end_time_throttle = currentTime;
            }
            if(sudu_origin != sudu){

                
                UIImage * suduImage = [self createOtherMerchantImage:[NSString stringWithFormat:@"%d",sudu_origin] alignment:NSTextAlignmentCenter strFont:56 size:CGSizeMake(speedTextValueLayer.frame.size.width, speedTextValueLayer.frame.size.height)];
                [speedValueArray addObject:(__bridge id _Nullable)suduImage.CGImage];
                [speedTimeArray addObject:[NSNumber numberWithFloat:currentTime / 100.0]];

                sudu_origin = sudu;
                sudu_time_start = currentTime;
            }else{
                end_time_speed = currentTime;
            }
            if(dangwei_origin != dangwei){
                
                UIImage * dangweiImage = [self createOtherMerchantImage:[NSString stringWithFormat:@"%d",dangwei] alignment:NSTextAlignmentCenter strFont:56 size:CGSizeMake(valueGearLayer.frame.size.width, valueGearLayer.frame.size.height)];
                
                [dangweiValueArray addObject:(__bridge id _Nullable)dangweiImage.CGImage];
                [dangweiTimeArray addObject:[NSNumber numberWithFloat:currentTime / 100.0]];


                dangwei_time_start = currentTime;

                dangwei_origin = dangwei;
            }else{
                end_time_gear = currentTime;
            }
            if(wolun_origin != wolun){
                
                [wolunTimeArray addObject:[NSNumber numberWithFloat:currentTime/100.0]];
                
                UIImage * wolunImage = [self createOtherMerchantImage:[NSString stringWithFormat:@"%.f",wolun] alignment:NSTextAlignmentRight strFont:24  size:turbineprogressLayer.frame.size];
                [wolunValueArray addObject:(__bridge id _Nullable)wolunImage.CGImage];

                UIImage * wolunProgressImage = [self createProgressView:wolun/1500.0 color:[UIColor systemPinkColor] size:turbineprogressLayer.frame.size];
                [wolunProgressArray addObject:(__bridge id _Nullable)wolunProgressImage.CGImage];
                




                wolun_time_start = currentTime;

                wolun_origin = wolun;
            }else{
                end_time_wolun = currentTime;
            }
            if(zhuanshu_origin != zhuanshu){
                
                UIImage * zhuansuImage = [self createOtherMerchantImage:[NSString stringWithFormat:@"%d",zhuanshu] alignment:NSTextAlignmentRight strFont:24 size:speedtagValueLayer.frame.size];
                
                [zhuansuValueArray addObject:(__bridge id _Nullable)zhuansuImage.CGImage];
                [zhuansuTimeArray addObject:[NSNumber numberWithFloat:currentTime/100.0]];
                
                UIImage * zhuansuProgressImage = [self createProgressView:zhuanshu / 7000.0 color:[UIColor colorWithRed:1/255.0 green:50/255.0 blue:111/255.0 alpha:1.0] size:speedprogressLayer.frame.size];
                [zhuansuProgressArray addObject:(__bridge id _Nullable)zhuansuProgressImage.CGImage];


                zhuanshu_time_start = currentTime;
                zhuanshu_origin = zhuanshu;
            }else{
                end_time_zhuansu = currentTime;
            }
        
    } while (true);
    
    if(isNoData){
        
        valueGearLayer.contents = (__bridge id _Nullable)([self createOtherMerchantImage:[NSString stringWithFormat:@"%d",dangwei] alignment:NSTextAlignmentCenter strFont:56 size:CGSizeMake(valueGearLayer.frame.size.width, valueGearLayer.frame.size.height)].CGImage);
        
        speedTextValueLayer.contents = (__bridge id _Nullable)[self createOtherMerchantImage:[NSString stringWithFormat:@"%d",sudu] alignment:NSTextAlignmentCenter strFont:56 size:CGSizeMake(speedTextValueLayer.frame.size.width, speedTextValueLayer.frame.size.height)].CGImage;
        
        gurbineValueLayer.contents = (__bridge id _Nullable)[self createOtherMerchantImage:[NSString stringWithFormat:@"%.f",wolun] alignment:NSTextAlignmentRight strFont:24 size:gurbineValueLayer.frame.size].CGImage;
        
        speedtagValueLayer.contents = (__bridge id _Nullable)[self createOtherMerchantImage:[NSString stringWithFormat:@"%d",zhuanshu] alignment:NSTextAlignmentRight strFont:24 size:speedtagValueLayer.frame.size].CGImage;
    
        ghrottleValueLayer.contents = (__bridge id _Nullable)[self createOtherMerchantImage:[NSString stringWithFormat:@"%d%%",youmen] alignment:NSTextAlignmentRight strFont:24 size:ghrottleValueLayer.frame.size].CGImage;
  
            
        UIImage * wolunProgressImage = [self createProgressView:wolun/1500.0 color:[UIColor redColor] size:turbineprogressLayer.frame.size];
        
        turbineprogressLayer.contents = (__bridge  id _Nullable)wolunProgressImage.CGImage;
        
        UIImage * zhuansuProgressImage = [self createProgressView:zhuanshu / 7000.0 color:[UIColor colorWithRed:1/255.0 green:50/255.0 blue:111/255.0 alpha:1.0]  size:speedprogressLayer.frame.size];
        speedprogressLayer.contents = (__bridge  id _Nullable)zhuansuProgressImage.CGImage;
        
        UIImage * youmenProgressImage = [self createProgressView:youmen/100.0 color:[UIColor colorWithRed:2/255.0 green:87/255.0 blue:165/255.0 alpha:1.0] size:throttleprogresslayer.frame.size];
        
        throttleprogresslayer.contents = (__bridge  id _Nullable)youmenProgressImage.CGImage;
        
    }else{


    
    CAKeyframeAnimation * keyAnimation_wolun = [CAKeyframeAnimation animationWithKeyPath:@"contents"];
    keyAnimation_wolun.duration = dtime;
    keyAnimation_wolun.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionDefault];
    keyAnimation_wolun.keyTimes = wolunTimeArray;
    keyAnimation_wolun.values = wolunValueArray;
    keyAnimation_wolun.fillMode = kCAFillModeBoth;
    keyAnimation_wolun.beginTime = 0;
    keyAnimation_wolun.removedOnCompletion = NO;
//    keyAnimation_wolun.repeatCount = 1;
    
    [gurbineValueLayer addAnimation:keyAnimation_wolun forKey:@"wolun"];
    
    CAKeyframeAnimation * keyAnimation_wolun_progress = [CAKeyframeAnimation animationWithKeyPath:@"contents"];
    keyAnimation_wolun_progress.duration = dtime;
    keyAnimation_wolun_progress.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionDefault];
    keyAnimation_wolun_progress.keyTimes = wolunTimeArray;
    keyAnimation_wolun_progress.values = wolunProgressArray;
    keyAnimation_wolun_progress.fillMode = kCAFillModeBoth;
    keyAnimation_wolun_progress.beginTime = 0;
    keyAnimation_wolun_progress.removedOnCompletion = NO;
    
    [turbineprogressLayer addAnimation:keyAnimation_wolun_progress forKey:@"wolun"];
    
    CAKeyframeAnimation * keyAnimation_zhuansu = [CAKeyframeAnimation animationWithKeyPath:@"contents"];
    keyAnimation_zhuansu.duration = dtime;
    keyAnimation_zhuansu.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionDefault];
    keyAnimation_zhuansu.keyTimes = zhuansuTimeArray;
    keyAnimation_zhuansu.values = zhuansuValueArray;
    keyAnimation_zhuansu.fillMode = kCAFillModeBoth;
    keyAnimation_zhuansu.beginTime = 0;
    keyAnimation_zhuansu.removedOnCompletion = NO;
//    keyAnimation_zhuansu.repeatCount = 1;
    
    [speedtagValueLayer addAnimation:keyAnimation_zhuansu forKey:@"zs"];
    
    CAKeyframeAnimation * keyAnimation_zhuansu_progress = [CAKeyframeAnimation animationWithKeyPath:@"contents"];
    keyAnimation_zhuansu_progress.duration = dtime;
    keyAnimation_zhuansu_progress.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionDefault];
    keyAnimation_zhuansu_progress.keyTimes = zhuansuTimeArray;
    keyAnimation_zhuansu_progress.values = zhuansuProgressArray;
    keyAnimation_zhuansu_progress.fillMode = kCAFillModeBoth;
    keyAnimation_zhuansu_progress.beginTime = 0;
    keyAnimation_zhuansu_progress.removedOnCompletion = NO;
    
    
//    NSLog(@"---->--- stime; %d, zhuanvalueArray: %@,zhuantimearray: %@",stime,zhuansuValueArray,zhuansuTimeArray);
    
    
    [speedprogressLayer addAnimation:keyAnimation_zhuansu_progress forKey:@"zhuansu"];
    
    CAKeyframeAnimation * keyAnimation_youmen = [CAKeyframeAnimation animationWithKeyPath:@"contents"];
    keyAnimation_youmen.duration = dtime;
    keyAnimation_youmen.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionDefault];
    keyAnimation_youmen.keyTimes = youmenTimeArray;
    keyAnimation_youmen.values = youmenValueArray;
    keyAnimation_youmen.fillMode = kCAFillModeBoth;
    keyAnimation_youmen.beginTime = 0;
    keyAnimation_youmen.removedOnCompletion = NO;
//    keyAnimation_youmen.repeatCount = 1;
    
    [ghrottleValueLayer addAnimation:keyAnimation_youmen forKey:@"youmen"];
    
    CAKeyframeAnimation * keyAnimation_youmen_progress = [CAKeyframeAnimation animationWithKeyPath:@"contents"];
    keyAnimation_youmen_progress.duration = dtime;
    keyAnimation_youmen_progress.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionDefault];
    keyAnimation_youmen_progress.keyTimes = youmenTimeArray;
    keyAnimation_youmen_progress.values = youmenProgressArray;
    keyAnimation_youmen_progress.fillMode = kCAFillModeBackwards;
    keyAnimation_youmen_progress.beginTime = 0;
    keyAnimation_youmen_progress.removedOnCompletion = NO;
    
    [throttleprogresslayer addAnimation:keyAnimation_youmen_progress forKey:@"aadfasd"];
    
    CAKeyframeAnimation * keyAnimation = [CAKeyframeAnimation animationWithKeyPath:@"contents"];
    keyAnimation.duration = dtime;
    keyAnimation.values = speedValueArray;
    keyAnimation.keyTimes = speedTimeArray;
    keyAnimation.removedOnCompletion = NO;
    keyAnimation.fillMode = kCAFillModeBackwards;
    keyAnimation.beginTime = 0;
    
    [speedTextValueLayer addAnimation:keyAnimation forKey:@"animation"];
    

    
    CAKeyframeAnimation * keyAnimation_gear = [CAKeyframeAnimation animationWithKeyPath:@"contents"];
    keyAnimation_gear.duration = dtime;
    keyAnimation_gear.values = dangweiValueArray;
    keyAnimation_gear.keyTimes = dangweiTimeArray;
    keyAnimation_gear.removedOnCompletion = NO;
    keyAnimation_gear.fillMode = kCAFillModeBackwards;
    keyAnimation_gear.beginTime = 0;
    
    [valueGearLayer addAnimation:keyAnimation_gear forKey:@"animation"];
        
    }
    
    
    // 添加三个图标
    
    
    CALayer * turbineiconLayer = [CALayer layer];
    turbineiconLayer.frame = CGRectMake(size.width / 2 + 90 + 100 + 20 + 20, 30 , 30, 30);
    turbineiconLayer.contents = (id)[UIImage imageNamed:@"videowolun"].CGImage;
    
    CALayer * speediconLayer = [CALayer layer];
    speediconLayer.frame = CGRectMake(size.width / 2 + 90 + 100 + 20 + 20, 80, 30, 30);
    speediconLayer.contents = (id)[UIImage imageNamed:@"videozhuanshu"].CGImage;
    
    CALayer * throttleiconLayer = [CALayer layer];
    throttleiconLayer.frame = CGRectMake(size.width / 2 + 90 + 100 + 20 + 20, 130, 30, 30);
    throttleiconLayer.contents = (id)[UIImage imageNamed:@"videoyoumen"].CGImage;

    
    // 添加秒表
    
    //  计算坐标值
        NSString * m_str = @"00:00:00.001";
        NSString * str = @"00:";
    
        BOOL hidden = [[NSUserDefaults standardUserDefaults] boolForKey:@"videoexport"];
        if(hidden){
            m_str = @"00:00:00";
        }
    
        CGSize text_size = [m_str sizeWithAttributes:@{NSFontAttributeName:[UIFont fontWithName:@"ArialRoundedMTBold" size:60]}];
        CGSize str_size = [str sizeWithAttributes:@{NSFontAttributeName:[UIFont fontWithName:@"ArialRoundedMTBold" size:60]}];

    
    //    // 1. 先添加小时字符
        CATextLayer * hourLayer = [CATextLayer layer];
        hourLayer.font = fontRef;
        [hourLayer setFontSize:60];
        hourLayer.alignmentMode = kCAAlignmentCenter;
        [hourLayer setForegroundColor:[UIColor whiteColor].CGColor];
        [hourLayer setString:@"00:"];
        [hourLayer setFrame:CGRectMake(size.width / 2 - text_size.width / 2, 20, str_size.width, 60)];
        [bottomLayer addSublayer:hourLayer];
    
    
        // 2. 再添加分钟字符
        CATextLayer * minuteLayer = [CATextLayer layer];
        minuteLayer.font = fontRef;
        [minuteLayer setFontSize:60];
        minuteLayer.alignmentMode = kCAAlignmentCenter;
        [minuteLayer setForegroundColor:[UIColor whiteColor].CGColor];
        [minuteLayer setString:@"00:"];
        [minuteLayer setFrame:CGRectMake(size.width / 2 - text_size.width / 2 + str_size.width, 20, str_size.width, 60)];
        [bottomLayer addSublayer:minuteLayer];
    
        // 3. 再添加秒钟字符
    
        if(hidden){
            
            [bottomLayer addSublayer:hourLayer];
            [bottomLayer addSublayer:minuteLayer];
            CATextLayer * secondLayer = [CATextLayer layer];
            secondLayer.font = fontRef;
            [secondLayer setFontSize:60];
            secondLayer.alignmentMode = kCAAlignmentCenter;
            [secondLayer setForegroundColor:[UIColor whiteColor].CGColor];
            [secondLayer setFrame: CGRectMake(size.width / 2 - text_size.width / 2 + str_size.width * 2 , 20, str_size.width, 60)];
            NSString * second_text = [NSString stringWithFormat:@"%02d",(int)stime];
            [secondLayer setString:second_text];
            [bottomLayer addSublayer:secondLayer];
            
            
        }else{
            
            //         这里先添加一个占位的，因为首次添加会黑屏
            
            if(stime >= self->durationReady && stime <= (self->durationReady + self->durationvalue)){
                CATextLayer * secondLayer = [CATextLayer layer];
                secondLayer.font = fontRef;
                [secondLayer setFontSize:60];
                secondLayer.alignmentMode = kCAAlignmentCenter;
                [secondLayer setForegroundColor:[UIColor whiteColor].CGColor];
                [secondLayer setFrame: CGRectMake(size.width / 2 - text_size.width / 2 + str_size.width * 2 , 20, str_size.width, 60)];
                NSString * second_text = [NSString stringWithFormat:@"%02d.",(int)stime-1];
                [secondLayer setString:second_text];
                [bottomLayer addSublayer:secondLayer];
            }else if (stime < self->durationReady){
                CATextLayer * secondLayer = [CATextLayer layer];
                secondLayer.font = fontRef;
                [secondLayer setFontSize:60];
                secondLayer.alignmentMode = kCAAlignmentCenter;
                [secondLayer setForegroundColor:[UIColor whiteColor].CGColor];
                [secondLayer setFrame: CGRectMake(size.width / 2 - text_size.width / 2 + str_size.width * 2 , 20, str_size.width, 60)];
                NSString * second_text = [NSString stringWithFormat:@"00."];
                [secondLayer setString:second_text];
                [bottomLayer addSublayer:secondLayer];
            }else{
                CATextLayer * secondLayer = [CATextLayer layer];
                secondLayer.font = fontRef;
                [secondLayer setFontSize:60];
                secondLayer.alignmentMode = kCAAlignmentCenter;
                [secondLayer setForegroundColor:[UIColor whiteColor].CGColor];
                [secondLayer setFrame: CGRectMake(size.width / 2 - text_size.width / 2 + str_size.width * 2 , 20, str_size.width, 60)];
                double endtime = (self->durationvalue);
                NSString * timeString = [NSString stringWithFormat:@"%f",endtime];
                NSArray<NSString *> * timeArray = [timeString componentsSeparatedByString:@"."];
                
                NSString * second_text = [NSString stringWithFormat:@"%02d.",[timeArray[0] intValue]];
                [secondLayer setString:second_text];
                [bottomLayer addSublayer:secondLayer];
            }
            
            
            //
            CABasicAnimation *  animation = nil;
            
            CATextLayer * micro_secondLayer = [CATextLayer layer];
            micro_secondLayer.font = fontRef;
            [micro_secondLayer setFontSize:60];
            micro_secondLayer.alignmentMode = kCAAlignmentCenter;
            [micro_secondLayer setForegroundColor:[UIColor whiteColor].CGColor];
            [micro_secondLayer setBackgroundColor:[UIColor clearColor].CGColor];
            [micro_secondLayer setFrame: CGRectMake(size.width / 2 - text_size.width / 2 + str_size.width * 3 , 20, text_size.width - str_size.width * 3, 60)];
            
            NSString * second_text_tmp = [NSString stringWithFormat:@"000"];
            [micro_secondLayer setString:second_text_tmp];

            
            animation = [CABasicAnimation animationWithKeyPath:@"opacity"];
            animation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionDefault];
            [animation setFromValue:[NSNumber numberWithFloat:1.0]];
            [animation setToValue:[NSNumber numberWithFloat:0.0]];
            //        [animation setBeginTime:0.001];
            [animation setDuration:0.001];
            [animation setRemovedOnCompletion:NO];/*must be no*/
            [animation setFillMode:kCAFillModeBoth];
            
            NSLog(@"--------> stime: %f",stime);
            
            NSMutableArray * microvalueArray = [NSMutableArray array];
            NSMutableArray * microtimeArray = [NSMutableArray array];
            // 如果是还未开始时
            if(stime < self->durationReady){
                
                [bottomLayer addSublayer:micro_secondLayer];
            }

                if (stime >= self->durationReady && stime <= (self->durationReady + self->durationvalue)){
                    [bottomLayer addSublayer:micro_secondLayer];
                    int start = (int)(stime * 1000) % 1000 + 1;
                for (int j = start; j < 100+start; j++) {
           
                    UIImage * micro_image = [self createOtherMerchantImage:[NSString stringWithFormat:@"%03d",j] alignment:NSTextAlignmentLeft strFont:60 size:CGSizeMake(text_size.width - str_size.width * 3+10, 50)];
                    [microvalueArray addObject:(__bridge id _Nullable)micro_image.CGImage];
                    [microtimeArray addObject:[NSNumber numberWithFloat:(j-start)*1.0 / 100.0]];
                }
                    CAKeyframeAnimation *  keyAnimation = [CAKeyframeAnimation animationWithKeyPath:@"contents"];
                    keyAnimation.duration = 0.001 * microvalueArray.count;
                    keyAnimation.values = microvalueArray;
                    keyAnimation.keyTimes = microtimeArray;
                    keyAnimation.removedOnCompletion = NO;
                    keyAnimation.fillMode = kCAFillModeBackwards;
                    keyAnimation.beginTime = 0.001;
                    [micro_secondLayer addAnimation:keyAnimation forKey:@"keyAnimation"];
          
                    
                // 如果是刚结束时
            }

            if (stime > self->durationReady + self->durationvalue){
                
                double endtime = (self->durationReady + self->durationvalue);
                NSString * timeString = [NSString stringWithFormat:@"%f",endtime];
                NSArray<NSString *> * timeArray = [timeString componentsSeparatedByString:@"."];
                NSString * second_miro = [timeArray[1] substringToIndex:3];
                [micro_secondLayer setString:second_miro];
                //            [micro_secondLayer addAnimation:animation forKey:@"animateOpacityHiddenAgin"];
                [bottomLayer addSublayer:micro_secondLayer];
            }
            
        }
        
    [bottomLayer addSublayer:bmwLayer];
    [bottomLayer addSublayer:ecuLayer];
    [bottomLayer addSublayer:tcuLayer];
    [bottomLayer addSublayer:valueGearLayer];
    [bottomLayer addSublayer:gearTagLayer];
    [bottomLayer addSublayer:speedLayer];
    [bottomLayer addSublayer:speedTextValueLayer];
    [bottomLayer addSublayer:zendaologoLayer];
    [bottomLayer addSublayer:gurbineLayer];
    [bottomLayer addSublayer:gurbineValueLayer];
    [bottomLayer addSublayer:speedtagLayer];
    [bottomLayer addSublayer:speedtagValueLayer];
    [bottomLayer addSublayer:ghrottleLayer];
    [bottomLayer addSublayer:ghrottleValueLayer];
    [bottomLayer addSublayer:turbineprogressLayer];
    [bottomLayer addSublayer:speedprogressLayer];
    [bottomLayer addSublayer:throttleprogresslayer];
    [bottomLayer addSublayer:turbineiconLayer];
    [bottomLayer addSublayer:speediconLayer];
    [bottomLayer addSublayer:throttleiconLayer];
    
    return bottomLayer;
}
-(UIImage *)createProgressView:(float)progress color:(UIColor*)color size:(CGSize)size {
    
    size = CGSizeMake(size.width/2, size.height/2);
    
    UIGraphicsBeginImageContextWithOptions(size, NO, 0.0);

    CGContextRef context = UIGraphicsGetCurrentContext();

    UIBezierPath *path = [UIBezierPath bezierPathWithRect:CGRectMake(0, 0, size.width*progress, size.height)];

    //CGContextSetFillColorWithColor(context, colorArr[lastNum].CGColor);
        CGContextSetFillColorWithColor(context, color.CGColor);
    [path fill];

    UIImage *resultImg = UIGraphicsGetImageFromCurrentImageContext();

    UIGraphicsEndImageContext();

    return resultImg;
}
- (UIImage *)createOtherMerchantImage:(NSString *)str alignment:(NSTextAlignment)alignment strFont:(CGFloat)fontsize  size:(CGSize)size{
    
    NSDictionary * fontAttributes = @{
            NSFontAttributeName:[UIFont boldSystemFontOfSize:fontsize],//设置文字的字体
            NSForegroundColorAttributeName: [UIColor whiteColor]
    };

    CGSize textSize = [str sizeWithAttributes:fontAttributes];

    CGPoint drawPoint = CGPointMake((size.width - textSize.width)/2, (size.height - textSize.height)/2);
    if(alignment == NSTextAlignmentLeft){
        drawPoint = CGPointMake(0, (size.height - textSize.height)/2);
    }
    if(alignment == NSTextAlignmentRight){
        drawPoint = CGPointMake(size.width - textSize.width, (size.height - textSize.height)/2);
    }

//    UIGraphicsBeginImageContextWithOptions(size, NO, 1.0);
    UIGraphicsBeginImageContext(size);
    CGContextRef context = UIGraphicsGetCurrentContext();

    UIBezierPath *path = [UIBezierPath bezierPathWithRect:CGRectMake(0, 0, size.width, size.height)];

    //CGContextSetFillColorWithColor(context, colorArr[lastNum].CGColor);
        CGContextSetFillColorWithColor(context, [UIColor clearColor].CGColor);

    [path fill];

    [str drawAtPoint:drawPoint withAttributes:fontAttributes];

    UIImage *resultImg = UIGraphicsGetImageFromCurrentImageContext();

    UIGraphicsEndImageContext();

return resultImg;

}
-(int)speedTransferSero:(int)sero shudu:(int)shudu {
    
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
    return speed;
}
#pragma mark CorAnimation
- (void)addVideoMarkVideoPath:(NSString *)videoPath  WithCompletionHandler:(void (^)(NSURL* outPutURL, int code))handler{
    
    videoPath = [videoPath stringByReplacingOccurrencesOfString:@"_completed" withString:@"_origin"];
    NSArray<NSString *> * pathArray = [videoPath componentsSeparatedByString:@"."];
    
    NSString * outputPath = [videoPath stringByReplacingOccurrencesOfString:@"_origin" withString:@"_completed"];
    
    NSURL * videoUrl = [NSURL fileURLWithPath:videoPath];
    AVAsset * videoAsset = [AVAsset assetWithURL:videoUrl];
    __block CMTime videoTime = videoAsset.duration;
    // 为了处理视频首和尾部的黑边，所以这里从 0.2s处开始剪，因为时间转换的问题，没有匹配到时间就会出现黑边，结尾就少处理一个部分
//    __block CMTime  startTime = kCMTimeZero;
    __block CMTime  startTime = CMTimeMake(videoTime.timescale * 1 / 10, videoTime.timescale);
//    __block CMTime durTime = CMTimeMake(videoTime.timescale, videoTime.timescale);
    __block  CMTime  durTime = CMTimeMake(videoTime.timescale * 1 / 10, videoTime.timescale);
    
    NSLog(@"videoTime.value: %lld,videoTime.timescale: %d",startTime.value,startTime.timescale);
    //   这里先释放t信号量
    if(t){
        dispatch_semaphore_signal(t);
        t = nil;
    }
    t = dispatch_semaphore_create(1);
    dispatch_semaphore_wait(self->t, DISPATCH_TIME_FOREVER);
    __block NSURL * fileoutputUrl = [NSURL fileURLWithPath:outputPath];
    __block bool isLastPackage = false;
    __block NSURL * inputUrl = videoUrl;
    
    //    [self addTimerLabelWithCompleteAssetUrl:inputUrl];
    //    return;
    
    //    avassetExportArray = [NSMutableArray array];
    
    NSString * txtPath = [videoPath stringByReplacingOccurrencesOfString:@"_origin.mp4" withString:@".txt"];
    txtPath = [txtPath stringByReplacingOccurrencesOfString:@"%20" withString:@" "];
    
    //    txtPath = [[NSBundle mainBundle] pathForResource:@"29-05-2023 14:09" ofType:@"txt"];
    fileHandler = [NSFileHandle fileHandleForReadingAtPath:txtPath];
    [fileHandler seekToEndOfFile];
    [fileHandler seekToFileOffset:fileHandler.offsetInFile-24];
    // 前三个字符存储的是分支 [1]  总共三人字符
    NSData * prefixData = [fileHandler readDataOfLength:24];
    NSString * prefixSero = [[NSString alloc] initWithData:prefixData encoding:NSUTF8StringEncoding];
    prefixSero = [prefixSero stringByReplacingOccurrencesOfString:@"[" withString:@""];
    prefixSero = [prefixSero stringByReplacingOccurrencesOfString:@"]" withString:@""];
    stringSero = [prefixSero componentsSeparatedByString:@","];
    sero = [stringSero[0] intValue];
    durationReady = [stringSero[1] floatValue];
    startvalue = [stringSero[2] floatValue];
    durationvalue = [stringSero[3] floatValue];
  //  int sero = [stringSero[0] intValue];
    //    [fileHandler closeFile];
    //    fileHandler = [NSFileHandle fileHandleForReadingAtPath:txtPath];
    [fileHandler seekToFileOffset:0];
    
    youmen = 0;
    sudu = 0;
    dangwei = 0;
    wolun = 0;
    zhuanshu = 0;
//    __block int count = (int)(videoTime.value / videoTime.timescale);
//    if(videoTime.timescale * count < videoTime.value){
//        count ++;
//    }
    __block int count = CMTimeGetSeconds(videoTime) * 10;
    // 为了处理开始和结束的黑边，这里做一下处理
//    count--;
//    if( count * 1.0 < CMTimeGetSeconds(videoTime) * 10.0){
//        count ++;
//    }
    //   总的进度数 包含了将视频总共的视频段+最后进行合成的时间
    
        NSData * data = [fileHandler readDataOfLength:41];

        NSString * itemString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        //            NSLog(@"itemString: %@",itemString);
        itemString = [itemString stringByReplacingOccurrencesOfString:@"[" withString:@""];
        itemString = [itemString stringByReplacingOccurrencesOfString:@"]" withString:@""];
        itemString = [itemString stringByReplacingOccurrencesOfString:@" " withString:@""];
        NSArray<NSString *> * valueArray = [itemString componentsSeparatedByString:@":"];
        NSString * timestampString = [valueArray objectAtIndex:0];
        double time = [timestampString doubleValue];
        
        speedStartTimeStamp = time;
        [fileHandler seekToFileOffset:fileHandler.offsetInFile-41];

   
//    }
    
    // 这里需要先判断开始加速的时间是否大于1s
    if(durationReady > 1.0){
        //        durationReady = 1.0;
        //        startvalue = durationReady + durationvalue;
//
        double start_time = durationReady - 1.0;
        int end = (start_time * 1000);
        double timestamp = 0;
        int to_end = true;
        while (to_end) {
            NSData * data = [fileHandler readDataOfLength:41];
            if(data.length > 0){
                NSString * itemString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
                //            NSLog(@"itemString: %@",itemString);
                itemString = [itemString stringByReplacingOccurrencesOfString:@"[" withString:@""];
                itemString = [itemString stringByReplacingOccurrencesOfString:@"]" withString:@""];
                itemString = [itemString stringByReplacingOccurrencesOfString:@" " withString:@""];
                NSArray<NSString *> * valueArray = [itemString componentsSeparatedByString:@":"];
                NSString * timestampString = [valueArray objectAtIndex:0];
//                NSString * youmenString = [valueArray objectAtIndex:1];
             //   NSString * suduString = [valueArray objectAtIndex:2];
//                NSString * dangweiString = [valueArray objectAtIndex:3];
//                NSString * wolunString = [valueArray objectAtIndex:4];
//                NSString * zhuanshuString = [valueArray objectAtIndex:5];
                double time = [timestampString doubleValue];


//                speedStartTimeStamp = time;
//                to_end = false;

                if(timestamp == 0){
                    timestamp = time;
                }
             //   NSLog(@"--------->  time - timestamp: %lf,suduString: %@",(time - timestamp),suduString);
                if(time - timestamp >= end){
                //    NSLog(@"-------->  >= end sudu: %@",suduString);
                    [fileHandler seekToFileOffset:fileHandler.offsetInFile-41];
                    speedStartTimeStamp = time;
                    to_end = false;
                }
            }else{
                break;
            }

        }
   
        NSString * origin_repare_path = [inputUrl.absoluteString stringByReplacingOccurrencesOfString:@"_origin" withString:@"_origin_repare"];
        //        origin_repare_path = [origin_repare_path stringByReplacingOccurrencesOfString:@"%20" withString:@" "];
        //        origin_repare_path = [origin_repare_path stringByReplacingOccurrencesOfString:@"file://" withString:@""];
        NSURL *  outputUrl = [NSURL URLWithString:origin_repare_path];
        [self seaprVideoWithVideoPath:inputUrl outputUrl:outputUrl doneBlock:^{
            self->durationReady = 1.0;
            self->startvalue = self->durationReady + self->durationvalue;
            
            AVAsset * asset = [AVAsset assetWithURL:outputUrl];
//            count = (int)(asset.duration.value / asset.duration.timescale);
            videoTime = asset.duration;
//            if(asset.duration.timescale * count < asset.duration.value){
//                count ++;
//            }
            count = CMTimeGetSeconds(asset.duration) * 10;
//            if(count * 1.0  < CMTimeGetSeconds(asset.duration) * 10.0){
//                count++;
//            }
            startTime = kCMTimeZero;
            self->count_progress = (count + 1) * 1.0;
            self->progress = 0;
            inputUrl = outputUrl;
            dispatch_semaphore_signal(self->t);
        }];
      
        dispatch_semaphore_wait(self->t, DISPATCH_TIME_FOREVER);
    }else{
        
        NSData * data = [fileHandler readDataOfLength:41];
        if(data.length > 0){
            NSString * itemString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
            //            NSLog(@"itemString: %@",itemString);
            itemString = [itemString stringByReplacingOccurrencesOfString:@"[" withString:@""];
            itemString = [itemString stringByReplacingOccurrencesOfString:@"]" withString:@""];
            itemString = [itemString stringByReplacingOccurrencesOfString:@" " withString:@""];
            NSArray<NSString *> * valueArray = [itemString componentsSeparatedByString:@":"];
            NSString * timestampString = [valueArray objectAtIndex:0];
            double time = [timestampString doubleValue];
            [fileHandler seekToFileOffset:fileHandler.offsetInFile-41];
            speedStartTimeStamp = time;

        }
        count_progress = (count + 1) * 1.0;
        progress = 0;
    }
    
    //    self->timer = [NSTimer scheduledTimerWithTimeInterval:0.001 target:self selector:@selector(funcTimer) userInfo:nil repeats:YES];
    __block bool end = false;
    for (int i = 1; i <= count; i ++) {
        NSLog(@"i: %d",i);
//        if(end)break;
        
        
        NSLog(@"------------->  i: %d startTime.value: %lld , startTime.timeScale: %d,starttime.second: %f",i,startTime.value,startTime.timescale,CMTimeGetSeconds(startTime));
        
        NSString * videoPathcompon = [NSString stringWithFormat:@"%@_%d.%@",pathArray.firstObject,i,pathArray.lastObject];
        NSURL * videoPathcomnUrl = [NSURL fileURLWithPath:videoPathcompon];
        [self CompositionaddWaterMarkTypeWithCorAnimationAndInputVideoURL:inputUrl outputUrl:videoPathcomnUrl startTime:startTime durationTime:durTime seroString:sero  WithCompletionHandler:^(NSURL* outPutURL, int code){
            NSLog(@"outputurl: %@",outPutURL);
             NSFileManager * fm = [NSFileManager defaultManager];
            NSString * documentPath = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)[0];
            NSString * moviePath = [documentPath stringByAppendingPathComponent:@"Movie"];
            bool hidden = [[NSUserDefaults standardUserDefaults] boolForKey:@"videoexport"];
            if(hidden){
                moviePath = [documentPath stringByAppendingPathComponent:@"Racing"];
            }
            if(![fm fileExistsAtPath:moviePath]){
                [fm createDirectoryAtPath:moviePath withIntermediateDirectories:YES attributes:nil error:nil];
            }
            
            startTime = CMTimeMake(startTime.value + videoTime.timescale * 1 / 10 , videoTime.timescale);
//            startTime = CMTimeMake(startTime.value + videoTime.timescale , videoTime.timescale);
           // NSArray<NSString *> * files = [fm contentsOfDirectoryAtPath:moviePath error:nil];
           // NSLog(@"视频合成中，目录内文件  : %@",files);
            if(startTime.value >= videoTime.value){
//                dispatch_semaphore_signal(self->t);
              //  end = true;
            }
            if(end == false){
                if((startTime.value + (videoTime.timescale * 1 / 10)) >= videoTime.value){
                    isLastPackage = true;
                    //                startTime = CMTimeMake(videoTime.value - startTime.value, videoTime.timescale);
                    durTime = CMTimeMake(videoTime.value - startTime.value, videoTime.timescale);
                }else{
                    //                startTime = CMTimeMake(startTime.value + videoTime.timescale , videoTime.timescale);
                }
                
                NSLog(@"i: %d , starttime.value: %lld, starttime.timescale %d",i,startTime.value,startTime.timescale);
                dispatch_semaphore_signal(self->t);
            }
        }];
        NSLog(@"------------i: %d",i);
        dispatch_semaphore_wait(self->t,DISPATCH_TIME_FOREVER);
    }
    NSLog(@"==================================================================");
    
    if(t){
        dispatch_semaphore_signal(t);
        t = nil;
    }
    //    [self addAllVideoSegmentsWithOriginVideoName:videoPath.lastPathComponent];
    
    NSLog(@"----------------合成完毕--------------------------");
    handler(fileoutputUrl,100);
    
}
- (void)CompositionaddWaterMarkTypeWithCorAnimationAndInputVideoURL:(NSURL*)InputURL outputUrl:(NSURL *)outputUrl startTime:(CMTime)sTime  durationTime:(CMTime)dTime seroString:(int)sero WithCompletionHandler:(void (^)(NSURL* outPutURL, int code))handler{
    NSLog(@"inputUrl: %@",InputURL);
    //    NSDictionary *opts = [NSDictionary dictionaryWithObject:@(YES) forKey:AVURLAssetPreferPreciseDurationAndTimingKey];
    __block AVAsset *videoAsset = [AVURLAsset assetWithURL:InputURL];
    __block  AVMutableComposition *mixComposition = [[AVMutableComposition alloc] init];
    __block AVMutableCompositionTrack *videoTrack = [mixComposition addMutableTrackWithMediaType:AVMediaTypeVideo
                                                                        preferredTrackID:kCMPersistentTrackID_Invalid];
    NSError *errorVideo;
   __block  AVAssetTrack *assetVideoTrack = [[videoAsset tracksWithMediaType:AVMediaTypeVideo]firstObject];
    //    CMTime endTime = assetVideoTrack.asset.duration;
    NSLog(@"stime.value: %lld,stime.timescale: %d",sTime.value,sTime.timescale);
    BOOL bl = [videoTrack insertTimeRange:CMTimeRangeMake(sTime, dTime)
                                  ofTrack:assetVideoTrack
                                   atTime:kCMTimeInvalid error:&errorVideo];
    NSLog(@"insertTimer: b1: %d Error %@",bl,errorVideo);
    
   __block  AVMutableCompositionTrack *audioTrack = [mixComposition addMutableTrackWithMediaType:AVMediaTypeAudio preferredTrackID:kCMPersistentTrackID_Invalid];
    
    NSError * error = nil;
    //    CMTime audioTime = videoAsset.duration;
    BOOL bd = [audioTrack insertTimeRange:CMTimeRangeMake(sTime, dTime) ofTrack: [[videoAsset tracksWithMediaType:AVMediaTypeAudio]firstObject] atTime:kCMTimeInvalid error:&error];
    //
    
    videoTrack.preferredTransform = assetVideoTrack.preferredTransform;
    NSLog(@"errorVideo bd: %d  error: %@",bd,error);
    
    
    //    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    //    NSString *documentsDirectory = [paths objectAtIndex:0];
    //    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    //    formatter.dateFormat = @"yyyyMMddHHmmss";
    //    NSString *outPutFileName = [formatter stringFromDate:[NSDate dateWithTimeIntervalSinceNow:0]];
    //    NSString *myPathDocs =  [documentsDirectory stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.mp4",outPutFileName]];
    //  @"_completed" withString:@"_origin"
    //    NSString * outputfileurl = [InputURL.absoluteString stringByReplacingOccurrencesOfString:@"_origin" withString:@"_completed"];
    //    NSURL* outPutVideoUrl = [NSURL URLWithString:outputfileurl];
    
//    CGSize videoSize = [videoTrack naturalSize];
    CGSize videoSize = [assetVideoTrack naturalSize];
    
    NSLog(@"videoSize.width: %lf,videoSize.height: %lf",videoSize.width,videoSize.height);
    
    __block  CALayer *parentLayer = [CALayer layer];
    __block  CALayer *videoLayer = [CALayer layer];
    parentLayer.frame = CGRectMake(0, 0, videoSize.width, videoSize.height);
    videoLayer.frame = CGRectMake(0, 0, videoSize.width, videoSize.height);
    [parentLayer addSublayer:videoLayer];
    
    // 首先添加 顶部的layer
    __block CALayer * topLayer = [self addTopLayerWithVideoSize:videoSize];
    //    topLayer.frame = CGRectMake(0, 0, videoSize.width, 40);
    
    NSString * txtPath = [InputURL.absoluteString stringByReplacingOccurrencesOfString:@"_origin_repare.mp4" withString:@".txt"];
    txtPath = [txtPath stringByReplacingOccurrencesOfString:@"_origin.mp4" withString:@".txt"];
    txtPath = [txtPath stringByReplacingOccurrencesOfString:@"file://" withString:@""];
    txtPath = [txtPath stringByReplacingOccurrencesOfString:@"%20" withString:@" "];
    NSLog(@"add watermark txtpath: %@",txtPath);
    
    // 再添加底部的 layer
    __block CALayer * bottomLayer = [self addBottomLayerWithVideoSize:videoSize starttime:CMTimeGetSeconds(sTime) endtime:CMTimeGetSeconds(dTime) seroString:sero  txtFilePath:txtPath];

    [parentLayer addSublayer:topLayer];
    [parentLayer addSublayer:bottomLayer];

    
    __block CALayer * logoLayer = [CALayer layer];
    [logoLayer setFrame:CGRectMake(videoSize.width - 260, 120, 200, 58)];
    //    logo1Layer.backgroundColor = [UIColor orangeColor].CGColor;
    logoLayer.contents = (id)[UIImage imageNamed:@"99"].CGImage;
    
    [parentLayer addSublayer:logoLayer];
    
    __block AVMutableVideoComposition* videoComp = [AVMutableVideoComposition videoComposition];
    videoComp.renderSize = videoSize;
    parentLayer.geometryFlipped = true;
    videoComp.frameDuration = CMTimeMake(1, 30);
    videoComp.animationTool = [AVVideoCompositionCoreAnimationTool videoCompositionCoreAnimationToolWithPostProcessingAsVideoLayer:videoLayer inLayer:parentLayer];
    __block AVMutableVideoCompositionInstruction* instruction = [AVMutableVideoCompositionInstruction videoCompositionInstruction];

    instruction.timeRange = CMTimeRangeMake(kCMTimeZero, dTime);
    AVMutableVideoCompositionLayerInstruction* layerInstruction = [AVMutableVideoCompositionLayerInstruction videoCompositionLayerInstructionWithAssetTrack:videoTrack];
    instruction.layerInstructions = [NSArray arrayWithObjects:layerInstruction, nil];
    

    videoComp.instructions = [NSArray arrayWithObjects: instruction,nil];
    
    
    __block AVAssetExportSession* exporter = [[AVAssetExportSession alloc] initWithAsset:mixComposition
                                                                      presetName:AVAssetExportPresetHighestQuality];
    exporter.outputURL=outputUrl;
    exporter.outputFileType = AVFileTypeMPEG4;
    exporter.shouldOptimizeForNetworkUse = YES;
    exporter.videoComposition = videoComp;

    [exporter exportAsynchronouslyWithCompletionHandler:^{
        NSLog(@"=========================");
        //        dispatch_async(dispatch_get_main_queue(), ^{
        //这里是输出视频之后的操作，做你想做的
        NSLog(@"输出视频地址:%@ andCode:%@",outputUrl,exporter.error);
        handler(outputUrl,(int)exporter.error.code);
        
        CGFloat count_current = 1.0;
        
        CGFloat current_progress  = count_current + self->progress;
        
        if(count_current >= 1.0){
            self->progress += count_current;
        }
        CGFloat progress_file = current_progress / self->count_progress;
        NSDictionary * data = @{progress_count:@(self->count_progress),prgress_video:@(progress_file)};
        if(progress_file >= 1.0){
            dispatch_async(dispatch_get_main_queue(), ^{
                [[NSNotificationCenter defaultCenter] postNotificationName:recv_video_progress_done_notify_name object:nil userInfo:data];
            });
            
            NSLog(@"合成进度完成: %f",progress_file);
        }else{
            dispatch_async(dispatch_get_main_queue(), ^{
                [[NSNotificationCenter defaultCenter] postNotificationName:recv_video_progress_notify_name object:nil userInfo:data];
            });

            
            NSLog(@"视频合成中: %f",progress_file);
        }
    }];
}
// 判断视频大于1s 就进行分隔
-(void)seaprVideoWithVideoPath:(NSURL *) videoUrl outputUrl:(NSURL *)outputUrl doneBlock:(void(^)(void))doneBlock{
    
    AVAsset * asset = [AVAsset assetWithURL:videoUrl];
    

    AVAssetExportSession* exporter = [[AVAssetExportSession alloc] initWithAsset:asset
                                                                      presetName:AVAssetExportPresetPassthrough];
    exporter.outputURL=outputUrl;

    exporter.outputFileType = AVFileTypeMPEG4;
    exporter.shouldOptimizeForNetworkUse = YES;
    CMTime startTime = CMTimeMakeWithSeconds(durationReady - 1.0, asset.duration.timescale);
    CMTime durationTime = CMTimeMakeWithSeconds(CMTimeGetSeconds(asset.duration) - (durationReady - 1.0) - 0.2, asset.duration.timescale);
    exporter.timeRange = CMTimeRangeMake(startTime, durationTime);
    [exporter exportAsynchronouslyWithCompletionHandler:^{
        NSLog(@"=========================");
        //        dispatch_async(dispatch_get_main_queue(), ^{
        //这里是输出视频之后的操作，做你想做的
        NSLog(@"对视频进行剪切后输出视频地址:%@ andCode:%@",outputUrl,exporter.error);
        doneBlock();

    }];
    
}
-(void)addAllVideoSegmentsWithOriginVideoName:(NSString *)name{
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentDirectory = paths.firstObject;
    //    NSString *saveFilePath = [documentDirectory stringByAppendingPathComponent:fileName];
    NSString * moviepath = [documentDirectory stringByAppendingPathComponent:@"Movie"];
    
    BOOL hidden = [[NSUserDefaults standardUserDefaults] boolForKey:@"videoexport"];
    if(hidden){
        moviepath = [documentDirectory stringByAppendingPathComponent:@"Racing"];
    }
    
    NSFileManager * fm = [NSFileManager defaultManager];
    NSArray<NSString *> * files = [fm contentsOfDirectoryAtPath:moviepath error:nil];
    
    // 这里对name进入处理
    NSArray<NSString *> * fileArray = [name componentsSeparatedByString:@"."];
    NSString * videoPrefixString = fileArray.firstObject;
    
    NSMutableArray * mutableArray = [NSMutableArray array];
    for (NSString * fileName in files) {
        if(![fileName hasSuffix:@"_origin.mp4"] && ![fileName hasSuffix:@".txt"] && [fileName hasPrefix:videoPrefixString] && ![fileName hasSuffix:@"_origin_repare.mp4"]){
            [mutableArray addObject:fileName];
        }
        
    }
    files = [mutableArray sortedArrayUsingComparator:^(id obj1,id obj2){
        NSString * str1 = (NSString *)obj1;
        NSString * str2 = (NSString *)obj2;
        
        NSString * str3 = [NSString stringWithString:str1];
        NSString * str4 = [NSString stringWithString:str2];
        str3 = [str3 stringByReplacingOccurrencesOfString:videoPrefixString withString:@""];
        str3 = [str3 stringByReplacingOccurrencesOfString:@"_" withString:@""];
        str3 = [str3 stringByReplacingOccurrencesOfString:@".mp4" withString:@""];
        
        
        str4 = [str4 stringByReplacingOccurrencesOfString:videoPrefixString withString:@""];
        str4 = [str4 stringByReplacingOccurrencesOfString:@"_" withString:@""];
        str4 = [str4 stringByReplacingOccurrencesOfString:@".mp4" withString:@""];
        
        int value1 = [str3 intValue];
        int value2 = [str4 intValue];
        if(value1 >= value2){
            return NSOrderedDescending;
        }
        return NSOrderedAscending;
    }];
    

    AVMutableComposition *mixComposition = [[AVMutableComposition alloc] init];
    
    
    //   向混合单元中添加一条视频
    AVMutableCompositionTrack *videoTrack = [mixComposition addMutableTrackWithMediaType:AVMediaTypeVideo
                                                                        preferredTrackID:kCMPersistentTrackID_Invalid];
    //   向混合单元中添加一条音频
    AVMutableCompositionTrack *audioTrack = [mixComposition addMutableTrackWithMediaType:AVMediaTypeAudio preferredTrackID:kCMPersistentTrackID_Invalid];
    CMTime startTime = kCMTimeZero;
    CMTime durationTime = kCMTimeZero;
    
    NSLog(@"files: %@",files);

    for (NSString * file in files) {

      
        AVAsset * avAsset = [AVAsset assetWithURL:[NSURL fileURLWithPath:[moviepath stringByAppendingPathComponent:file]]];
        NSError *errorVideo;
        AVAssetTrack *assetVideoTrack = [[avAsset tracksWithMediaType:AVMediaTypeVideo]firstObject];
        //    CMTime endTime = assetVideoTrack.asset.duration;
        BOOL bl = [videoTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, avAsset.duration)
                                      ofTrack:assetVideoTrack
                                       atTime:startTime error:&errorVideo];
        NSLog(@"insertTimer: b1: %d Error %@",bl,errorVideo);
        
        
        NSLog(@" video file: %@  duration: %f",file,CMTimeGetSeconds(avAsset.duration));
        NSError * error = nil;
        //        CMTime audioTime = avAsset.duration;
        BOOL bd = [audioTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, avAsset.duration) ofTrack: [[avAsset tracksWithMediaType:AVMediaTypeAudio]firstObject] atTime:startTime error:&error];
        
        NSLog(@"errorVideo bd: %d  error: %@",bd,error);
        
        durationTime =  CMTimeAdd(durationTime, avAsset.duration);
        NSLog(@" value: %lld   timescale: %d  startTime.value: %lld, startTime.timeScale: %d durationTime.value: %lld , durationTime.timeScale: %d ",avAsset.duration.value,avAsset.duration.timescale,startTime.value,startTime.timescale,durationTime.value,durationTime.timescale);
        startTime = CMTimeAdd(startTime, avAsset.duration);

    }
    

    CGSize videoSize = [videoTrack naturalSize];
//    CGSize videoSize = CGSizeMake(1280, 720);
    
    NSLog(@"------------------->  videoSize.width: %lf,videoSize.height: %lf",videoSize.width,videoSize.height);
    
    CALayer *parentLayer = [CALayer layer];
    CALayer *videoLayer = [CALayer layer];
    parentLayer.frame = CGRectMake(0, 0, videoSize.width, videoSize.height);
    videoLayer.frame = CGRectMake(0, 0, videoSize.width, videoSize.height);
    
    // 添加计时标签
    // 分支，开始计时时间起点(ready标签持续时间)，达到100km/h时在视频中的时间点，总共耗时
    [fileHandler seekToEndOfFile];
    [fileHandler seekToFileOffset:fileHandler.offsetInFile-24];
    NSData * data = [fileHandler readDataOfLength:24];
    NSString * timeString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    timeString = [timeString stringByReplacingOccurrencesOfString:@"[" withString:@""];
    timeString = [timeString stringByReplacingOccurrencesOfString:@"]" withString:@""];
    NSString * durationStr = [NSString stringWithFormat:@"%.3f s",durationvalue];
    [fileHandler closeFile];
    
    CATextLayer * readyLayer = [CATextLayer layer];
    [readyLayer setFontSize:150];
    [readyLayer setForegroundColor:[UIColor whiteColor].CGColor];
    [readyLayer setBackgroundColor:[UIColor clearColor].CGColor];
    [readyLayer setAlignmentMode:kCAAlignmentCenter];
    [readyLayer setContentsGravity:kCAGravityCenter];
    [readyLayer setString:@"READY"];
    [readyLayer setFrame:CGRectMake(videoSize.width/2- 400, videoSize.height/2 - 100, 800, 200)];
    
    
    CABasicAnimation *  animation = nil;

    animation = nil;
    animation = [CABasicAnimation animationWithKeyPath:@"opacity"];
    animation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionDefault];
    [animation setFromValue:[NSNumber numberWithFloat:1]];
    [animation setToValue:[NSNumber numberWithFloat:0]];
    [animation setBeginTime:durationReady];
    [animation setDuration:0.001];
    [animation setFillMode:kCAFillModeForwards];/*must be backwards*/
    [animation setRemovedOnCompletion:NO];/*must be no*/
    [readyLayer addAnimation:animation forKey:@"animation"];
    
    
    CATextLayer * timeLayer = [CATextLayer layer];
    [timeLayer setFontSize:150];
    [timeLayer setForegroundColor:[UIColor whiteColor].CGColor];
    [timeLayer setBackgroundColor:[UIColor clearColor].CGColor];
    [timeLayer setAlignmentMode:kCAAlignmentCenter];
    [timeLayer setContentsGravity:kCAGravityCenter];
    [timeLayer setString:durationStr];
    [timeLayer setFrame:CGRectMake(videoSize.width/2- 400, videoSize.height/2 - 100, 800, 200)];
    
    CABasicAnimation *  animation1 = nil;
    animation1 = [CABasicAnimation animationWithKeyPath:@"opacity"];
    animation1.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionDefault];
    [animation1 setFromValue:[NSNumber numberWithFloat:0]];
    [animation1 setToValue:[NSNumber numberWithFloat:1]];
    [animation1 setBeginTime:durationReady+durationvalue-0.2];
    [animation1 setDuration:0.01];
    [animation1 setFillMode:kCAFillModeBackwards];/*must be backwards*/
    [animation1 setRemovedOnCompletion:NO];/*must be no*/
    [timeLayer addAnimation:animation1 forKey:@"animation"];
    
    if(sero >= 10){
        
    }else{
        
        [videoLayer addSublayer:readyLayer];
        [videoLayer addSublayer:timeLayer];
    }

    [parentLayer addSublayer:videoLayer];
    
    AVMutableVideoComposition* videoComp = [AVMutableVideoComposition videoComposition];
    videoComp.renderSize = videoSize;
    parentLayer.geometryFlipped = true;
    videoComp.frameDuration = CMTimeMake(1, 30);
    videoComp.animationTool = [AVVideoCompositionCoreAnimationTool videoCompositionCoreAnimationToolWithPostProcessingAsVideoLayer:videoLayer inLayer:parentLayer];
    AVMutableVideoCompositionInstruction* instruction = [AVMutableVideoCompositionInstruction videoCompositionInstruction];
    

    instruction.timeRange = CMTimeRangeMake(kCMTimeZero, durationTime);
    AVMutableVideoCompositionLayerInstruction* layerInstruction = [AVMutableVideoCompositionLayerInstruction videoCompositionLayerInstructionWithAssetTrack:videoTrack];
    instruction.layerInstructions = [NSArray arrayWithObjects:layerInstruction, nil];

    videoComp.instructions = [NSArray arrayWithObjects: instruction,nil];
    
    NSString * outputpath = [moviepath stringByAppendingPathComponent:[name stringByReplacingOccurrencesOfString:@"_origin" withString:@"_completed"]];
    NSURL * outputUrl = [NSURL fileURLWithPath:outputpath];
    
    AVAssetExportSession* exporter = [[AVAssetExportSession alloc] initWithAsset:mixComposition
                                                                      presetName:AVAssetExportPresetHighestQuality];
    exporter.outputURL=outputUrl;

    exporter.outputFileType = AVFileTypeMPEG4;
    exporter.shouldOptimizeForNetworkUse = YES;
    exporter.videoComposition = videoComp;
    [exporter exportAsynchronouslyWithCompletionHandler:^{
        NSLog(@"=========================");
        //这里是输出视频之后的操作，做你想做的
        NSLog(@"将视频拼接后输出视频地址:%@ andCode:%@",outputUrl,exporter.error);

        CGFloat count_current = 1.0;
        
        CGFloat current_progress  = count_current + self->progress;
        
        if(count_current >= 1.0){
            self->progress += count_current;
        }
        
        CGFloat progress_file = current_progress / self->count_progress;
        NSDictionary * data = @{progress_count:@(self->count_progress),prgress_video:@(progress_file)};
        if(progress_file >= 1.0){
            dispatch_async(dispatch_get_main_queue(), ^{
                [[NSNotificationCenter defaultCenter] postNotificationName:recv_video_progress_done_notify_name object:nil userInfo:data];
            });

            NSLog(@"合成进度完成: %f",progress_file);
        }else{
            dispatch_async(dispatch_get_main_queue(), ^{
                [[NSNotificationCenter defaultCenter] postNotificationName:recv_video_progress_notify_name object:nil userInfo:data];
            });
       
            NSLog(@"视频合成中: %f",progress_file);
        }
        
    }];
}

// 导出视频分步加入计时器
-(void)addTimerLabelWithCompleteAssetUrl:(NSURL *) fileUrl {
    
    NSLog(@"添加倒计时标签方法");
    
    NSString * txtPath = [fileUrl.absoluteString stringByReplacingOccurrencesOfString:@"_completed_time.mp4" withString:@".txt"];
    txtPath = [txtPath stringByReplacingOccurrencesOfString:@"%20" withString:@" "];
    txtPath = [txtPath stringByReplacingOccurrencesOfString:@"file://" withString:@""];
    
    //    txtPath = [[NSBundle mainBundle] pathForResource:@"29-05-2023 14:09" ofType:@"txt"];
    fileHandler = [NSFileHandle fileHandleForReadingAtPath:txtPath];
    [fileHandler seekToEndOfFile];
    [fileHandler seekToFileOffset:fileHandler.offsetInFile-24];
    // 前三个字符存储的是分支 [1]  总共三人字符
    NSData * prefixData = [fileHandler readDataOfLength:24];
    NSString * prefixSero = [[NSString alloc] initWithData:prefixData encoding:NSUTF8StringEncoding];
    prefixSero = [prefixSero stringByReplacingOccurrencesOfString:@"[" withString:@""];
    prefixSero = [prefixSero stringByReplacingOccurrencesOfString:@"]" withString:@""];
    stringSero = [prefixSero componentsSeparatedByString:@","];
    durationReady = [stringSero[1] floatValue];
    startvalue = [stringSero[2] floatValue];
    durationvalue = [stringSero[3] floatValue];
    
    durationReady = 1;
//    startvalue = 23;
    durationvalue = 20;
    
    AVAsset * videoAsset = [AVAsset assetWithURL:fileUrl];
    
    NSLog(@"videoasset.duration: %f",CMTimeGetSeconds(videoAsset.duration));
    
    AVAssetTrack * track = [videoAsset tracksWithMediaType:AVMediaTypeVideo].firstObject;
    
    CGSize videoSize = track.naturalSize;
    
    
    CALayer *parentLayer = [CALayer layer];
    CALayer *videoLayer = [CALayer layer];
    parentLayer.frame = CGRectMake(0, 0, videoSize.width, videoSize.height);
    videoLayer.frame = CGRectMake(0, 0, videoSize.width, videoSize.height);
    
    NSString * m_str = @"00:00:00.001";
    NSString * str = @"00:";
    CGSize text_size = [m_str sizeWithAttributes:@{NSFontAttributeName:[UIFont systemFontOfSize:60]}];
    CGSize str_size = [str sizeWithAttributes:@{NSFontAttributeName:[UIFont systemFontOfSize:60]}];
    
    // 1. 先添加小时字符
    CATextLayer * hourLayer = [CATextLayer layer];
    [hourLayer setFontSize:60];
    hourLayer.alignmentMode = kCAAlignmentCenter;
    [hourLayer setForegroundColor:[UIColor whiteColor].CGColor];
    [hourLayer setString:@"00:"];
    [hourLayer setFrame:CGRectMake(videoSize.width / 2 - text_size.width / 2, videoSize.height-160, str_size.width, 60)];
    [parentLayer addSublayer:hourLayer];
    
    
    // 2. 再添加分钟字符
    CATextLayer * minuteLayer = [CATextLayer layer];
    [minuteLayer setFontSize:60];
    minuteLayer.alignmentMode = kCAAlignmentCenter;
    [minuteLayer setForegroundColor:[UIColor whiteColor].CGColor];
    [minuteLayer setString:@"00:"];
    [minuteLayer setFrame:CGRectMake(videoSize.width / 2 - text_size.width / 2 + str_size.width,  videoSize.height-160, str_size.width, 60)];
    [parentLayer addSublayer:minuteLayer];
    
    // 3. 再添加秒钟字符
    
    // 这里先添加一个占位的，因为首次添加会黑屏
    CATextLayer * secondLayer = [CATextLayer layer];
    [secondLayer setFontSize:60];
    secondLayer.alignmentMode = kCAAlignmentCenter;
    [secondLayer setForegroundColor:[UIColor whiteColor].CGColor];
    [secondLayer setFrame: CGRectMake(videoSize.width / 2 - text_size.width / 2 + str_size.width * 2 , videoSize.height-160, str_size.width, 60)];
    NSString * second_text = [NSString stringWithFormat:@"00."];
    [secondLayer setString:second_text];
    [parentLayer addSublayer:secondLayer];
    //
    CABasicAnimation * animation = nil;
    
    animation = [CABasicAnimation animationWithKeyPath:@"opacity"];
    animation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionDefault];
    [animation setFromValue:[NSNumber numberWithFloat:1]];
    [animation setToValue:[NSNumber numberWithFloat:0]];
    [animation setBeginTime:durationReady];
    //    [animation setBeginTime:2];
    [animation setDuration:0.001];
    [animation setFillMode:kCAFillModeBoth];/*must be backwards*/
    [animation setRemovedOnCompletion:NO];/*must be no*/
    [secondLayer addAnimation:animation forKey:@"animateOpacityShow"];
    
    CATextLayer * micro_secondLayer = [CATextLayer layer];
    [micro_secondLayer setFontSize:60];
    micro_secondLayer.alignmentMode = kCAAlignmentCenter;
    [micro_secondLayer setForegroundColor:[UIColor whiteColor].CGColor];
    [micro_secondLayer setFrame: CGRectMake(videoSize.width / 2 - text_size.width / 2 + str_size.width * 3 ,  videoSize.height-160, text_size.width - str_size.width * 3, 60)];
    NSString * second_text_tmp = [NSString stringWithFormat:@"000"];
    [micro_secondLayer setString:second_text_tmp];
    
    
    animation = nil;
    
    animation = [CABasicAnimation animationWithKeyPath:@"opacity"];
    
    animation = [CABasicAnimation animationWithKeyPath:@"opacity"];
    animation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionDefault];
    [animation setFromValue:[NSNumber numberWithFloat:1.0]];
    [animation setToValue:[NSNumber numberWithFloat:0.0]];
    [animation setBeginTime:durationReady];
    //    [animation setBeginTime:2];
    [animation setDuration:0.001];
    [animation setRemovedOnCompletion:NO];/*must be no*/
    [animation setFillMode:kCAFillModeForwards];
    [micro_secondLayer addAnimation:animation forKey:@"animateOpacityHiddenAgin"];
    
    [parentLayer addSublayer:micro_secondLayer];

    for (int i = 1 ; i <= (int)durationvalue; i++) {
        CATextLayer * secondLayer = [CATextLayer layer];
        [secondLayer setFontSize:60];
        secondLayer.alignmentMode = kCAAlignmentCenter;
        [secondLayer setForegroundColor:[UIColor whiteColor].CGColor];
        [secondLayer setFrame: CGRectMake(videoSize.width / 2 - text_size.width / 2 + str_size.width * 2 ,  videoSize.height-160, str_size.width, 60)];
        NSString * second_text = [NSString stringWithFormat:@"%02d.",i];
        [secondLayer setString:second_text];
        [parentLayer addSublayer:secondLayer];

        if(i < (int)durationvalue){
            CAKeyframeAnimation * keyAnimation = [CAKeyframeAnimation animationWithKeyPath:@"opacity"];
            keyAnimation.duration = 1;
            keyAnimation.values = @[@0,@0.999,@1,@0.999,@0];
            keyAnimation.keyTimes = @[@0,@0.001,@0.5,@0.999,@1];
            keyAnimation.removedOnCompletion = NO;
            keyAnimation.fillMode = kCAFillModeBoth;
            keyAnimation.beginTime = durationReady+i-1;
            [secondLayer addAnimation:keyAnimation forKey:@"animail"];
        }else{
            CAKeyframeAnimation * keyAnimation = [CAKeyframeAnimation animationWithKeyPath:@"opacity"];
            keyAnimation.duration = 0.01;
            keyAnimation.values = @[@0,@1];
            keyAnimation.keyTimes = @[@0,@1];
            keyAnimation.removedOnCompletion = NO;
            keyAnimation.fillMode = kCAFillModeBackwards;
            keyAnimation.beginTime = durationReady+i-1;
            [secondLayer addAnimation:keyAnimation forKey:@"animail"];
        }
        
        

        int miro_count = 1000;
        if(i == (int)durationvalue){
            CGFloat shenyu = durationvalue - (int)durationvalue;
            shenyu = shenyu * 1000;
            miro_count = shenyu;
        }
        
        
        for (int j = 0; j <= miro_count; j++) {
            micro_secondLayer = [CATextLayer layer];
            [micro_secondLayer setFontSize:60];
            micro_secondLayer.alignmentMode = kCAAlignmentCenter;
            [micro_secondLayer setForegroundColor:[UIColor whiteColor].CGColor];
            [micro_secondLayer setBackgroundColor:[UIColor clearColor].CGColor];
            [micro_secondLayer setFrame: CGRectMake(videoSize.width / 2 - text_size.width / 2 + str_size.width * 3 ,  videoSize.height-160, text_size.width - str_size.width * 3, 60)];
            NSString * second_text = [NSString stringWithFormat:@"%03d",j];
            [micro_secondLayer setString:second_text];
            
            if(miro_count == 1000 || j < miro_count){
                CAKeyframeAnimation *   keyAnimation = [CAKeyframeAnimation animationWithKeyPath:@"opacity"];
                keyAnimation.duration = 0.001;
                keyAnimation.values = @[@0,@1,@0];
                keyAnimation.keyTimes = @[@0,@0.5,@1];
                keyAnimation.removedOnCompletion = NO;
                keyAnimation.fillMode = kCAFillModeBoth;
                keyAnimation.beginTime = j*0.001+(durationReady)+i-1;
                [micro_secondLayer addAnimation:keyAnimation forKey:@"keyAnimation"];
            }else{
                CAKeyframeAnimation *   keyAnimation = [CAKeyframeAnimation animationWithKeyPath:@"opacity"];
                keyAnimation.duration = 0.001;
                keyAnimation.values = @[@0,@1];
                keyAnimation.keyTimes = @[@0,@1];
                keyAnimation.removedOnCompletion = NO;
                keyAnimation.fillMode = kCAFillModeBoth;
                keyAnimation.beginTime = j*0.001+(durationReady)+i-1;
            }
            
            [parentLayer addSublayer:micro_secondLayer];
            
        }
        
    }
    
    
    [parentLayer addSublayer:videoLayer];
    
    AVMutableComposition *mixComposition = [[AVMutableComposition alloc] init];
    
    
    //   向混合单元中添加一条视频
    AVMutableCompositionTrack *videoTrack = [mixComposition addMutableTrackWithMediaType:AVMediaTypeVideo
                                                                        preferredTrackID:kCMPersistentTrackID_Invalid];
    
    AVMutableCompositionTrack *audioTrack = [mixComposition addMutableTrackWithMediaType:AVMediaTypeAudio preferredTrackID:kCMPersistentTrackID_Invalid];
    
    AVAssetTrack *assetVideoTrack = [[videoAsset tracksWithMediaType:AVMediaTypeVideo]firstObject];
    NSError * errorVideo;
    BOOL bl = [videoTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, videoAsset.duration)
                                  ofTrack:assetVideoTrack
                                   atTime:kCMTimeZero error:&errorVideo];
    NSLog(@"----> insertTimeRange: b1: %d",bl);
    BOOL b2 =  [audioTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, videoAsset.duration) ofTrack:[videoAsset tracksWithMediaType:AVMediaTypeAudio].firstObject atTime:kCMTimeZero error:&errorVideo];
    NSLog(@"---> insertTimeRange: b2: %d",b2);
    AVMutableVideoComposition* videoComp = [AVMutableVideoComposition videoComposition];
    videoComp.renderSize = videoSize;
    parentLayer.geometryFlipped = true;
    videoComp.frameDuration = CMTimeMake(1, 30);
    videoComp.animationTool = [AVVideoCompositionCoreAnimationTool videoCompositionCoreAnimationToolWithPostProcessingAsVideoLayer:videoLayer inLayer:parentLayer];
    AVMutableVideoCompositionInstruction* instruction = [AVMutableVideoCompositionInstruction videoCompositionInstruction];
    
    instruction.timeRange = CMTimeRangeMake(kCMTimeZero, videoAsset.duration);
    AVMutableVideoCompositionLayerInstruction* layerInstruction = [AVMutableVideoCompositionLayerInstruction videoCompositionLayerInstructionWithAssetTrack:videoTrack];
    instruction.layerInstructions = [NSArray arrayWithObjects:layerInstruction, nil];
  
    
    videoComp.instructions = [NSArray arrayWithObjects: instruction,nil];
    
    //    NSString * outputabsoluteString = [fileUrl.absoluteString  stringByReplacingOccurrencesOfString:@"_completed_time" withString:@"_completed"];
    NSString * outputabsoluteString = [fileUrl.absoluteString  stringByReplacingOccurrencesOfString:@"_completed" withString:@"_completed"];
    NSURL * outputUrl = [NSURL URLWithString:outputabsoluteString];
    
    AVAssetExportSession* exporter = [[AVAssetExportSession alloc] initWithAsset:mixComposition
                                                                      presetName:AVAssetExportPresetHighestQuality];
    exporter.outputURL=outputUrl;

    exporter.outputFileType = AVFileTypeMPEG4;
    exporter.shouldOptimizeForNetworkUse = YES;
    exporter.videoComposition = videoComp;
    [exporter exportAsynchronouslyWithCompletionHandler:^{
        NSLog(@"=========================");
        //        dispatch_async(dispatch_get_main_queue(), ^{
        //这里是输出视频之后的操作，做你想做的
        NSLog(@"添加倒计时后输出视频地址:%@ andCode:%@",outputUrl,exporter.error);
        
        CGFloat count_current = 1.0;
        
        CGFloat current_progress  = count_current + self->progress;
        
        if(count_current >= 1.0){
            self->progress += count_current;
        }
        
        CGFloat progress_file = current_progress / self->count_progress;
        NSDictionary * data = @{progress_count:@(self->count_progress),prgress_video:@(progress_file)};
        if(progress_file >= 1.0){
            dispatch_async(dispatch_get_main_queue(), ^{
                [[NSNotificationCenter defaultCenter] postNotificationName:recv_video_progress_done_notify_name object:nil userInfo:data];
            });

            NSLog(@"合成进度完成: %f",progress_file);
        }else{
            dispatch_async(dispatch_get_main_queue(), ^{
                [[NSNotificationCenter defaultCenter] postNotificationName:recv_video_progress_notify_name object:nil userInfo:data];
            });
        
            NSLog(@"视频合成中: %f",progress_file);
        }
    }];
    
}

// 合成时的时间计时器
-(void)funcTimer {
    
    
    CGFloat progress_item = 0;
    for (AVAssetExportSession * export in self->avassetExportArray) {
        progress_item += export.progress;
    }
    
    CGFloat progress_file = progress_item / self->count_progress;
    NSDictionary * data = @{progress_count:@(self->count_progress),prgress_video:@(progress_file)};
    if(progress_file >= 1.0){
        dispatch_async(dispatch_get_main_queue(), ^{
            [[NSNotificationCenter defaultCenter] postNotificationName:recv_video_progress_done_notify_name object:nil userInfo:data];
        });

        NSLog(@"合成进度完成: %f",progress_file);
        [self->timer invalidate];
    }else{
        dispatch_async(dispatch_get_main_queue(), ^{
            [[NSNotificationCenter defaultCenter] postNotificationName:recv_video_progress_notify_name object:nil userInfo:data];
        });

        NSLog(@"视频合成中: %f",progress_file);
    }
}

// 视频合成的进度
-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context{
    NSNumber * num = change[@"new"];
    CGFloat count_current = [num floatValue];
    
    CGFloat current_progress  = count_current + progress;
    
    if(count_current >= 1.0){
        progress += count_current;
    }
    
    CGFloat progress_file = current_progress / count_progress;
    NSDictionary * data = @{progress_count:@(count_progress),prgress_video:@(progress_file)};
    if(progress_file >= 1.0){
        dispatch_async(dispatch_get_main_queue(), ^{
            [[NSNotificationCenter defaultCenter] postNotificationName:recv_video_progress_done_notify_name object:data];
        });

        NSLog(@"合成进度完成: %f",progress_file);
    }else{
        dispatch_async(dispatch_get_main_queue(), ^{
            [[NSNotificationCenter defaultCenter] postNotificationName:recv_video_progress_notify_name object:data];
        });

        NSLog(@"视频合成中: %f",progress_file);
    }
    
}

-(void)removesignal{
    if(self->t){
        dispatch_semaphore_signal(self->t);
        self->t = nil;
    }
}
@end
