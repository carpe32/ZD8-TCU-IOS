//
//  UdpBase.m
//  CarLinkChannel
//
//  Created by 刘润泽 on 2024/9/23.
//

#import "UdpBase.h"

@interface UdpBase()<GCDAsyncUdpSocketDelegate>
{
    NSTimer *SendUdpBroadcastTimer;
}

@property (strong, nonatomic) GCDAsyncUdpSocket *Udpsocket;
@end
@implementation UdpBase

-(instancetype)initWithIp:(NSString *)LocalIp{
    self = [super init];
    if (self) {
        NSError * error;
        self.Udpsocket = [[GCDAsyncUdpSocket alloc] initWithDelegate:self delegateQueue:dispatch_queue_create(0, 0) socketQueue:dispatch_queue_create(0, 0)];
        [self.Udpsocket bindToPort:local_port interface:LocalIp error:&error];
        NSLog(@"绑定本地广播: %@ , error: %@",LocalIp,error);
        NSError * boardcastError;
        [self.Udpsocket enableBroadcast:YES error:&boardcastError];
        [self.Udpsocket beginReceiving:&error];
        dispatch_async(dispatch_get_main_queue(), ^{
            self->SendUdpBroadcastTimer =  [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(sendUdpBoardCast) userInfo:nil repeats:YES];
        });
    }
    return self;
}
- (void)dealloc {
    // 停止并销毁定时器
    [self->SendUdpBroadcastTimer invalidate];
    self->SendUdpBroadcastTimer = nil;
    
    // 关闭 UDP socket
    [self.Udpsocket close];
    self.Udpsocket = nil;
}


-(void)sendUdpBoardCast {
    unsigned char bytes[] = send_datapacket_boardcast;
    NSData * data = [NSData dataWithBytes:bytes length:sizeof(bytes)];
    [self.Udpsocket sendData:data toHost:gateway_ip port:gateway_port withTimeout:-1 tag:1000];
    NSLog(@"发送udp广播消息");
}

#pragma mark UDP 代理
- (void)udpSocket:(GCDAsyncUdpSocket *)sock didReceiveData:(NSData *)data fromAddress:(NSData *)address withFilterContext:(nullable id)filterContext{
 
    NSMutableString *string = [NSMutableString stringWithCapacity:data.length * 2];
    const unsigned char *dataBytes = data.bytes;
    for (NSInteger idx = 0; idx < data.length; idx++) {
        [string appendFormat:@"%02x", dataBytes[idx]];
    }
    NSLog(@"Data: %@", string);
    NSString * address_ip = [GCDAsyncUdpSocket hostFromAddress:address];
    NSString * vehicle_ip = address_ip;
    NSString *local_ip = [sock localHost];
    NSLog(@"收到udp广播消息 远端ip： %@ local_ip: %@",vehicle_ip,local_ip);
    
    [self.delegate didReceiveVehicleIPInfo:vehicle_ip :@"6801"];
    //canel Udp Broadcast Timer
    [self->SendUdpBroadcastTimer invalidate];
    self->SendUdpBroadcastTimer = nil;  // 确保引用被清除，避免内存泄露
    
}
@end

