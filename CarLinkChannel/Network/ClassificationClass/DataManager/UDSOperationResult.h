//
//  UDSOperationResult.h
//  TTS Tuning
//
//  Created by 刘润泽 on 2024/9/3.
//

#import <Foundation/Foundation.h>
#import "VehicleTypeProgramming.h"
NS_ASSUME_NONNULL_BEGIN

@interface UDSOperationResult : NSObject

- (OperationResult *)executeOperationWithBlock:(OperationResult *(^)(void))operationBlock delegate:(id<FlashFeedbackDelegate>)delegate;
- (BOOL)executeOperations:(NSArray<OperationResult * (^)(void)> *)operations delegate:(id<FlashFeedbackDelegate>)delegate;

@end

NS_ASSUME_NONNULL_END
