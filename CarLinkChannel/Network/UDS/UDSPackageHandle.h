//
//  UDSPackageHandle.h
//  CarLinkChannel
//
//  Created by 刘润泽 on 2024/9/23.
//

#import <Foundation/Foundation.h>
#import "UdsStructured.h"
#import "UDSQueue.h"

NS_ASSUME_NONNULL_BEGIN

@interface UDSPackageHandle : NSObject
-(void)InputData:(NSData *)UdsOriginalData;

+ (NSData *)createUDSSendPacket:(uint8_t)Destaddr Functionid:(uint8_t)Fid SubFunctionId:(NSData *)Sid parameterData:(NSData *)parameterData;
- (void)registerDataReceivedCallback:(void (^)(UdsStructured *element))callback;
@end

NS_ASSUME_NONNULL_END
