//
//  SpeedTestInteractive.m
//  CarLinkChannel
//
//  Created by job on 2023/4/25.
//

#import "SpeedTestInteractive.h"

#import "SpeedView.h"
#import <AVFoundation/AVFoundation.h>
@interface SpeedTestInteractive()<AVCaptureFileOutputRecordingDelegate,AVCaptureVideoDataOutputSampleBufferDelegate,AVCaptureAudioDataOutputSampleBufferDelegate,AVAudioPlayerDelegate>
{
    BOOL state;
    BOOL isShooting;
    BOOL isTest;        // 是否在速度测试状态
    int isRecoredState;   // 0. 初始状态    1. 开始记录    2.记录中   3. 开始等待完成停止录制  4. 开始停止
    int timeCount;
    AVAudioPlayer * audioPlayer;
    dispatch_source_t animation_t_internet;
    dispatch_source_t video_time_count;             // 录制视频计时器
    NSString * videoPath;
    NSString * txtPath;
    int speedteststate;         // 测速状态   0.初始状态  1.到达50km/h 之后 2.到达100km/h之后   用于播放速度测试时的音频
    __block int count;
    int speedSero;              // 测速时候的分支
    NSTimeInterval starttimer;   //     测速开始计时的时间起点
    NSTimeInterval endtimer;        //  测速结束计时的时间起点
    NSTimeInterval videoStarTimer;   // 视频开始录制的时间起点
    int type;           // 1. 测速模式     2. Racing 模式
//    int
}
@property (nonatomic,strong) AVCaptureSession * session;
@property (nonatomic,strong) AVCaptureDeviceInput * inputPicture;
@property (nonatomic,strong) AVCaptureDeviceInput * inputAudio;
@property (nonatomic,strong) AVCaptureMovieFileOutput * output;
@property (nonatomic,strong) AVCaptureVideoDataOutput * videoOutput;
@property (nonatomic,strong) AVCaptureAudioDataOutput * audioOutput;
@property (nonatomic,strong) AVCaptureSession * capturesession;
@property (nonatomic,strong) AVCaptureVideoPreviewLayer * layer;
@property (nonatomic,strong) dispatch_queue_t captureQueue;
@property (nonatomic,strong) AVCaptureConnection * videoConnection;
@property (nonatomic,strong) AVAssetWriter * writer;
@property (nonatomic,strong) AVAssetWriterInput * videoInput;
@property (nonatomic,strong) AVAssetWriterInput * audioInput;
@property (assign, nonatomic) UIDeviceOrientation shootingOrientation;
@end
@implementation SpeedTestInteractive


