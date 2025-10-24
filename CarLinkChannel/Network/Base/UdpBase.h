//
//  UdpBase.h
//  CarLinkChannel
//
//  Created by 刘润泽 on 2024/9/23.
//

#import <Foundation/Foundation.h>
#import "GCDAsyncUdpSocket.h"
NS_ASSUME_NONNULL_BEGIN

@protocol UdpBackDelegate <NSObject>
- (void)didReceiveVehicleIPInfo:(NSString *)VehicleIp :(NSString *)port;

@end

@interface UdpBase : NSObject
-(instancetype)initWithIp:(NSString *)LocalIp;


@property (nonatomic, weak) id<UdpBackDelegate> delegate;
@end

NS_ASSUME_NONNULL_END
