//
//  OperationResult.h
//  CarLinkChannel
//
//  Created by 刘润泽 on 2024/9/23.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface OperationResult : NSObject
@property(nonatomic)BOOL state;
@property(nonatomic)NSString *operationName;
@property(nonatomic)NSString *failureReason;
@property(nonatomic)NSString *OtherInfo;
@property(nonatomic)NSData *receiveData;
@property(nonatomic)uint8_t OperationFID;

@property(nonatomic)bool CheckOperation;
@end

NS_ASSUME_NONNULL_END
