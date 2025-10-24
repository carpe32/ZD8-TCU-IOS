//
//  PackageDownloadInteractive.h
//  CarLinkChannel
//
//  Created by job on 2023/3/30.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface PackageDownloadInteractive : NSObject

+(PackageDownloadInteractive*)getInteractive;
-(void)loadFileWithUrl:(NSString * )fileUrl;
@end

NS_ASSUME_NONNULL_END
