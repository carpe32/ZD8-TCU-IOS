//
//  testObject.m
//  CarLinkChannel
//
//  Created by job on 2023/5/17.
//

#import "testObject.h"
#import <AVFoundation/AVFoundation.h>
#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>

#define weakself    __weak typeof (*&self) weakself;
#define strongerself    __strong typeof (*&self) strongerself;
@implementation testObject

//#define kEffectVideoFileName_Animation @"tmpMov-effect.mov"
//- (void)renderWholeVideo:(AVAsset *)asset{
//    // 1 - Early exit if there's no video file selected
//    if (!asset) {
//        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error" message:@"Please Load a Video Asset First"
//                                                       delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
//        [alert show];
//        return;
//    }
//
//    // 2 - Create AVMutableComposition object. This object will hold your AVMutableCompositionTrack instances.
//    AVMutableComposition *mixComposition = [[AVMutableComposition alloc] init];
//
//    // 3 - Video track
//    AVMutableCompositionTrack *videoTrack = [mixComposition addMutableTrackWithMediaType:AVMediaTypeVideo
//                                                                        preferredTrackID:kCMPersistentTrackID_Invalid];
//    [videoTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, asset.duration)
//                        ofTrack:[[asset tracksWithMediaType:AVMediaTypeVideo] objectAtIndex:0]
//                         atTime:kCMTimeZero error:nil];
//
//    AVMutableCompositionTrack *audioTrack = [mixComposition addMutableTrackWithMediaType:AVMediaTypeAudio preferredTrackID:kCMPersistentTrackID_Invalid];
//    [audioTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, asset.duration) ofTrack:[asset tracksWithMediaType:AVMediaTypeAudio][0] atTime:kCMTimeZero error:nil];
//
//    // 3.1 - Create AVMutableVideoCompositionInstruction
//    AVMutableVideoCompositionInstruction *mainInstruction = [AVMutableVideoCompositionInstruction videoCompositionInstruction];
//    mainInstruction.timeRange = CMTimeRangeMake(kCMTimeZero, asset.duration);
//
//    // 3.2 - Create an AVMutableVideoCompositionLayerInstruction for the video track and fix the orientation.
//    __block     CGSize naturalSize;
//    AVMutableVideoCompositionLayerInstruction *videolayerInstruction = [self transformVideo:asset track:videoTrack isVideoAssetPortrait:^(CGSize finalSize) {
//        naturalSize = finalSize;
//    }];
//    [videolayerInstruction setOpacity:0.0 atTime:asset.duration];
//
//    // 3.3 - Add instructions
//    mainInstruction.layerInstructions = [NSArray arrayWithObjects:videolayerInstruction,nil];
//
//    AVMutableVideoComposition *mainCompositionInst = [AVMutableVideoComposition videoComposition];
//
//
//    float renderWidth, renderHeight;
//    renderWidth = naturalSize.width;
//    renderHeight = naturalSize.height;
//    mainCompositionInst.renderSize = CGSizeMake(renderWidth, renderHeight);
//    mainCompositionInst.instructions = [NSArray arrayWithObject:mainInstruction];
//    mainCompositionInst.frameDuration = CMTimeMake(1, 30);
//
//
//
//    [self applyVideoEffectsWithAnimation:mainCompositionInst size:naturalSize];
//
//
//    NSString *myPathDocs = [NSTemporaryDirectory() stringByAppendingPathComponent:kEffectVideoFileName_Animation];
//    NSURL *url = [NSURL fileURLWithPath:myPathDocs];
//    /*先移除旧文件*/
//    [PublicUIMethod removeFile:url];
//
//    // 5 - Create exporter
//    AVAssetExportSession *exporter = [[AVAssetExportSession alloc] initWithAsset:mixComposition
//                                                                      presetName:AVAssetExportPresetHighestQuality];
//    [self.exportSessions addObject:exporter];
//    exporter.outputURL=url;
//    exporter.outputFileType = AVFileTypeQuickTimeMovie;
//    exporter.shouldOptimizeForNetworkUse = YES;
//    exporter.videoComposition = mainCompositionInst;
//    weakifyself;
//    [exporter exportAsynchronouslyWithCompletionHandler:^{
//        strongifyself;
//        dispatch_async(dispatch_get_main_queue(), ^{
//            switch ([exporter status]) {
//                case AVAssetExportSessionStatusFailed:
//
//                    DDLogWarn(@"render Export failed: %@ and order : %d", [exporter error], 0);
//                    break;
//                case AVAssetExportSessionStatusCancelled:
//
//                    NSLog(@"render Export canceled order : %d", 0);
//                    break;
//                default:
//                {
//                    NSLog(@"'%@' render finish",[myPathDocs lastPathComponent]);
//                    [self pushToPreviePage:myPathDocs];
//                }
//                    break;
//            }
//        });
//    }];
//    [self monitorSingleExporter:exporter];
//}
//
//- (void)applyVideoEffectsWithAnimation:(AVMutableVideoComposition *)composition size:(CGSize)size
//{
//    // Set up layer
//    CALayer *parentLayer = [CALayer layer];
//    CALayer *videoLayer = [CALayer layer];
//    parentLayer.frame = CGRectMake(0, 0, size.width, size.height);
//    videoLayer.frame = CGRectMake(0, 0, size.width, size.height);
//    [parentLayer addSublayer:videoLayer];
//
//
//    /**/
//    CMTime timeFrame = [self frameTime];
//    CGFloat granularity = CMTimeGetSeconds(timeFrame);
//    /*caption layer*/
//    for (int j=0; j<self.effectsArray.count; j++) {
//        NSArray* effectSeries = (NSArray *)self.effectsArray[j];
//        FSVideoCaptionDescriptionModel *description = [[effectSeries firstObject] as:FSVideoCaptionDescriptionModel.class];
//        NSArray *captions = [description reOrder];
//        if (!captions || captions.count == 0) {
//            //没有字幕就别瞎搞了
//            continue;
//        }
//
//        FSCaptionModel *captionModel = captions.firstObject;
//        UIImage *image = captionModel.image;/*将水印生成图片，采用图片方法添加水印*/
//        CGFloat scaleY = captionModel.scaleY;
//        CGFloat scaleHeight = captionModel.scaleHeight;
//        CALayer *layer = [CALayer layer];
//        layer.frame = CGRectMake(0, size.height * scaleY, size.width, size.height * scaleHeight);
//        layer.contents = (__bridge id)image.CGImage;
//
//        /*
//         字幕动画由两个组成:
//         1. 显示所有字幕<动画开始前保持，初始状态。动画时间是0.结束后不移除动画>
//         2. 隐藏字幕，到最后。
//         */
//        CGFloat showStartTime = description.startIndex * granularity;
//        CGFloat hiddenAginStartTime = showStartTime + effectSeries.count*granularity;
//
//        CABasicAnimation *animation = nil;
//        if (showStartTime > 0) {
//            animation = [CABasicAnimation animationWithKeyPath:@"opacity"];
//            animation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionDefault];
//            [animation setFromValue:[NSNumber numberWithFloat:0.0]];
//            [animation setToValue:[NSNumber numberWithFloat:1.0]];
//            [animation setBeginTime:showStartTime];
//            [animation setFillMode:kCAFillModeBackwards];/*must be backwards*/
//            [animation setRemovedOnCompletion:NO];/*must be no*/
//            [layer addAnimation:animation forKey:@"animateOpacityShow"];
//        }
//        /*最后一个字幕片段不是整的1.5s或者5秒。就不隐藏动画了*/
//        if (j != self.effectsArray.count-1) {
//            animation = [CABasicAnimation animationWithKeyPath:@"opacity"];
//            animation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionDefault];
//            [animation setFromValue:[NSNumber numberWithFloat:1.0]];
//            [animation setToValue:[NSNumber numberWithFloat:0.0]];
//            [animation setBeginTime:hiddenAginStartTime];
//            [animation setRemovedOnCompletion:NO];/*must be no*/
//            [animation setFillMode:kCAFillModeForwards];
//            [layer addAnimation:animation forKey:@"animateOpacityHiddenAgin"];
//        }
//
//        [parentLayer addSublayer:layer];
//    }
//
//    parentLayer.geometryFlipped = YES;
//    composition.animationTool = [AVVideoCompositionCoreAnimationTool
//                                 videoCompositionCoreAnimationToolWithPostProcessingAsVideoLayer:videoLayer inLayer:parentLayer];
//}
//
//- (void)monitorSingleExporter:(AVAssetExportSession *)exporter{
//    double delay = 1.0;
//    int64_t delta = (int64_t)delay * NSEC_PER_SEC;
//    dispatch_time_t poptime = dispatch_time(DISPATCH_TIME_NOW, delta);
//    dispatch_after(poptime, dispatch_get_main_queue(), ^{
//        if (exporter.status == AVAssetExportSessionStatusExporting) {
//            NSLog(@"whole progress is %f",  exporter.progress);
//            [self monitorSingleExporter:exporter];
//        }
//    });
//}
//-(AVMutableVideoCompositionLayerInstruction *) transformVideo:(AVAsset *)asset track:(AVMutableCompositionTrack *)firstTrack isVideoAssetPortrait:(void(^)(CGSize size))block{
//    AVMutableVideoCompositionLayerInstruction *videolayerInstruction = [AVMutableVideoCompositionLayerInstruction videoCompositionLayerInstructionWithAssetTrack:firstTrack];
//
//
//    AVAssetTrack *videoAssetTrack = [[asset tracksWithMediaType:AVMediaTypeVideo] objectAtIndex:0];
//    UIImageOrientation videoAssetOrientation_  = UIImageOrientationUp;
//    BOOL isVideoAssetPortrait_  = NO;
//    CGAffineTransform videoTransform = videoAssetTrack.preferredTransform;
//    if (videoTransform.a == 0 && videoTransform.b == 1.0 && videoTransform.c == -1.0 && videoTransform.d == 0) {
//        videoAssetOrientation_ = UIImageOrientationRight;
//        videoTransform = CGAffineTransformMakeRotation(M_PI_2);
//
//        videoTransform = CGAffineTransformTranslate(videoTransform, 0, -videoAssetTrack.naturalSize.height);
//        isVideoAssetPortrait_ = YES;
//    }
//    if (videoTransform.a == 0 && videoTransform.b == -1.0 && videoTransform.c == 1.0 && videoTransform.d == 0) {
//        videoAssetOrientation_ =  UIImageOrientationLeft;
//        //这个地方很恶心，涉及到reveal看不到的坐标系
//        videoTransform = CGAffineTransformMakeRotation(-M_PI_2);
//        videoTransform = CGAffineTransformTranslate(videoTransform, - videoAssetTrack.naturalSize.width, 0);
//        isVideoAssetPortrait_ = YES;
//    }
//    if (videoTransform.a == 1.0 && videoTransform.b == 0 && videoTransform.c == 0 && videoTransform.d == 1.0) {
//        videoAssetOrientation_ =  UIImageOrientationUp;
//    }
//    if (videoTransform.a == -1.0 && videoTransform.b == 0 && videoTransform.c == 0 && videoTransform.d == -1.0) {
//        videoTransform = CGAffineTransformMakeRotation(-M_PI);
//        videoTransform = CGAffineTransformTranslate(videoTransform, -videoAssetTrack.naturalSize.width, -videoAssetTrack.naturalSize.height);
////        videoTransform = CGAffineTransformRotate(videoTransform, M_PI/180*45);
//        videoAssetOrientation_ = UIImageOrientationDown;
//    }
//    [videolayerInstruction setTransform:videoTransform atTime:kCMTimeZero];
//
//    CGSize naturalSize;
//    if(isVideoAssetPortrait_){
//        naturalSize = CGSizeMake(videoAssetTrack.naturalSize.height, videoAssetTrack.naturalSize.width);
//    } else {
//        naturalSize = videoAssetTrack.naturalSize;
//    }
//
//
//    if(block){
//        block(naturalSize);
//    }
//    return videolayerInstruction;
//}
//
//



