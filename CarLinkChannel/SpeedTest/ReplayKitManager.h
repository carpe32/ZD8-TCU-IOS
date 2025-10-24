//
//  ReplayKitManager.h
//  CarLinkChannel
//
//  Created by 刘润泽 on 2025/1/2.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface ReplayKitManager : NSObject


- (void)startRecording;
- (void)stopRecordingAndSaveToPhotos;


@end

NS_ASSUME_NONNULL_END