-(void)loadCaptureWithView:(UIView *)view {
    self.session = [[AVCaptureSession alloc] init];
    [self.session beginConfiguration];
    
    [self.session setSessionPreset:AVCaptureSessionPreset1280x720];
    
    // 输入
    AVCaptureDevice *inputCamera;
    
//    inputCamera = [AVCaptureDevice defaultDeviceWithDeviceType:AVCaptureDeviceTypeBuiltInDualCamera mediaType:AVMediaTypeVideo position:AVCaptureDevicePositionFront];
//    if (@available(iOS 13.0, *)) {
//        inputCamera = [AVCaptureDevice defaultDeviceWithDeviceType:AVCaptureDeviceTypeBuiltInDualWideCamera mediaType:AVMediaTypeVideo position:AVCaptureDevicePositionFront];
//    } else {
//        // Fallback on earlier versions
//    }
    AVCaptureDeviceDiscoverySession * discoverySession = [AVCaptureDeviceDiscoverySession discoverySessionWithDeviceTypes:@[AVCaptureDeviceTypeBuiltInWideAngleCamera] mediaType:AVMediaTypeVideo position:AVCaptureDevicePositionBack];
    NSArray * devices = discoverySession.devices;
//    NSArray *devices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
    for (AVCaptureDevice *device in devices) {
        if ([device position] == AVCaptureDevicePositionBack) {
            inputCamera = device;
        }
    }
    
    // 设置帧率 低帧率模式(<=30fps)下，此API有效
    [inputCamera lockForConfiguration:NULL];
    [inputCamera setActiveVideoMinFrameDuration:CMTimeMake(1, 30)];
    [inputCamera setActiveVideoMaxFrameDuration:CMTimeMake(1, 30)];
    [inputCamera unlockForConfiguration];
    
    
    NSError *error;
    AVCaptureDeviceInput *videoInput = [[AVCaptureDeviceInput alloc] initWithDevice:inputCamera error:&error];
    if ([self.session canAddInput:videoInput]) {
        [self.session addInput:videoInput];
    }

    
    // 输出
    AVCaptureVideoDataOutput *videoOutput = [[AVCaptureVideoDataOutput alloc] init];
    [videoOutput setAlwaysDiscardsLateVideoFrames:NO];
    // 输出的像素格式 NV12
//    [videoOutput setVideoSettings:@{
//        (id)kCVPixelBufferPixelFormatTypeKey: @(kCVPixelFormatType_420YpCbCr8BiPlanarFullRange)
//    }];
    // 输出回调
    [videoOutput setSampleBufferDelegate:self queue:dispatch_get_global_queue(0, 0)];
    if ([self.session canAddOutput:videoOutput]) {
        [self.session addOutput:videoOutput];
    }
    
    
    // 竖屏录制
    AVCaptureConnection *conn = [videoOutput connectionWithMediaType:AVMediaTypeVideo];
    conn.videoOrientation = AVCaptureVideoOrientationLandscapeRight;
    
    // 开启防抖模式会导致高清视频编码延迟
    
    [self.session commitConfiguration];
    
    // 预览
    AVCaptureVideoPreviewLayer *previewLayer = [AVCaptureVideoPreviewLayer layerWithSession:self.session];
    previewLayer.orientation = AVCaptureVideoOrientationLandscapeRight;
//    previewLayer.frame = view.bounds;
    previewLayer.frame = CGRectMake(0, 0, view.frame.size.height,view.frame.size.width);
    [view.layer addSublayer:previewLayer];
    
    previewLayer.backgroundColor = [UIColor blackColor].CGColor;

    NSLog(@"previewLayer.frame origin.x:%f y: %f .size.width: %f height: %f",previewLayer.frame.origin.x,previewLayer.frame.origin.y,previewLayer.frame.size.width,previewLayer.frame.size.height);
    if (![self.session isRunning]) {
        [self.session startRunning];
    };
    
}
-(void)destoryTimer{
    if(self->animation_t_internet){
        dispatch_source_cancel(self->animation_t_internet);
        self->animation_t_internet = nil;
    }
    if(self->video_time_count){
        dispatch_source_cancel(self->video_time_count);
        self->video_time_count = nil;
    }
}
-(void)CarSpeedSero:(int)sero CarSpeed:(int)sudu{
    // 处理后的速度
    speedSero = sero;
    
    NSLog(@"timecount: %d, isTest: %d",timeCount,isTest);
    
    if(isTest == false){
        if(sudu == 0){
            timeCount++;
        }
        else{
            timeCount = 0;
        }
        if(type == 2){
            isTest = true;
            if(isRecoredState == 0){
                // 这里判断是否开始录制，如果没有录制，开始录制
                isRecoredState = 1;
                [[NSNotificationCenter defaultCenter] postNotificationName:recv_speed_time_start_notify_name object:nil];
                // 播放准备音频
//                NSString * readyFile = [[NSBundle mainBundle] pathForResource:@"ready" ofType:@"WAV"];
//                audioPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:[NSURL fileURLWithPath:readyFile] error:nil];
//                audioPlayer.delegate = self;
//                [audioPlayer play];
            }
        }else if (type == 1){
            if(timeCount == 200){
                isTest = true;
                if(isRecoredState == 0){
                    // 这里判断是否开始录制，如果没有录制，开始录制
                    isRecoredState = 1;
                    // 播放准备音频
                    NSString * readyFile = [[NSBundle mainBundle] pathForResource:@"ready" ofType:@"WAV"];
                    audioPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:[NSURL fileURLWithPath:readyFile] error:nil];
                    audioPlayer.delegate = self;
                    [audioPlayer play];
                }
            }
        }
    }
    
    if(isTest == true){
        
        if(sudu == 0){
            
        }else if (sudu > 0){
            // 如果等于0表示开始计时
//            if(starttimer == 0 && isRecoredState == 2){
            if(type == 1){
                if(starttimer == 0){
                    starttimer = [NSDate date].timeIntervalSince1970;
                    [[NSNotificationCenter defaultCenter] postNotificationName:recv_speed_time_start_notify_name object:nil];
                    
                    if(video_time_count){
                        dispatch_source_cancel(video_time_count);
                        video_time_count = nil;
                    }
                    self->count = 0;
                    //设置时间间隔
                    NSTimeInterval period = 1.0f;
                    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
                    video_time_count = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, queue);
                    
                    // 第一次不会立刻执行，会等到间隔时间后再执行
                    //    dispatch_time_t start = dispatch_time(DISPATCH_TIME_NOW, period * NSEC_PER_SEC);
                    //    dispatch_source_set_timer(_timer, start, period * NSEC_PER_SEC, 0);
                    
                    // 第一次会立刻执行，然后再间隔执行
                    dispatch_source_set_timer(video_time_count, dispatch_walltime(NULL, 0), period * NSEC_PER_MSEC, 0);
                    // 事件回调
                    dispatch_source_set_event_handler(video_time_count, ^{
                         self->count ++;
                        // 意思是20s后如果没有达到速度100km/h，就自动重置, 这里因为一直有速度，如果立即将开始计时的时间清0，会导致开始计时的通知在准备的通知之前，所以这里在有速度的情况下，先开始重置录制，等待1s后再发送开始计时的通知
                        if(self->count == 20000){
                            if(self->video_time_count){
                                dispatch_source_cancel(self->video_time_count);
                                self->video_time_count = nil;
                            }
                            [self cancelRecored];
                            self->isRecoredState = 4;
                            [[NSNotificationCenter defaultCenter] postNotificationName:recv_speed_test_timeout_notify_name object:nil];
    //                        [self initAvassetWritter];
    //                        self->isRecoredState = 1;
    //                        self->speedteststate = 0;
    //                        self->videoStarTimer = 0;
                            self->count = 0;
    //                        self->starttimer = 0;
    //                        self->endtimer = 0;
    //                        double delay = 500;
    //                        int64_t delta = (int64_t)delay * NSEC_PER_MSEC;
    //                        dispatch_time_t poptime = dispatch_time(DISPATCH_TIME_NOW, delta);
    //                        dispatch_after(poptime, dispatch_get_global_queue(0, 0), ^{
    //                            self->starttimer = 0;
    //                            self->endtimer = 0;
    //                        });
                            
    //                        self->starttimer = 0;
    //                        self->endtimer = 0;
                        }
    //                    else if (self->count == 21000){
    //                        if(self->video_time_count){
    //                            dispatch_source_cancel(self->video_time_count);
    //                            self->video_time_count = nil;
    //                        }
    //                        self->count = 0;
    //                        self->videoStarTimer = 0;
    //                        self->starttimer = 0;
    //                        self->endtimer = 0;
    //                    }
                    });
                    // 开启定时器
                    if (video_time_count) {
                        dispatch_resume(video_time_count);
                    }
                }
  
            }
            if(isRecoredState == 2){
                if (sudu >= 100){
                    if(speedteststate == 1){
                        if(type == 1){
                            speedteststate = 2;
                            endtimer = [NSDate date].timeIntervalSince1970;
                            CGFloat time = (CGFloat)(endtimer - starttimer);
                            NSLog(@"发送停止计时的通知");
                            [[NSNotificationCenter defaultCenter] postNotificationName:recv_speed_stop_timer_notify_name object:nil userInfo:@{@"time":@(time)}];
                            if(video_time_count){
                                dispatch_source_cancel(video_time_count);
                                video_time_count = nil;
                            }
                            // 播放 100码的音频 ， 等待1s后结束录制
                            NSString * readyFile = [[NSBundle mainBundle] pathForResource:@"100" ofType:@"WAV"];
                            audioPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:[NSURL fileURLWithPath:readyFile] error:nil];
                            audioPlayer.delegate = self;
                            audioPlayer.volume = 1;
                            [audioPlayer play];
                        }
//                        }else if (type == 2){
//                            // 播放 100码的音频 ， 等待1s后结束录制
//                            NSString * readyFile = [[NSBundle mainBundle] pathForResource:@"100" ofType:@"WAV"];
//                            audioPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:[NSURL fileURLWithPath:readyFile] error:nil];
//                            audioPlayer.delegate = self;
//                            audioPlayer.volume = 1;
//                            [audioPlayer play];
//                        }

                    }
                    
                   if (type == 2){
                            // 播放 100码的音频 ， 等待1s后结束录制
//                        NSString * readyFile = [[NSBundle mainBundle] pathForResource:@"100" ofType:@"WAV"];
//                        audioPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:[NSURL fileURLWithPath:readyFile] error:nil];
//                        audioPlayer.delegate = self;
//                        audioPlayer.volume = 1;
//                        [audioPlayer play];
                 }
               
     //
     //                // 速度达到 100 后， 等待1s就暂停录制
     //                if(isRecoredState == 2){
     //                    isRecoredState = 3;
     //                    [self timerFunc];
     //                }
            
                }else  if(sudu >= 50){
                    if(speedteststate == 0){
                        if(type == 1){
                            // 播放 50码的音频
                            NSString * readyFile = [[NSBundle mainBundle] pathForResource:@"50" ofType:@"WAV"];
                            audioPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:[NSURL fileURLWithPath:readyFile] error:nil];
                            audioPlayer.volume = 1;
                            [audioPlayer play];
                            speedteststate = 1;
                        }
                    }
                    if(type == 2){
                        // 播放 50码的音频
//                        NSString * readyFile = [[NSBundle mainBundle] pathForResource:@"50" ofType:@"WAV"];
//                        audioPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:[NSURL fileURLWithPath:readyFile] error:nil];
//                        audioPlayer.volume = 1;
//                        [audioPlayer play];
//                        speedteststate = 1;
                    }
                }
            }
        }
        
    }
    
    
}
-(void)timerFunc {

    NSLog(@"加速到100以后 开始计数一秒");
    //设置时间间
    double delay = 1;
    int64_t delta = (int64_t)delay * NSEC_PER_SEC;
    dispatch_time_t poptime = dispatch_time(DISPATCH_TIME_NOW, delta);
    dispatch_after(poptime, dispatch_get_global_queue(0, 0), ^{
        NSLog(@"完成 1s以后");
        self->isRecoredState = 4;
    });


}
#pragma mark   音频播放的回调
- (void)audioPlayerDidFinishPlaying:(AVAudioPlayer *)player successfully:(BOOL)flag{
    
    if([player.url.absoluteString containsString:@"ready.WAV"]){


      //  isRecoredState = 2;
    }else if ([player.url.absoluteString hasSuffix:@"100.WAV"]){
        // 速度达到 100 后， 等待1s就暂停录制
        if(isRecoredState == 2 && speedteststate == 2){
            isRecoredState = 3;
            [self timerFunc];
        }
    }
    
    NSLog(@"播放结束");

}
#pragma mark   启动音视频输入

