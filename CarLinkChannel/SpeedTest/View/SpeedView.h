//
//  SpeedView.h
//  CarLinkChannel
//
//  Created by job on 2023/5/22.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface SpeedView : UIView
-(void)addVideoMarkVideoPath:(NSString *)videoPath  WithCompletionHandler:(void (^)(NSURL* outPutURL, int code))handler;
-(void)addAllVideoSegmentsWithOriginVideoName:(NSString *)fileName;
//+ (void)addWaterMarkTypeWithCorAnimationAndInputVideoURL:(NSURL*)InputURL WithCompletionHandler:(void (^)(NSURL* outPutURL, int code))handler;
-(void)addTimerLabelWithCompleteAssetUrl:(NSURL *)url;

-(void)removesignal;
@end

NS_ASSUME_NONNULL_END