#pragma mark CorAnimation
+ (void)addWaterMarkTypeWithCorAnimationAndInputVideoURL:(NSURL*)InputURL WithCompletionHandler:(void (^)(NSURL* outPutURL, int code))handler{
    NSDictionary *opts = [NSDictionary dictionaryWithObject:@(YES) forKey:AVURLAssetPreferPreciseDurationAndTimingKey];
    AVAsset *videoAsset = [AVURLAsset URLAssetWithURL:InputURL options:opts];
    AVMutableComposition *mixComposition = [[AVMutableComposition alloc] init];
    AVMutableCompositionTrack *videoTrack = [mixComposition addMutableTrackWithMediaType:AVMediaTypeVideo
                                                                        preferredTrackID:kCMPersistentTrackID_Invalid];
    NSError *errorVideo = [NSError new];
    AVAssetTrack *assetVideoTrack = [[videoAsset tracksWithMediaType:AVMediaTypeVideo]firstObject];
    CMTime endTime = assetVideoTrack.asset.duration;
    
    
    BOOL bl = [videoTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, endTime)
                                  ofTrack:assetVideoTrack
                                   atTime:kCMTimeZero error:&errorVideo];
    
    AVMutableCompositionTrack *audioTrack = [mixComposition addMutableTrackWithMediaType:AVMediaTypeAudio preferredTrackID:kCMPersistentTrackID_Invalid];

    CMTime audioTime = videoAsset.duration;
    [audioTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, audioTime) ofTrack: [[videoAsset tracksWithMediaType:AVMediaTypeAudio]firstObject] atTime:kCMTimeZero error:nil];