//录制的队列
- (dispatch_queue_t)captureQueue {
    if (_captureQueue ==nil) {
        _captureQueue =dispatch_queue_create("cn.qiuyouqun.im.wclrecordengine.capture",DISPATCH_QUEUE_SERIAL);
    }
    return _captureQueue;
}

//视频输出
- (AVCaptureVideoDataOutput *)videoOutput {
    if (_videoOutput ==nil) {
        _videoOutput = [[AVCaptureVideoDataOutput alloc] init];
        [_videoOutput setSampleBufferDelegate:self queue:self.captureQueue];
//        NSDictionary* setcapSettings = [NSDictionary dictionaryWithObjectsAndKeys:
//                                        [NSNumber numberWithInt:kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange],kCVPixelBufferPixelFormatTypeKey,
//                                        nil];
//        _videoOutput.videoSettings = setcapSettings;
    }
    return _videoOutput;
}
- (AVCaptureAudioDataOutput *)audioOutput{
    if(_audioOutput == nil){
        _audioOutput = [[AVCaptureAudioDataOutput alloc] init];
        [_audioOutput setSampleBufferDelegate:self queue:self.captureQueue];
    }
    return _audioOutput;
}
//初始化视频输入
- (void)initVideoInputHeight:(NSInteger)cy width:(NSInteger)cx {
    //录制视频的一些配置，分辨率，编码方式等等
//    NSDictionary* settings = [NSDictionary dictionaryWithObjectsAndKeys:
//                              AVVideoCodecTypeH264,AVVideoCodecKey,
//                              [NSNumber numberWithInteger: cx], AVVideoWidthKey,
//                              [NSNumber numberWithInteger: cy], AVVideoHeightKey,
//                              nil];
//    NSInteger numPixels = [UIScreen mainScreen].bounds.size.width * [UIScreen mainScreen].bounds.size.height;
//    CGFloat bitsPerPixel = 10.0;
//    NSInteger bitsPerSecond = numPixels * bitsPerPixel;
    NSInteger bitsPerSecond = 1500000;
    // 码率和帧率设置
//    NSDictionary *compressionProperties = @{ AVVideoAverageBitRateKey : @(bitsPerSecond),
//    AVVideoExpectedSourceFrameRateKey : @(30),
//    AVVideoMaxKeyFrameIntervalKey : @(30),
//    AVVideoProfileLevelKey : AVVideoProfileLevelH264BaselineAutoLevel };
//    
////    CGSize size = [UIScreen mainScreen].bounds.size;
////    CGFloat width_video = size.width > size.height ? size.width : size.height;
////    CGFloat height_video = size.width > size.height ? size.height : size.width;
//    
//    NSDictionary * videoCompressionSettings = @{ AVVideoCodecKey : AVVideoCodecTypeH264,
//    AVVideoWidthKey : @(1280),
//    AVVideoHeightKey : @(720),
//    AVVideoScalingModeKey : AVVideoScalingModeResizeAspect,
//    AVVideoCompressionPropertiesKey : compressionProperties };
//
//
//    
//    //初始化视频写入类
//    _videoInput = [AVAssetWriterInput assetWriterInputWithMediaType:AVMediaTypeVideo outputSettings:videoCompressionSettings];
//    
    
    
    NSDictionary *compressionProperties = @{
        AVVideoAverageBitRateKey : @(1500000), // 比特率 6Mbps
        AVVideoMaxKeyFrameIntervalKey : @30,  // 关键帧间隔 30 帧
        AVVideoProfileLevelKey : AVVideoProfileLevelH264HighAutoLevel // H.264 高级配置
    };

    NSDictionary *videoCompressionSettings = @{
        AVVideoCodecKey : AVVideoCodecTypeH264,
        AVVideoWidthKey : @(1280),
        AVVideoHeightKey : @(720),
        AVVideoScalingModeKey : AVVideoScalingModeResizeAspect,
        AVVideoCompressionPropertiesKey : compressionProperties
    };

    _videoInput = [AVAssetWriterInput assetWriterInputWithMediaType:AVMediaTypeVideo outputSettings:videoCompressionSettings];

    
    
    //表明输入是否应该调整其处理为实时数据源的数据
    _videoInput.expectsMediaDataInRealTime =YES;
    _videoInput.transform = CGAffineTransformMakeRotation(M_PI / 2.0);
    [_videoInput setExpectsMediaDataInRealTime:NO];
    if (self.shootingOrientation == UIDeviceOrientationLandscapeRight)
    {
        _videoInput.transform = CGAffineTransformMakeRotation(M_PI);
    }
    else if (self.shootingOrientation == UIDeviceOrientationLandscapeLeft)
    {
        _videoInput.transform = CGAffineTransformMakeRotation(0);
    }
    else if (self.shootingOrientation == UIDeviceOrientationPortraitUpsideDown)
    {
        _videoInput.transform = CGAffineTransformMakeRotation(M_PI + (M_PI / 2.0));
    }
    else
    {
        _videoInput.transform = CGAffineTransformMakeRotation(M_PI / 2.0);
    }

    // 音频设置
    NSDictionary * audioCompressionSettings = @{ AVEncoderBitRatePerChannelKey : @(28000),
    AVFormatIDKey : @(kAudioFormatMPEG4AAC),
    AVNumberOfChannelsKey : @(2),
    AVSampleRateKey : @(22050)
//    AVSampleRateKey:@(44100)
    };
    
    _audioInput = [AVAssetWriterInput assetWriterInputWithMediaType:AVMediaTypeAudio outputSettings:audioCompressionSettings];
    _audioInput.expectsMediaDataInRealTime = YES;
    //将视频输入源加入
    if([_writer canAddInput:_videoInput]){
        [_writer addInput:_videoInput];
    }else{
        NSLog(@"AssetWriter videoInput append Failed");
    }
    
    if([_writer canAddInput:_audioInput]){
        [_writer addInput:_audioInput];
    }
    
}
//初始化方法
- (void)initPath:(NSString*)path1    Height:(NSInteger)cy width:(NSInteger)cx channels:(int)ch samples:(Float64) rate {
//    self = [super init];
//    if (self) {
    
    NSString * documentPath = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)[0];
    NSString * moviePath = [documentPath stringByAppendingPathComponent:@"Movie"];
    BOOL hidden = [[NSUserDefaults standardUserDefaults] boolForKey:@"videoexport"];
    if(hidden){
        moviePath = [documentPath stringByAppendingPathComponent:@"Racing"];
    }
    
    
    NSFileManager * fm = [NSFileManager defaultManager];
    if(![fm fileExistsAtPath:moviePath]){
        [fm createDirectoryAtPath:moviePath withIntermediateDirectories:YES attributes:nil error:nil];
    }
    
    
    NSDateFormatter * dateFormat  = [[NSDateFormatter alloc] init];
