//
//  UDSResponse.h
//  CarLinkChannel
//
//  Created by 刘润泽 on 2024/9/23.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN
typedef NS_ENUM(NSInteger, UdsResponseStatus) {
    UdsResponseStatusSuccess,   // 收到合法数据
    UdsResponseStatusTimeout,   // 超时
    UdsResponseStatusError      // UDS错误
};

@interface UDSResponse : NSObject
@property (nonatomic, assign) UdsResponseStatus status;
@property (nonatomic, strong) NSData *payload;
@property(nonatomic)uint8_t OperationFID;
@end

@interface UDSMultipleResponse : NSObject
@property (nonatomic)uint8_t ECUID;
@property (nonatomic, strong) NSData *Data;
@end


NS_ASSUME_NONNULL_END
