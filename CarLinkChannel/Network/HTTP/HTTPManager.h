//
//  HTTPManager.h
//  TTS Tuning
//
//  Created by 刘润泽 on 2024/8/13.
//

#import <Foundation/Foundation.h>
#import <libkern/OSAtomic.h>
#import <ifaddrs.h>
#import <resolv.h>
#import <arpa/inet.h>
#import <net/if.h>
#import <netdb.h>
#import <netinet/ip.h>
#import <net/ethernet.h>
#import <net/if_dl.h>
#import <Network/Network.h>
#import <pthread.h>
#import <os/lock.h>

NS_ASSUME_NONNULL_BEGIN

@interface HTTPManager : NSObject
typedef  void(^datablock)(id data);
typedef  void(^errblock)(NSError * error);
-(void)sendGetWithUrl:(NSString *)url doneBlock:(datablock)completionHandler errBlock:(errblock)errorBlock;
+ (void) requestLocalNetworkAuthorization:(void(^)(BOOL isAuth)) complete;
- (void)sendJSONRequestWithURL:(NSString *)urlString
                          json:(NSDictionary *)jsonDict
                    completion:(void (^)(NSData *data, NSURLResponse *response, NSError *error))completion;
@end

NS_ASSUME_NONNULL_END