//    dateFormat.dateFormat = @"dd-MM-yyyy HH:mm";
//    if(hidden){
        dateFormat.dateFormat = @"dd-MM-yyyy HH:mm:ss";
//    }
    
    NSString * dateString = [dateFormat stringFromDate:[NSDate date]];
    
    NSLog(@"dateString: %@",dateString);
    
    NSString * path = [NSString stringWithFormat:@"%@/%@_origin.mp4",moviePath,dateString];
    NSString * txtFilePath = [NSString stringWithFormat:@"%@/%@.txt",moviePath,dateString];
    if(![fm fileExistsAtPath:txtFilePath]){
        [fm createFileAtPath:txtFilePath contents:nil attributes:nil];
    }
    [[NSUserDefaults standardUserDefaults] setObject:txtFilePath forKey:@"txtFilePath"];
    NSLog(@"txtFilePath: %@",txtFilePath);
    [[NSUserDefaults standardUserDefaults] synchronize];
        //先把路径下的文件给删除掉，保证录制的文件是最新的
//        [[NSFileManager defaultManager] removeItemAtPath:path error:nil];
        NSURL* url = [NSURL fileURLWithPath:path];
        videoPath = path;
        txtPath = txtFilePath;
        //初始化写入媒体类型为MP4类型
        NSError * error;
        _writer = [AVAssetWriter assetWriterWithURL:url fileType:AVFileTypeMPEG4 error:&error];
        NSLog(@"File Type error: %@",error);