//

    videoTrack.preferredTransform = assetVideoTrack.preferredTransform;
    NSLog(@"errorVideo:%ld%d",errorVideo.code,bl);
 
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    formatter.dateFormat = @"yyyyMMddHHmmss";
    NSString *outPutFileName = [formatter stringFromDate:[NSDate dateWithTimeIntervalSinceNow:0]];
    NSString *myPathDocs =  [documentsDirectory stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.mp4",outPutFileName]];
    NSURL* outPutVideoUrl = [NSURL fileURLWithPath:myPathDocs];
    
    CGSize videoSize = [videoTrack naturalSize];
    
    UIFont *font = [UIFont systemFontOfSize:60.0];
    CATextLayer *aLayer = [[CATextLayer alloc] init];
    [aLayer setFontSize:60];
    [aLayer setString:@"H"];
    [aLayer setAlignmentMode:kCAAlignmentCenter];
    [aLayer setForegroundColor:[[UIColor greenColor] CGColor]];
    [aLayer setBackgroundColor:[UIColor clearColor].CGColor];
    CGSize textSize = [@"H" sizeWithAttributes:[NSDictionary dictionaryWithObjectsAndKeys:font,NSFontAttributeName, nil]];
    [aLayer setFrame:CGRectMake(240, 470, textSize.width, textSize.height)];
    aLayer.anchorPoint = CGPointMake(0.5, 1.0);
    
    CATextLayer *bLayer = [[CATextLayer alloc] init];
    [bLayer setFontSize:60];
    [bLayer setString:@"E"];
    [bLayer setAlignmentMode:kCAAlignmentCenter];
    [bLayer setForegroundColor:[[UIColor greenColor] CGColor]];
    [bLayer setBackgroundColor:[UIColor clearColor].CGColor];
    CGSize textSizeb = [@"E" sizeWithAttributes:[NSDictionary dictionaryWithObjectsAndKeys:font,NSFontAttributeName, nil]];
    [bLayer setFrame:CGRectMake(240 + textSize.width, 470 , textSizeb.width, textSizeb.height)];
    bLayer.anchorPoint = CGPointMake(0.5, 1.0);
    
    CATextLayer *cLayer = [[CATextLayer alloc] init];
    [cLayer setFontSize:60];
    [cLayer setString:@"L"];
    [cLayer setAlignmentMode:kCAAlignmentCenter];
    [cLayer setForegroundColor:[[UIColor greenColor] CGColor]];
    [cLayer setBackgroundColor:[UIColor clearColor].CGColor];
    CGSize textSizec = [@"L" sizeWithAttributes:[NSDictionary dictionaryWithObjectsAndKeys:font,NSFontAttributeName, nil]];
    [cLayer setFrame:CGRectMake(240 + textSizeb.width + textSize.width, 470 , textSizec.width, textSizec.height)];
    cLayer.anchorPoint = CGPointMake(0.5, 1.0);
    
    CATextLayer *dLayer = [[CATextLayer alloc] init];
    [dLayer setFontSize:60];
    [dLayer setString:@"L"];
    [dLayer setAlignmentMode:kCAAlignmentCenter];
    [dLayer setForegroundColor:[[UIColor greenColor] CGColor]];
    [dLayer setBackgroundColor:[UIColor clearColor].CGColor];
    CGSize textSized = [@"L" sizeWithAttributes:[NSDictionary dictionaryWithObjectsAndKeys:font,NSFontAttributeName, nil]];
    [dLayer setFrame:CGRectMake(240 + textSizec.width+ textSizeb.width + textSize.width, 470 , textSized.width, textSized.height)];
    dLayer.anchorPoint = CGPointMake(0.5, 1.0);
    
    CATextLayer *eLayer = [[CATextLayer alloc] init];
    [eLayer setFontSize:60];
    [eLayer setString:@"O"];
    [eLayer setAlignmentMode:kCAAlignmentCenter];
    [eLayer setForegroundColor:[[UIColor greenColor] CGColor]];
    [eLayer setBackgroundColor:[UIColor clearColor].CGColor];
    CGSize textSizede = [@"O" sizeWithAttributes:[NSDictionary dictionaryWithObjectsAndKeys:font,NSFontAttributeName, nil]];
    [eLayer setFrame:CGRectMake(240 + textSized.width + textSizec.width+ textSizeb.width + textSize.width, 470 , textSizede.width, textSizede.height)];
    eLayer.anchorPoint = CGPointMake(0.5, 1.0);
    
    CABasicAnimation* basicAni = [CABasicAnimation animationWithKeyPath:@"transform.scale"];
    basicAni.fromValue = @(1.0f);
    basicAni.toValue = @(0.f);
    basicAni.beginTime = AVCoreAnimationBeginTimeAtZero;
    basicAni.duration = 2.0f;
//    basicAni.repeatCount = HUGE_VALF;
    basicAni.repeatCount = 2;
    basicAni.removedOnCompletion = NO;
    basicAni.fillMode = kCAFillModeForwards;
    [aLayer addAnimation:basicAni forKey:nil];
    [bLayer addAnimation:basicAni forKey:nil];
    [cLayer addAnimation:basicAni forKey:nil];
    [dLayer addAnimation:basicAni forKey:nil];
    [eLayer addAnimation:basicAni forKey:nil];
    
    CALayer *parentLayer = [CALayer layer];
    CALayer *videoLayer = [CALayer layer];
    parentLayer.frame = CGRectMake(0, 0, videoSize.width, videoSize.height);
    videoLayer.frame = CGRectMake(0, 0, videoSize.width, videoSize.height);
    [parentLayer addSublayer:videoLayer];
    [parentLayer addSublayer:aLayer];
    [parentLayer addSublayer:bLayer];
    [parentLayer addSublayer:cLayer];
    [parentLayer addSublayer:dLayer];
    [parentLayer addSublayer:eLayer];
    
    CALayer * bgLayer = [CALayer layer];
    bgLayer.frame = CGRectMake(0, 200, 300, 20);
    bgLayer.backgroundColor = [UIColor orangeColor].CGColor;
    [parentLayer addSublayer:bgLayer];
    
    for (int i = 0; i < 100; i++) {
        
        NSString * text = [NSString stringWithFormat:@"%d",i];
        
        eLayer = [[CATextLayer alloc] init];
        [eLayer setFontSize:20];
        [eLayer setString:text];
        [eLayer setAlignmentMode:kCAAlignmentCenter];
        [eLayer setForegroundColor:[[UIColor redColor] CGColor]];
        [eLayer setBackgroundColor:[UIColor clearColor].CGColor];
        CGSize textSizede = [ text sizeWithAttributes:[NSDictionary dictionaryWithObjectsAndKeys:font,NSFontAttributeName, nil]];
        [eLayer setFrame:CGRectMake(360 + textSized.width + textSizec.width+ textSizeb.width + textSize.width, 400 , textSizede.width, textSizede.height)];
        eLayer.anchorPoint = CGPointMake(0.5, 1.0);
     
        CABasicAnimation *  animation = nil;
        
        animation = [CABasicAnimation animationWithKeyPath:@"opacity"];
        animation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionDefault];
        [animation setFromValue:[NSNumber numberWithFloat:0.0]];
        [animation setToValue:[NSNumber numberWithFloat:1.0]];
        [animation setBeginTime:i*0.4];
        [animation setDuration:0.2];
        [animation setFillMode:kCAFillModeBackwards];/*must be backwards*/
        [animation setRemovedOnCompletion:NO];/*must be no*/
        [eLayer addAnimation:animation forKey:@"animateOpacityShow"];
        
        
        
        animation = [CABasicAnimation animationWithKeyPath:@"opacity"];
        animation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionDefault];
        [animation setFromValue:[NSNumber numberWithFloat:1.0]];
        [animation setToValue:[NSNumber numberWithFloat:0.0]];
        [animation setBeginTime:i*0.4+0.2];
        [animation setDuration:0.2];
        [animation setRemovedOnCompletion:NO];/*must be no*/
        [animation setFillMode:kCAFillModeForwards];
        [eLayer addAnimation:animation forKey:@"animateOpacityHiddenAgin"];
        
        [parentLayer addSublayer:eLayer];
        
        
    }

    
    AVMutableVideoComposition* videoComp = [AVMutableVideoComposition videoComposition];
    videoComp.renderSize = videoSize;
    parentLayer.geometryFlipped = true;
    videoComp.frameDuration = CMTimeMake(1, 30);
    videoComp.animationTool = [AVVideoCompositionCoreAnimationTool videoCompositionCoreAnimationToolWithPostProcessingAsVideoLayer:videoLayer inLayer:parentLayer];
    AVMutableVideoCompositionInstruction* instruction = [AVMutableVideoCompositionInstruction videoCompositionInstruction];
    
