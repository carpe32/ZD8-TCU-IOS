//
//  NetworkTool.h
//  CarLinkChannel
//
//  Created by 刘润泽 on 2024/9/23.
//

#import <Foundation/Foundation.h>
#import <ifaddrs.h>
#import <net/if.h>
#import <netdb.h>
#import <netinet/ip.h>
#import <net/ethernet.h>
#import <net/if_dl.h>
#import <Network/Network.h>
#import <arpa/inet.h>
NS_ASSUME_NONNULL_BEGIN

@interface NetworkTool : NSObject
+(NSString *)getEthNetworkIp;
@end

NS_ASSUME_NONNULL_END