//        _writer.delegate = self;
        //使其更适合在网络上播放
        _writer.shouldOptimizeForNetworkUse =YES;
  
    NSLog(@"------------->  initfilepath: %@",path);
    CGRect rect = [UIScreen mainScreen].bounds;
    NSLog(@"width: %lf height: %lf",rect.size.width,rect.size.height);
    //初始化视频输出
        [self initVideoInputHeight:rect.size.width * 2 width:rect.size.height * 2];
        //确保采集到rate和ch
        if (rate !=0 && ch != 0) {
            //初始化音频输出
//            [self initAudioInputChannels:ch samples:rate];
        }
//    }
//    return self;
}


- (void)assetWriter:(AVAssetWriter *)writer didOutputSegmentData:(NSData *)segmentData segmentType:(AVAssetSegmentType)segmentType segmentReport:(nullable AVAssetSegmentReport *)segmentReport{
    
    NSLog(@"------>  didOutputSegmentData");
}

/*!
@method assetWriter:didOutputSegmentData:segmentType:
@abstract
   A method invoked when a segment data is output.

@param writer
   An AVAssetWriter instance.
@param segmentData
   An instance of NSData containing a segment data.
@param segmentType
   A segment type of the segment data. Segment types are declared in AVAssetSegmentReport.h.

@discussion
   The usage of this method is same as -assetWriter:didOutputSegmentData:segmentType:segmentReport: except that this method does not deliver AVAssetSegmentReport.

   If clients implement the -assetWriter:didOutputSegmentData:segmentType:segmentReport: method, that method is called instead of this one.
*/
- (void)assetWriter:(AVAssetWriter *)writer didOutputSegmentData:(NSData *)segmentData segmentType:(AVAssetSegmentType)segmentType{
    
    NSLog(@"------> didOutputSegmentData");
}

