//
//  testObject.h
//  CarLinkChannel
//
//  Created by job on 2023/5/17.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface testObject : NSObject
@property(strong,nonatomic) NSMutableArray * exportSessions;
+ (void)addWaterMarkTypeWithCorAnimationAndInputVideoURL:(NSURL*)InputURL WithCompletionHandler:(void (^)(NSURL* outPutURL, int code))handler;
@end

NS_ASSUME_NONNULL_END
