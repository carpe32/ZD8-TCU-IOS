//
//  FlashInfo.h
//  CarLinkChannel
//
//  Created by 刘润泽 on 2024/9/23.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface FlashInfo : NSObject
@property(nonatomic)uint8_t index;
@property(nonatomic)NSData *data;
@end

NS_ASSUME_NONNULL_END
