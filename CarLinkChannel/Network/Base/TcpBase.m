//
//  TcpBase.m
//  CarLinkChannel
//
//  Created by 刘润泽 on 2024/9/23.
//

#import "TcpBase.h"

@interface TcpBase()<GCDAsyncSocketDelegate>
{
    NSString * ServerIp;
    NSString * Serverport;
    bool ServerState;
}
@property (strong, nonatomic) GCDAsyncSocket *Tcpsocket;
@end
@implementation TcpBase

-(void)Connect:(NSString*)ip Port:(NSString*)port delegateQue:(const char*)dQue socketQue:(const char*)sQue {
    ServerState = false;
    ServerIp = ip;
    Serverport = port;
    self.Tcpsocket = [[GCDAsyncSocket alloc] initWithDelegate:self delegateQueue:dispatch_queue_create(dQue, DISPATCH_QUEUE_SERIAL) socketQueue:dispatch_queue_create(sQue, DISPATCH_QUEUE_SERIAL)];
    
    [self ConnectToServer];

}
-(void)ConnectToServer{
    int intValue = [Serverport intValue];
    [self.Tcpsocket connectToHost:ServerIp onPort:intValue error:nil];
}
//Error Process (include dissconnection)
- (void)socketDidDisconnect:(GCDAsyncSocket *)sock withError:(NSError *)err {
    ServerState = false;
    if (err) {
        NSLog(@"Socket Disconnected with Error: %@, Code: %ld", err.localizedDescription, (long)err.code);
        [[NSNotificationCenter defaultCenter] postNotificationName:tcp_disconnect_notify_name object:nil];
        if ([err.domain isEqualToString:NSPOSIXErrorDomain]) {
            // 这是POSIX错误，可以进一步根据错误代码判断具体错误类型
            switch (err.code) {
                case ETIMEDOUT:
                    NSLog(@"Connection timed out.");
                    break;
                case ECONNREFUSED:
                    NSLog(@"Connection refused.");
                    //Reconnect
                    [self ConnectToServer];
                    
                    break;
                case ENETDOWN:
                    NSLog(@"Network is down.");
                    break;
                case ENETUNREACH:
                    NSLog(@"Network is unreachable.");
                    [self ConnectToServer];
                    break;
                default:
                    NSLog(@"Other POSIX network error.");
                    [self ConnectToServer];
                    break;
            }
        } else if ([err.domain isEqualToString:GCDAsyncSocketErrorDomain]) {
            // This is GCDAsyncSocket custom error
            switch (err.code) {
                case GCDAsyncSocketConnectTimeoutError:
                    NSLog(@"Connection timeout.");
                    break;
                case GCDAsyncSocketClosedError:
                    NSLog(@"Connection closed by peer.");
                    //Reconnect
                    [self ConnectToServer];
                    break;
                default:
                    NSLog(@"Other GCDAsyncSocket error.");
                    [self ConnectToServer];
                    break;
            }
        }
    } else {
        NSLog(@"Socket disconnected without error.");
    }
}
//Connect Success process
- (void)socket:(GCDAsyncSocket *)sock didConnectToHost:(NSString *)host port:(UInt16)port {
    NSLog(@"Connected to %@:%hu", host, port);
    ServerState = true;
    if([self.delegate respondsToSelector:@selector(ConnectSuccess)]){
        [self.delegate ConnectSuccess];
    }
    // 连接成功后，可能需要根据协议发送或接收数据
    [sock readDataWithTimeout:-1 tag:0];
}
//Read Data
- (void)socket:(GCDAsyncSocket *)sock didReadData:(NSData *)data withTag:(long)tag {
    NSMutableString *string = [NSMutableString stringWithCapacity:data.length * 2];
    const unsigned char *dataBytes = data.bytes;
    for (NSInteger idx = 0; idx < data.length; idx++) {
        [string appendFormat:@"%02x ", dataBytes[idx]];
    }
//    NSLog(@"Receipt of vehicle %@", string);
    
    NSDate *currentDate = [NSDate date];

    // 创建并配置日期格式化器
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss.SSS"];

    // 将当前日期转换为字符串
    NSString *currentDateString = [dateFormatter stringFromDate:currentDate];

    // 打印带有时间戳的日志
    NSLog(@"[%@] Receipt of vehicle Vehicle: %@", currentDateString, string);

    if([self.delegate respondsToSelector:@selector(RecDataListen:)]){
        [self.delegate RecDataListen:data];
    }
    [sock readDataWithTimeout:-1 tag:0];  // 继续读取数据
}

-(void)SendData:(NSData *)data{
    NSMutableString *string = [NSMutableString stringWithCapacity:data.length * 2];
    const unsigned char *dataBytes = data.bytes;
    for (NSInteger idx = 0; idx < data.length; idx++) {
        [string appendFormat:@"%02x ", dataBytes[idx]];
    }
    NSDate *currentDate = [NSDate date];

    // 创建并配置日期格式化器
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss.SSS"];

    // 将当前日期转换为字符串
    NSString *currentDateString = [dateFormatter stringFromDate:currentDate];

    // 打印带有时间戳的日志
    NSLog(@"[%@] Send To Vehicle: %@", currentDateString, string);
    
//    NSLog(@"Send To Vehicle: %@",string);
    [self.Tcpsocket writeData:data withTimeout:-1 tag:1];
}
-(bool)CheckServerState{
    return ServerState;
}
@end
