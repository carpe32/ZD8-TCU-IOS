//
//  UIImage+ImageBuffer.m
//  MCAudioInputQueue
//
//  Created by zhangyj on 16/3/24.
//  Copyright © 2016年 Chengyin. All rights reserved.
//

#import "UIImage+ImageBuffer.h"

@implementation UIImage (ImageBuffer)

+ (UIImage *)imageWithColor:(UIColor *)color {
    return [self imageWithColor:color size:CGSizeMake(1., 1.)];
}

+ (UIImage *)imageWithColor:(UIColor *)color size:(CGSize)size {
    CGRect rect = CGRectMake(0.0f, 0.0f, size.width, size.height);
    UIGraphicsBeginImageContext(rect.size);
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetFillColorWithColor(context, [color CGColor]);
    CGContextFillRect(context, rect);
    
    UIImage *aImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return aImage;
}

+ (instancetype)getImageFromImageBuffer:(CVImageBufferRef)imageBuffer {
    CVImageBufferRef buffer = imageBuffer;
    
    CVPixelBufferLockBaseAddress(buffer, 0);
    
    //從 CVImageBufferRef 取得影像的細部資訊
    uint8_t *base;
    size_t width, height, bytesPerRow;
    base = CVPixelBufferGetBaseAddress(buffer);
    width = CVPixelBufferGetWidth(buffer);
    height = CVPixelBufferGetHeight(buffer);
    bytesPerRow = CVPixelBufferGetBytesPerRow(buffer);
    
    //利用取得影像細部資訊格式化 CGContextRef
    CGColorSpaceRef colorSpace;
    CGContextRef cgContext;
    colorSpace = CGColorSpaceCreateDeviceRGB();
    cgContext = CGBitmapContextCreate (base, width, height, 8, bytesPerRow, colorSpace, kCGBitmapByteOrder32Little | kCGImageAlphaPremultipliedFirst);
    
    CGColorSpaceRelease(colorSpace);
    
    //透過 CGImageRef 將 CGContextRef 轉換成 UIImage
    CGImageRef cgImage;
    UIImage *image;
    cgImage = CGBitmapContextCreateImage(cgContext);
    image = [UIImage imageWithCGImage:cgImage];
    
    CGImageRelease(cgImage);
    CGContextRelease(cgContext);
    
    CVPixelBufferUnlockBaseAddress(buffer, 0);
    
    return image;
}

+ (instancetype)getImageFromPixelBuffer:(CVPixelBufferRef)imageBuffer {
    CIImage *ciimage = [[CIImage alloc]initWithCVPixelBuffer:imageBuffer];
    
    NSMutableDictionary *options = [NSMutableDictionary dictionary];
    [options setObject: [NSNull null] forKey: kCIContextWorkingColorSpace];
    CIContext *cictx = [CIContext contextWithEAGLContext:[[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2] options:options];
    CGImageRef cgimage = [cictx createCGImage:ciimage fromRect:ciimage.extent];
    UIImage *image = [UIImage imageWithCGImage:cgimage];
    CGImageRelease(cgimage);
    return image;
}

- (UIImage *)imageByScalingToSize:(CGSize)targetSize {
    UIImage *newImage;
    
    UIGraphicsBeginImageContext(targetSize);
    
    CGRect thumbnailRect = CGRectZero;
    thumbnailRect.origin = CGPointZero;
    thumbnailRect.size.width  = targetSize.width;
    thumbnailRect.size.height = targetSize.height;
    
    [self drawInRect:thumbnailRect];
    
    newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return newImage;
}


@end
