//
//  TcpSpeedTestHandler.h
//  CarLinkChannel
//
//  Created by job on 2023/4/25.
//

#import <Foundation/Foundation.h>
#import "AutoNetworkService.h"
NS_ASSUME_NONNULL_BEGIN

@interface TcpSpeedTestHandler : NSObject

-(BOOL)startSpeedTest;
-(void)sendSpeedTestPacket2;
-(void)sendSpeedTestPacket3Sero2;
-(void)sendspeedTest;
-(NSDictionary *)Sero1parseSpeedTestData:(NSString *)dataString;
-(NSDictionary *)Sero2parseSpeedTestData:(NSString *)dataString;

- (NSDictionary *)ReadSpeedDataFromVehicle:(BOOL)state;
@end

NS_ASSUME_NONNULL_END