-(void)initAudioInput:(UIView *)view  {
    
    [[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"isRecord"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    self.shootingOrientation = UIDeviceOrientationLandscapeRight;
    
    //视频录制请参考二维码扫描
    // 0 --3----8-- 10 点击了开始录制按钮 结束按钮
    //角色:  1.输入设备画面输入 摄像头  输入麦克风    2.输出文件的输出保存为mp4 ->录制  3.会话 (session 关联以上设备)  4.展示当前摄像头捕捉到画面
    
    //创建所有设备(摄像头)摄像头 两个 前置后置
    AVCaptureDevice *devicePitcure = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    
    AVCaptureDevice *deviceAudio = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeAudio];
    
    //设备输入数据管理对象，管理输入数据AVCaptureDeviceInput
    //指定摄像头作为输入设备 还可以用麦克风作为输入设备
    self.inputPicture = [AVCaptureDeviceInput deviceInputWithDevice:devicePitcure error:nil];
    self.inputAudio = [AVCaptureDeviceInput deviceInputWithDevice:deviceAudio error:nil];

        //添加防抖动功能
    self.videoConnection = [self.videoOutput connectionWithMediaType:AVMediaTypeVideo];
        if ([self.videoConnection isVideoStabilizationSupported]) {
            self.videoConnection.preferredVideoStabilizationMode = AVCaptureVideoStabilizationModeAuto;//防抖模式
        }
    self.videoConnection.videoOrientation = AVCaptureVideoOrientationLandscapeRight;
    //设置视频录制的方向

    self.capturesession = [[AVCaptureSession alloc]init];//会话，用来关联输入输出

    [self.capturesession setSessionPreset:AVCaptureSessionPreset1280x720];
    //关联layer和session
    self.layer = [[AVCaptureVideoPreviewLayer alloc]initWithSession:self.capturesession];//相机拍摄预览图层，是CALayer的子类，实时查看拍照或录像效果。
    self.layer.videoGravity =AVLayerVideoGravityResize;
    self.layer.orientation = AVCaptureVideoOrientationLandscapeRight;
    self.layer.frame = CGRectMake(0, 0, view.frame.size.height,view.frame.size.width);
    //看到 layer再说
    [view.layer addSublayer:self.layer];
    
    //关联输入
    if ([self.capturesession canAddInput:self.inputPicture]) {
        [self.capturesession addInput:self.inputPicture];
    }
    if ([self.capturesession canAddInput:self.inputAudio]) {
        [self.capturesession addInput:self.inputAudio];
    }
    // 关联输出
    if ([self.capturesession canAddOutput:self.videoOutput]) {
        [self.capturesession addOutput:self.videoOutput];
    }
    
    
    if([self.capturesession canAddOutput:self.audioOutput]){
        [self.capturesession addOutput:self.audioOutput];
    }
    //查看录制结果(真机)
    //设置属性
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        //会话创建之后 关联  开启session
        [self.capturesession startRunning];
    });
   
    
    count = 0;
    isRecoredState = 0;
    timeCount = 0;
    speedteststate = 0;
    videoStarTimer = 0;
    starttimer = 0;
    endtimer = 0;
    
    bool export = [[NSUserDefaults standardUserDefaults] boolForKey:@"videoexport"];
    
    NSLog(@"---------->  video export %d",export);
    if(export == true){
        type = 2;
//        starttimer = 100;
    }else{
        type = 1;
    }
    [self initAvassetWritter];
}
-(void)initAvassetWritter {
        [self initPath:@"" Height:100 width:100 channels:100 samples:100];
        self->isShooting = YES;
}
-(void)startRecored:(CMSampleBufferRef)sampleBuffer {
    
    if(isRecoredState == 1){
        isRecoredState = 2;
        NSLog(@"--------> 现在开始录制");
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"isRecord"];
        [[NSUserDefaults standardUserDefaults] synchronize];
        videoStarTimer = [NSDate date].timeIntervalSince1970;
        if([self->_writer status] != AVAssetWriterStatusWriting){
            NSLog(@"------------>开始写入 : videoPath: %@,txtpath: %@",videoPath,txtPath);
  
            [self->_writer startWriting];
            [self->_writer startSessionAtSourceTime:CMSampleBufferGetPresentationTimeStamp(sampleBuffer)];

        
            if(video_time_count){
                dispatch_source_cancel(video_time_count);
                video_time_count = nil;
            }
            
            if(type == 1){
                [[NSNotificationCenter defaultCenter] postNotificationName:recv_speed_ready_notify_name object:nil];
                //设置时间间隔
                NSTimeInterval period = 1.0f;
                dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
                video_time_count = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, queue);
                
                // 第一次不会立刻执行，会等到间隔时间后再执行
                //    dispatch_time_t start = dispatch_time(DISPATCH_TIME_NOW, period * NSEC_PER_SEC);
                //    dispatch_source_set_timer(_timer, start, period * NSEC_PER_SEC, 0);
                
                // 第一次会立刻执行，然后再间隔执行
                dispatch_source_set_timer(video_time_count, dispatch_walltime(NULL, 0), period * NSEC_PER_MSEC, 0);
                // 事件回调
                dispatch_source_set_event_handler(video_time_count, ^{
                     self->count ++;
                    if(self->count >= 20000){
                        [self cancelRecored];
                        [self initAvassetWritter];
                        self->videoStarTimer = 0;
                        self->starttimer = 0;
                        self->endtimer = 0;
                        self->isRecoredState = 1;
                        self->speedteststate = 0;
                        if(self->video_time_count){
                            dispatch_source_cancel(self->video_time_count);
                            self->video_time_count = nil;
                        }
                        self->count = 0;
                    }
                    
                });
                
                // 开启定时器
                if (video_time_count) {
                    dispatch_resume(video_time_count);
                }
            }else if (type == 2){
                //设置时间间隔
                NSTimeInterval period = 1.0f;
                dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
                video_time_count = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, queue);
                
                // 第一次不会立刻执行，会等到间隔时间后再执行
                //    dispatch_time_t start = dispatch_time(DISPATCH_TIME_NOW, period * NSEC_PER_SEC);
                //    dispatch_source_set_timer(_timer, start, period * NSEC_PER_SEC, 0);
                
                // 第一次会立刻执行，然后再间隔执行
                dispatch_source_set_timer(video_time_count, dispatch_walltime(NULL, 0), period * NSEC_PER_MSEC, 0);
                // 事件回调
                dispatch_source_set_event_handler(video_time_count, ^{
                     self->count ++;
                    if(self->count >= 30000){
                        NSLog(@"---------->  满了30s");
                      //  [self cancelRecored];
//                        [self initAvassetWritter];
                        self->videoStarTimer = 0;
                        self->starttimer = 100;
//                        self->endtimer = 0;
                        self->isRecoredState = 4;
                        self->speedteststate = 0;
                        if(self->video_time_count){
                            dispatch_source_cancel(self->video_time_count);
                            self->video_time_count = nil;
                        }
                        self->count = 0;
                    }
                    
                });
                
                // 开启定时器
                if (video_time_count) {
                    dispatch_resume(video_time_count);
                }
            }

        }
        
    }else{
        return;
    }

    
}
-(void)endRecored {
    
    if(isRecoredState == 4){
        isRecoredState = 0;
        self->count = 0;
        double delay = 100;
        int64_t delta = (int64_t)delay * NSEC_PER_MSEC;
        dispatch_time_t poptime = dispatch_time(DISPATCH_TIME_NOW, delta);
        dispatch_after(poptime, dispatch_get_global_queue(0, 0), ^{
            [[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"isRecord"];
            [[NSUserDefaults standardUserDefaults] synchronize];
            NSLog(@"------------>  停止写入倒计时  ,self.txtPath: %@,self->type: %d",self->txtPath,self->type);

        });
        
        double delay_end = 120;
        int64_t delty_end_time = (int64_t)delay_end * NSEC_PER_MSEC;
        dispatch_time_t poptime_end_time = dispatch_time(DISPATCH_TIME_NOW, delty_end_time);
        dispatch_after(poptime_end_time, dispatch_get_global_queue(0, 0), ^{
            
         //    如果是测速模式就写入原始数据值，如果不是测速模式就将 分支乘以 10 ，其它位数用0填充
            if(self->type == 1){

                // 24个字符长度
                // 分支，开始计时时间起点，达到100km/h时在视频中的时间点，总共耗时
                NSString * seroPrefix = [NSString stringWithFormat:@"[%d,%06.2f,%06.2f,%06.2f]",self->speedSero,self->starttimer-self->videoStarTimer,self->endtimer-self->videoStarTimer,self->endtimer-self->starttimer];
                NSData * seroData = [seroPrefix dataUsingEncoding:NSUTF8StringEncoding];
                NSFileHandle * fileHandler = [NSFileHandle fileHandleForWritingAtPath:self->txtPath];
                [fileHandler seekToEndOfFile];
                [fileHandler writeData:seroData];
                [fileHandler closeFile];
            }else if(self->type == 2){
                // 24个字符长度
                // 分支，开始计时时间起点，达到100km/h时在视频中的时间点，总共耗时
                NSString * seroPrefix = [NSString stringWithFormat:@"[%d,000.00,000.00,000.00]",self->speedSero*10];
                NSData * seroData = [seroPrefix dataUsingEncoding:NSUTF8StringEncoding];
                NSFileHandle * fileHandler = [NSFileHandle fileHandleForWritingAtPath:self->txtPath];
                [fileHandler seekToEndOfFile];
                [fileHandler writeData:seroData];
                [fileHandler closeFile];

            }
            NSLog(@"写入结束符倒计时");
            if(self->type == 2){
                NSLog(@"--------->  racing模式 倒计时");
                [self initAvassetWritter];
                self->isRecoredState = 1;
            }
            
        });
        

//        [_videoInput markAsFinished];
//        NSLog(@"self.writer.status: %ld,error: %@",self->_writer.status,self->_writer.error);
        if(self->_writer && self->_writer.status == AVAssetWriterStatusWriting)
        {
            //            dispatch_async(self.videoQueue, ^{
            [self->_writer finishWritingWithCompletionHandler:^{
//                [[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"isRecord"];
//                [[NSUserDefaults standardUserDefaults] synchronize];
//                [[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"isRecord"];
//                [[NSUserDefaults standardUserDefaults] synchronize];
//                NSLog(@"------------>    停止录制完成,self.txtPath: %@,self->type: %d",self->txtPath,self->type);
//                if(self->type == 1){
//
//                    // 24个字符长度
//                    // 分支，开始计时时间起点，达到100km/h时在视频中的时间点，总共耗时
//                    NSString * seroPrefix = [NSString stringWithFormat:@"[%d,%06.2f,%06.2f,%06.2f]",self->speedSero,self->starttimer-self->videoStarTimer,self->endtimer-self->videoStarTimer,self->endtimer-self->starttimer];
//                    NSLog(@"------------->  写入结束符: %@",seroPrefix);
//                    NSData * seroData = [seroPrefix dataUsingEncoding:NSUTF8StringEncoding];
//                    NSFileHandle * fileHandler = [NSFileHandle fileHandleForWritingAtPath:self->txtPath];
//                    [fileHandler seekToEndOfFile];
//                    [fileHandler writeData:seroData];
//                    [fileHandler closeFile];
//                }else if(self->type == 2){
//                    // 24个字符长度
//                    // 分支，开始计时时间起点，达到100km/h时在视频中的时间点，总共耗时
//                    NSString * seroPrefix = [NSString stringWithFormat:@"[%d,000.00,000.00,000.00]",self->speedSero*10];
//                    NSLog(@"------------->  写入结束符: %@",seroPrefix);
//                    NSData * seroData = [seroPrefix dataUsingEncoding:NSUTF8StringEncoding];
//                    NSFileHandle * fileHandler = [NSFileHandle fileHandleForWritingAtPath:self->txtPath];
//                    [fileHandler seekToEndOfFile];
//                    [fileHandler writeData:seroData];
//                    [fileHandler closeFile];
//
//                }
//                NSLog(@"录制完成");
//                if(self->type == 2){
//                    NSLog(@"--------->  racing模式录制完成，现在进行初始化");
//                    [self initAvassetWritter];
//                    self->isRecoredState = 1;
//                }
            }];
            //            });
        }

        if(self->isShooting == YES){
//            endtimer = [NSDate date].timeIntervalSince1970;
//            [[NSNotificationCenter defaultCenter] postNotificationName:recv_speed_stop_timer_notify_name object:nil userInfo:@{@"time":@(endtimer-starttimer)}];
            self->isShooting = NO;
            
            NSLog(@"停止写入");
  
  
        }
      
//        if(self->video_time_count){
//            dispatch_source_cancel(self->video_time_count);
//            self->video_time_count = nil;
//        }
    }
    
}
-(void)cancelRecored {
    
    if(self->isShooting == YES){
        self->isShooting = NO;
    }
    
    [self->_writer cancelWriting];
    NSFileManager * fm = [NSFileManager defaultManager];
    if([fm fileExistsAtPath:videoPath]){
        NSError * error;
        [fm removeItemAtPath:videoPath error:&error];
        [fm removeItemAtPath:txtPath error:&error];
    }
    
}
#pragma mark - 视频采集回调

- (void)captureOutput:(AVCaptureOutput *)output didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection {
    if(self->isShooting == NO){
        return;
    }
//    NSLog(@"didOutputSampleBuffer");
    //    CMTime time = CMSampleBufferGetPresentationTimeStamp(sampleBuffer);
    bool isvideo = false;
    if(connection == [self.videoOutput connectionWithMediaType:AVMediaTypeVideo]){
        isvideo = true;
    }

    // 2.是正常写入 3.等待2s状态
    if(isRecoredState == 2 || isRecoredState == 3){
        NSLog(@"--------->   isRecoredState: %d",isRecoredState);
        @autoreleasepool {
            if(connection == [self.videoOutput connectionWithMediaType:AVMediaTypeVideo]){
                @synchronized (self) {
                    if(self.videoInput.readyForMoreMediaData){
                        [self.videoInput appendSampleBuffer:sampleBuffer];
                     //   NSLog(@"self.writer.status: %ld,写入视频数据,error: %@,videopath: %@",self->_writer.status,self->_writer.error,videoPath);
                    }else{
                    }
                }
            }
            if(connection == [self.audioOutput connectionWithMediaType:AVMediaTypeAudio]){
                @synchronized (self) {
                    if(self.audioInput.readyForMoreMediaData){
                        [self.audioInput appendSampleBuffer:sampleBuffer];
                      //  NSLog(@"self.writer.status: %ld,写入音频数据,error: %@,videopath: %@",self->_writer.status,self->_writer.error,videoPath);
                    }
                }
            }
        }
    }
    if(isvideo == true){
        [self startRecored:sampleBuffer];
    }

    [self endRecored];

    
    
}

- (void)captureOutput:(AVCaptureOutput *)output didDropSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection API_AVAILABLE(ios(6.0), macCatalyst(14.0)) API_UNAVAILABLE(tvos) {
    
    //NSLog(@"didDropSampleBuffer");
}

- (void)captureOutput:(nonnull AVCaptureFileOutput *)output didFinishRecordingToOutputFileAtURL:(nonnull NSURL *)outputFileURL fromConnections:(nonnull NSArray<AVCaptureConnection *> *)connections error:(nullable NSError *)error {
    
}

@end
