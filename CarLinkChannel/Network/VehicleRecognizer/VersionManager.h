//
//  VersionManager.h
//  CarLinkChannel
//
//  Created by 刘润泽 on 2025/4/22.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface VersionManager : NSObject
+ (instancetype)sharedInstance;
-(bool)isNeedFlashBase:(NSArray *)svt;
@end

NS_ASSUME_NONNULL_END
