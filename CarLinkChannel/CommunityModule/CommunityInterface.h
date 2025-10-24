//
//  CommunityInterface.h
//  CarLinkChannel
//
//  Created by job on 2023/3/27.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface CommunityInterface : NSObject

+ (void) requestLocalNetworkAuthorization:(void(^)(BOOL isAuth)) complete;

+(instancetype)getInstance;

-(BOOL)getEthNetworkIp;

-(void)uninitUdpSocket;

-(void)initUdpSocket;

-(NSDictionary *)ipDict;

-(void)sendUdpBoardCast;

-(void)uninitTcpSocket;

-(BOOL)initTcpSocket;

-(void)initStatus;

-(void)initInstallLocker;

-(void)sendTcpVinMessage;

-(void)sendStartMessage;

-(void)sendTcpSvtMessage;

-(void)sendTcpCafd1Message;

-(void)sendTcpCafd2Message;

-(void)sendTcpCafd3Message;

-(void)sendTcpCafd4Message;

-(void)sendTcpCafd5Message;

-(void)sendSpeedTestPacket1;

-(void)sendSpeedTestPacket2;

-(void)sendSpeedTestPacket3Sero2;

-(void)sendSpeedTestPacket3;

// 这里是发送Fault code的代码  （读取故障码）
-(void)sendFaultCodepacket;

-(Boolean)sendTcpControllerPacket:(NSString *)packet;

-(BOOL)Sero4sendInstallControllerPacket:(NSString *)packet;

-(Boolean)sendTcpBinaryPacket:(NSString *)packet;

// 数据包不用处理错误
-(void)sendDatapacket:(NSString *)packet;
@end

NS_ASSUME_NONNULL_END
