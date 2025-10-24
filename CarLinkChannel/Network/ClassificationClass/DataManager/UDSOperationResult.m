//
//  UDSOperationResult.m
//  TTS Tuning
//
//  Created by 刘润泽 on 2024/9/3.
//

#import "UDSOperationResult.h"

@implementation UDSOperationResult

- (OperationResult *)executeOperationWithBlock:(OperationResult *(^)(void))operationBlock delegate:(id<FlashFeedbackDelegate>)delegate {
    OperationResult *result = operationBlock();
    if(result.state)
    {
        if(result.CheckOperation)
        {
            const uint8_t *RecBuffer = [result.receiveData bytes];

            if(RecBuffer[2] != 00)
            {
                result.failureReason = OperationBasicDeficiency;
                [delegate didEncounterError:result.operationName ErrorInfo:result.failureReason ErrorData:result.receiveData ErrorFID:result.OperationFID];
                result.state = NO;
                return result;
            }
        }
        [delegate didUpdateProgress:result.operationName Info:result.OtherInfo];
    }
    else
    {
        [delegate didEncounterError:result.operationName ErrorInfo:result.failureReason ErrorData:result.receiveData ErrorFID:result.OperationFID];
    }
    return result;
}

- (BOOL)executeOperations:(NSArray<OperationResult * (^)(void)> *)operations delegate:(id<FlashFeedbackDelegate>)delegate {
    for (OperationResult * (^operationBlock)(void) in operations) {
        OperationResult *result = [self executeOperationWithBlock:operationBlock delegate:delegate];
        if (!result.state) {
            return NO; // 如果操作失败，返回NO
        }
        usleep(20000);
    }
    return YES; // 所有操作成功执行
}

@end
