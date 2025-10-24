//
//  ReplayKitManager.m
//  CarLinkChannel
//
//  Created by 刘润泽 on 2025/1/2.
//

#import "ReplayKitManager.h"
#import <ReplayKit/ReplayKit.h>
#import <Photos/Photos.h>


@implementation ReplayKitManager

- (void)startRecording {
    RPScreenRecorder *recorder = [RPScreenRecorder sharedRecorder];
    recorder.microphoneEnabled = YES; // 启用麦克风录音

    if (recorder.isAvailable) {
        [recorder startRecordingWithHandler:^(NSError * _Nullable error) {
            if (!error) {
                NSLog(@"Recording started successfully!");
            } else {
                NSLog(@"Failed to start recording: %@", error.localizedDescription);
            }
        }];
    } else {
        NSLog(@"Screen recording is not available on this device.");
    }
}


- (void)stopRecordingAndSaveToPhotos {
    RPScreenRecorder *recorder = [RPScreenRecorder sharedRecorder];

    [recorder stopRecordingWithHandler:^(RPPreviewViewController * _Nullable previewViewController, NSError * _Nullable error) {
        if (!error && previewViewController) {
            // 获取录制的文件 URL
            [self extractVideoFromPreviewController:previewViewController];
        } else {
            NSLog(@"Failed to stop recording: %@", error.localizedDescription);
        }
    }];
}
- (void)extractVideoFromPreviewController:(RPPreviewViewController *)previewController {
    // 通过 KVC 获取视频文件的 URL
    NSURL *videoURL = [previewController valueForKey:@"movieURL"];
    if (videoURL) {
        [self saveVideoToPhotoLibrary:videoURL];
    } else {
        NSLog(@"Failed to extract video URL from RPPreviewViewController.");
    }
}

- (void)saveVideoToPhotoLibrary:(NSURL *)videoURL {
    [[PHPhotoLibrary sharedPhotoLibrary] performChanges:^{
        [PHAssetChangeRequest creationRequestForAssetFromVideoAtFileURL:videoURL];
    } completionHandler:^(BOOL success, NSError * _Nullable error) {
        if (success) {
            NSLog(@"Video saved to photo library successfully.");
        } else {
            NSLog(@"Failed to save video to photo library: %@", error.localizedDescription);
        }
    }];
}
@end