//     tm = endTime;
//    tm.value = tm.value / 2;
//
    instruction.timeRange = CMTimeRangeMake(kCMTimeZero, endTime);
    AVMutableVideoCompositionLayerInstruction* layerInstruction = [AVMutableVideoCompositionLayerInstruction videoCompositionLayerInstructionWithAssetTrack:videoTrack];
    instruction.layerInstructions = [NSArray arrayWithObjects:layerInstruction, nil];
    
    AVMutableVideoCompositionInstruction* instruction2 = [AVMutableVideoCompositionInstruction videoCompositionInstruction];
    
    instruction2.timeRange = CMTimeRangeMake(kCMTimeZero, audioTime);
    
    videoComp.instructions = [NSArray arrayWithObjects: instruction,nil];
    
    
    AVAssetExportSession* exporter = [[AVAssetExportSession alloc] initWithAsset:mixComposition
                                                                      presetName:AVAssetExportPresetHighestQuality];
    exporter.outputURL=outPutVideoUrl;
    exporter.outputFileType = AVFileTypeMPEG4;
    exporter.shouldOptimizeForNetworkUse = YES;
    exporter.videoComposition = videoComp;
    [exporter exportAsynchronouslyWithCompletionHandler:^{
        dispatch_async(dispatch_get_main_queue(), ^{
            //这里是输出视频之后的操作，做你想做的
            NSLog(@"输出视频地址:%@ andCode:%@",myPathDocs,exporter.error);
            handler(outPutVideoUrl,(int)exporter.error.code);
        });
    }];
}

@end
