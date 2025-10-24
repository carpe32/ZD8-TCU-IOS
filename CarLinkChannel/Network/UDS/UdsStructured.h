//
//  UdsStructured.h
//  CarLinkChannel
//
//  Created by 刘润泽 on 2024/9/23.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface UdsStructured : NSObject

@property (nonatomic, assign) uint8_t transferDirection; // 传输方向
@property (nonatomic, assign) uint8_t sourceAddress;     // 源地址
@property (nonatomic, assign) uint8_t destinationAddress;// 目标地址
@property (nonatomic, assign) uint8_t functionID;        // 功能ID
@property (nonatomic, assign) uint8_t subFunctionID;     // 二级ID
@property (nonatomic, strong) NSData *payload;           // 有效数据

- (instancetype)initWithTransferDirection:(uint8_t)transferDirection
                             sourceAddress:(uint8_t)sourceAddress
                        destinationAddress:(uint8_t)destinationAddress
                                functionID:(uint8_t)functionID
                             subFunctionID:(uint8_t)subFunctionID
                                  payload:(NSData *)payload;
@end

NS_ASSUME_NONNULL_END
