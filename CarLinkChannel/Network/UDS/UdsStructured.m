//
//  UdsStructured.m
//  CarLinkChannel
//
//  Created by 刘润泽 on 2024/9/23.
//

#import "UdsStructured.h"

@implementation UdsStructured
- (instancetype)initWithTransferDirection:(uint8_t)transferDirection
                             sourceAddress:(uint8_t)sourceAddress
                        destinationAddress:(uint8_t)destinationAddress
                                functionID:(uint8_t)functionID
                             subFunctionID:(uint8_t)subFunctionID
                                   payload:(NSData *)payload {
    self = [super init];
    if (self) {
        _transferDirection = transferDirection;
        _sourceAddress = sourceAddress;
        _destinationAddress = destinationAddress;
        _functionID = functionID;
        _subFunctionID = subFunctionID;
        _payload = payload;
    }
    return self;
}
@end
