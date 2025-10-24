//
//  SpeedTestInteractive.h
//  CarLinkChannel
//
//  Created by job on 2023/4/25.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface SpeedTestInteractive : NSObject <AVAssetWriterDelegate>
-(void)loadCaptureWithView:(UIView *)view;
-(void)initAudioInput:(UIView *)view;
-(void)CarSpeedSero:(int)sero CarSpeed:(int)sudu;
-(void)destoryTimer;
@end

NS_ASSUME_NONNULL_END
