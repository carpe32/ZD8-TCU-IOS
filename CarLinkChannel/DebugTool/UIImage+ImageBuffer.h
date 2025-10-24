//
//  UIImage+ImageBuffer.h
//  MCAudioInputQueue
//
//  Created by zhangyj on 16/3/24.
//  Copyright © 2016年 Chengyin. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIImage (ImageBuffer)

+ (instancetype)getImageFromImageBuffer:(CVImageBufferRef)imageBuffer;
+ (instancetype)getImageFromPixelBuffer:(CVPixelBufferRef)imageBuffer;

- (UIImage *)imageByScalingToSize:(CGSize)targetSize;

+ (UIImage *)imageWithColor:(UIColor *)color;

@end
