//
//  CommunityInterface.m
//  CarLinkChannel
//
//  Created by job on 2023/3/27.
//

#import "CommunityInterface.h"
#import "CocoaAsyncSocket.h"
#import "TcpParserHandler.h"
#import "Constents.h"
#import "NSData+Category.h"
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
#import "TcpSpeedTestHandler.h"
#import "ECUInteractive.h"

#define IP_ADDR_IPv4    @"ipv4"
#define IP_ADDR_IPv6    @"ipv6"

void(^result1)(BOOL isAuth);
@interface CommunityInterface() <GCDAsyncUdpSocketDelegate,GCDAsyncSocketDelegate>
{
    GCDAsyncUdpSocket * udpSocket;
    GCDAsyncSocket * tcpSocket;
    TcpParserHandler *parseHandler;
    NSMutableArray * ip_array;
    NSString * last_scan_ip;
    NSString * hardware_ip;
    long hardware_port;
    NSString * local_ip;
    __block BOOL isRecvData;
    NSMutableArray * anquanSufaArray;
    NSMutableArray * cafdArray;
    NSMutableArray * waitList;
    NSString * waitingString;
    __block OSSpinLock oslock;   // 自旋锁
    //    pthread_mutex_t pLock;
    __block dispatch_semaphore_t semaphore;
    __block bool isLock;
    __block bool isTimeout;
    dispatch_source_t timeout_t;
    
    int send_seq;           // 发送的包的第9个字节的首位数字
    
    int progress;            // 0.初始状态   1.     2.    3.    4. 开始同步文件
    int vin_parse;          // 0.还没有赋值  1. 设置状态 2. 已经赋值过了
    int svt_parse;          // 0.还没有赋值  1. 设置状态 2. 已经赋值过了
    int cafd_parse;         // 0. 还没有解析  1. 开始解析   2. 已经解析过了
    int cafd_serial;
    int speed_test_sero;    // 测速分支   0. 还没有确定分支 1. 第一个分支  2.第二个分支  3. 分支不可用
        
    
}

@end



@implementation CommunityInterface

#pragma mark 判断本地网络权限
static void browseReply( DNSServiceRef sdRef, DNSServiceFlags flags, uint32_t interfaceIndex, DNSServiceErrorType errorCode, const char *serviceName, const char *regtype, const char *replyDomain, void *context )

{

    if (errorCode == kDNSServiceErr_PolicyDenied) {
        //本地网络权限未开启
        result1(NO);
        }
    else {

    //本地网络权限已开启
        result1(YES);
    }

}

+ (void) requestLocalNetworkAuthorization:(void(^)(BOOL isAuth)) complete {

    result1 = complete;
    if(@available(iOS 14, *)) {

    //IOS14需要进行本地网络授权
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{

        const char* strc = "_CarLinkChannel";
        DNSServiceRef serviceRef = nil;
        DNSServiceBrowse( &serviceRef, 0, 0, strc, nil, browseReply, nil);
        // serviceRef 为 nil 时，是允许访问出现的
        if(serviceRef == nil){
            result1(YES);
        }else{
            DNSServiceProcessResult(serviceRef);
            DNSServiceRefDeallocate(serviceRef);
        }
    });
    }
    else {
        //IOS14以下默认返回yes,因为IOS14以下设备默认开启本地网络权限
        complete(YES);
    }

}
-(void)uninitUdpSocket {
    if(udpSocket != nil){
//        if([udpSocket isConnected]){
        [udpSocket close];
//        }
        udpSocket.delegate = nil;
        udpSocket = nil;
    }
    if(self->semaphore){
        dispatch_semaphore_signal(self->semaphore);
        self->semaphore = nil;
    }
    if(self->timeout_t){
        dispatch_source_cancel(self->timeout_t);
        self->timeout_t = nil;
        self->isTimeout = false;
    }
}
-(void)initUdpSocket {

    if(udpSocket == nil){
        NSString * interface = last_scan_ip;
        NSDictionary * ipDict = [self getIPAddr];
        for (NSString * key in ipDict.allKeys) {
            NSString * ipaddress = ipDict[key];
            if([ipaddress hasPrefix:@"169."]){
                if(![ip_array containsObject:ipaddress]){
                    interface = ipaddress;
                    [ip_array addObject:ipaddress];
                    break;
                }else{
                    last_scan_ip = ipaddress;
                }
            }
        }
        if((!last_scan_ip || last_scan_ip.length <= 0) && (!interface || interface.length <= 0)){
            NSLog(@"暂时没有扫描到ip ，无法创建udp连接");
            return;
        }
        if([interface isEqualToString:last_scan_ip]){
            [ip_array removeAllObjects];
        }
        if(interface.length <= 0 && last_scan_ip.length > 0){
            interface = last_scan_ip;
        }
        NSError * error;
        udpSocket = [[GCDAsyncUdpSocket alloc] initWithDelegate:self delegateQueue:dispatch_queue_create(0, 0) socketQueue:dispatch_queue_create(0, 0)];
        // 获取本机的Ip 这里需要判断是否是以169开头
      //  NSString * localip = @"";
 
//        [udpSocket setIPv4Enabled:YES];
//        [udpSocket setIPv6Enabled:NO];
        BOOL succ = [udpSocket bindToPort:local_port interface:interface error:&error];
    
        NSLog(@"绑定本地广播: %@ , error: %@",interface,error);
        if(error){
            return;
        }
        if(succ){
        }
        NSError * boardcastError;
        [udpSocket enableBroadcast:YES error:&boardcastError];
        [udpSocket beginReceiving:&error];
    }
}
- (void)socket:(GCDAsyncSocket *)sock didConnectToHost:(NSString *)host port:(uint16_t)port{
    
    NSLog(@"tcpSocket 连接到主机: %@  端口: %d",host,port);
}
/**
 * Called when a socket has completed writing the requested data. Not called if there is an error.
**/
- (void)socket:(GCDAsyncSocket *)sock didWriteDataWithTag:(long)tag{
    
    NSLog(@"tcpSocket didWriteData tag: %ld",tag);
}
-(void)uninitTcpSocket {
    NSLog(@"uninitTcpSocket");
    if(tcpSocket != nil){
        if([tcpSocket isConnected]){
            NSLog(@"tcp 已经连接，现在进行断开连接");
            [tcpSocket disconnect];
        }
        tcpSocket.delegate = nil;
        tcpSocket = nil;
        NSLog(@"tcpsocket == nil");
    }
    if(self->semaphore){
        dispatch_semaphore_signal(self->semaphore);
        self->semaphore = nil;
    }
    if(self->timeout_t){
        dispatch_source_cancel(self->timeout_t);
        self->timeout_t = nil;
        self->isTimeout = false;
    }
}
-(BOOL)initTcpSocket {
    
    if(tcpSocket == nil){
        NSError * error;
        tcpSocket = [[GCDAsyncSocket alloc] initWithDelegate:self delegateQueue:dispatch_queue_create(0, 0) socketQueue:dispatch_queue_create(0, 0)];
        NSString * interface = @"";
        NSDictionary * ipDict = [self getIPAddr];
        NSLog(@"扫描到的ip： %@",ipDict);
//        for (NSString * key in ipDict.allKeys) {
//            NSString * ipaddress = ipDict[key];
//            if([ipaddress hasPrefix:@"169."]){
//                interface = ipaddress;
//            }
//        }
//    getifaddrs()
//        [tcpSocket acceptOnInterface:local_ip port:22122 error:&error];
//        tcpSocket = [[GCDAsyncSocket alloc] initWithDelegate:self delegateQueue:dispatch_queue_create(0, 0)];
//        [tcpSocket setIPv4Enabled:NO];
//        [tcpSocket setIPv6Enabled:NO];
        NSLog(@"绑定本地接口: %@ 错误: %@",interface,error);
        NSLog(@"tcp连接到远程地址: %@ 端口: %ld",hardware_ip,hardware_port);
        BOOL isConnect = [tcpSocket connectToHost:hardware_ip onPort:hardware_port error:&error];
        if(error){
          //  [[NSNotificationCenter defaultCenter] postNotificationName:@"a" object:@"创建tcp失败"];
            NSLog(@"创建tcp失败: %@",error);
            return false;
        }
        if(!isConnect){
          //  [[NSNotificationCenter defaultCenter] postNotificationName:@"a" object:@"创建tcp失败"];
            NSLog(@"当前创建tcp失败");
            return false;
        }
    }

//    pthread_mutex_init(&pLock, NULL);
//    pthread_mutex_lock(&pLock);
    return true;
}
-(void)initStatus {
    send_seq = 0;
    progress = 0;
    vin_parse = 0;
    svt_parse = 0;
    cafd_parse = 0;
    cafd_serial = 0;
    speed_test_sero = 0;
    isLock = NO;
    parseHandler = [[TcpParserHandler alloc] init];

}
-(void)initInstallLocker {
    progress = 4;
    oslock = OS_SPINLOCK_INIT;
    OSSpinLockLock(&oslock);
    if(semaphore){
        dispatch_semaphore_signal(semaphore);
        semaphore = nil;
    }
    semaphore = dispatch_semaphore_create(1);
    dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
}
#pragma mark 发送udp 广播消息

-(void)sendUdpBoardCast {
//    NSData * data = [NSData hexDataFromHexString:send_datapacket_boardcast];
//    [udpSocket sendData:data toHost:remote_ip port:gateway_port withTimeout:-1 tag:1000];
//    [udpSocket sendData:data toHost:gateway_ip port:gateway_port withTimeout:-1 tag:1000];
    NSLog(@"发送udp广播消息");
}
#pragma mark 发送tcp 消息
-(void)sendTcpVinMessage {
    NSData * vinData = [NSData hexDataFromHexString:send_datapacket_vin];
    long tag = random();
    [tcpSocket writeData:vinData withTimeout:-1 tag:tag];
    [tcpSocket readDataWithTimeout:-1 tag:tag];
    NSLog(@"发送vin消息");
}
-(void)sendStartMessage {
    NSString * startString = [send_datapacket_start stringByReplacingOccurrencesOfString:@" " withString:@""];
    NSData * startData = [NSData hexDataFromHexString:startString];
    long tag = random();
    [tcpSocket writeData:startData withTimeout:-1 tag:tag];
    [tcpSocket readDataWithTimeout:-1 tag:tag];
 
}
-(void)sendTcpSvtMessage {
    NSData * vinData = [NSData hexDataFromHexString:send_datapacket_svt];
    long tag = random();
    [tcpSocket writeData:vinData withTimeout:-1 tag:tag];
    [tcpSocket readDataWithTimeout:-1 tag:tag];
    
    NSLog(@"发送svt消息");
}

+(instancetype)getInstance {
    static dispatch_once_t once;
    static CommunityInterface * interface = nil;
    dispatch_once(&once, ^{
        if(interface == nil){
            interface = [[CommunityInterface alloc] init];
            interface->last_scan_ip = @"";
            interface->ip_array = [NSMutableArray array];
            interface->anquanSufaArray = [NSMutableArray array];
//            [interface initUdpSocket];
        }
    });
    return interface;
}
-(NSDictionary *)ipDict {
    NSDictionary * ipDict = [self getIPAddr];
    return ipDict;
}
-(BOOL)getEthNetworkIp {
    
    BOOL isConnect = false;
    NSDictionary * ipDict = [self getIPAddr];
 //   NSLog(@"扫描到的ip: %@",ipDict);
    for (NSString * key in ipDict.allKeys) {
        NSString * ipaddress = ipDict[key];
        if([ipaddress hasPrefix:@"169."]){
            isConnect = true;
        }
    }
    return isConnect;
}


- (NSDictionary *)getIPAddr
{
    NSMutableDictionary *addresses = [NSMutableDictionary dictionaryWithCapacity:8];
    
    // retrieve the current interfaces - returns 0 on success
    struct ifaddrs *interfaces;
    if(!getifaddrs(&interfaces)) {
        // Loop through linked list of interfaces
        struct ifaddrs *interface;
        for(interface=interfaces; interface; interface=interface->ifa_next) {
            if(!(interface->ifa_flags & IFF_UP) /* || (interface->ifa_flags & IFF_LOOPBACK) */ ) {
                continue; // deeply nested code harder to read
            }
            const struct sockaddr_in *addr = (const struct sockaddr_in*)interface->ifa_addr;
            char addrBuf[ MAX(INET_ADDRSTRLEN, INET6_ADDRSTRLEN) ];
            if(addr && (addr->sin_family==AF_INET || addr->sin_family==AF_INET6)) {
                NSString *name = [NSString stringWithUTF8String:interface->ifa_name];
                NSString *type;
                if(addr->sin_family == AF_INET) {
                    if(inet_ntop(AF_INET, &addr->sin_addr, addrBuf, INET_ADDRSTRLEN)) {
                        type = IP_ADDR_IPv4;
                    }
                } else {
                    const struct sockaddr_in6 *addr6 = (const struct sockaddr_in6*)interface->ifa_addr;
                    if(inet_ntop(AF_INET6, &addr6->sin6_addr, addrBuf, INET6_ADDRSTRLEN)) {
                        type = IP_ADDR_IPv6;
                    }
                }
                if(type) {
                    NSString *key = [NSString stringWithFormat:@"%@/%@", name, type];
                    addresses[key] = [NSString stringWithUTF8String:addrBuf];
                }
            }
        }
        // Free memory
        freeifaddrs(interfaces);
    }
    return [addresses count] ? addresses : nil;
}


#pragma mark UDP 代理

- (void)udpSocket:(GCDAsyncUdpSocket *)sock didSendDataWithTag:(long)tag{
    
   // NSLog(@"send data tag: %ld ",tag);
}
- (void)udpSocket:(GCDAsyncUdpSocket *)sock didNotSendDataWithTag:(long)tag dueToError:(NSError * _Nullable)error{
   // NSLog(@"not sendDatawith Tag: %ld ", tag);
}
- (void)udpSocket:(GCDAsyncUdpSocket *)sock didReceiveData:(NSData *)data
                                             fromAddress:(NSData *)address
withFilterContext:(nullable id)filterContext{

    NSString * address_ip = [GCDAsyncUdpSocket hostFromAddress:address];
//    uint16_t port = [GCDAsyncUdpSocket portFromAddress:address];
//
//    NSMutableData * mutableData = [[NSMutableData alloc] initWithData:data];
//    NSData * carNumData = [mutableData subdataWithRange:NSMakeRange(39, 17)];
//
//    char * carNumChar = (char*)carNumData.bytes;
//    NSString * carNum = [NSString stringWithUTF8String:carNumChar];
//
//    hardware_ip = address_ip;
//    hardware_port = 6801;
    
    hardware_ip = address_ip;
    hardware_port = remote_tcp_port;
    local_ip = [sock localHost];
    
    NSLog(@"收到udp广播消息 远端ip： %@ ， 远端端口: %ld  local_ip: %@",hardware_ip,hardware_port,local_ip);
    
    NSDictionary * dict = @{Remote_ip:hardware_ip,Local_ip:local_ip};
    [[NSNotificationCenter defaultCenter] postNotificationName:recv_udp_notify_name object:dict];

    NSLog(@"收到udp回复数据");
//    Boolean result =  [self initTcpSocket];
//    if(result == true){
//        [self sendTcpVinMessage];
//    }
}

#pragma mark TCP 代理
- (void)socketDidDisconnect:(GCDAsyncSocket *)sock withError:(nullable NSError *)err{
    
    [self uninitTcpSocket];
    [self  initInstallLocker];
    [[NSNotificationCenter defaultCenter] postNotificationName:tcp_disconnect_notify_name object:nil];
}

- (void)socket:(GCDAsyncSocket *)sock didReadData:(NSData *)data withTag:(long)tag{
    
    // 这里需要先设置tcp 数据读取超时时间
    [sock readDataWithTimeout:-1 tag:tag];
    // 这里是收到的tcp数据转16进制后和解析到字符后的值
    NSString * hexString = [NSData hexStringFromHexData:data];
    hexString = [hexString stringByReplacingOccurrencesOfString:@" " withString:@""];
    NSLog(@"收到的数据: %@",hexString);
    // 需要判断是否是广播回复的数据，如果是广播回复的数据直接丢弃，用第6个字节的是1还是2来判断，如果是2就是广播回复的数据
    NSString * subString = [hexString substringWithRange:NSMakeRange(packet_obj, 1)];
    // 这里有时间会出现广播的数据和ecu回复的数据粘包的问题，需要把广播数据给截取掉
    if([subString isEqualToString:packet_from_board]){
        //        NSString * dfString = [hexString substringWithRange:NSMakeRange(packet_df_index, 2)];
        //        if([dfString isEqualToString:packet_not_check]){
        //            if(semaphore){
        //                dispatch_semaphore_signal(semaphore);
        //            }
        //        }else{
        //            return;
        //        }
        // 这里有时间会出现广播的数据和ecu回复的数据粘包的问题，所以如果没有粘包才返回
        if(![hexString containsString:@"0118f4"] && ![hexString containsString:@"0112f4"]){
            return;
        }
    }
    if(hexString.length == packet_len_min){
        // 再次判断是否是收到了ecu的 7f xx 78 回复，收到此回复说明ecu 处于忙碌状态
        NSString * sub_9_string = [hexString substringWithRange:NSMakeRange(packet_error_9, 2)];
        NSString * sub_11_string = [hexString substringWithRange:NSMakeRange(packet_error_11, 2)];
        if([sub_9_string isEqualToString:packet_error_9_byte] && [sub_11_string isEqualToString:packet_error_11_byte]){
            NSLog(@"延时状态");
            return;
        }
    }else{
        NSLog(@"收到不等于22个长度的数据包: %@",hexString);
        //   return;
    }
    
    // 检查是否是有egs 健康度的包
    // recv_dtapacket_fault_tcu_pressure_container
    if([hexString hasPrefix:recv_dtapacket_fault_tcu_pressure_container]){
        
        NSRange range = [hexString rangeOfString:recv_dtapacket_fault_tcu_pressure_container];
        NSString * subString = [hexString substringFromIndex:range.location + range.length];
        
        NSMutableArray * array = [NSMutableArray array];
        for (int i = 0; i < 5; i++) {
            NSString * str_temp = [subString substringWithRange:NSMakeRange(i*4, 4)];
            [array addObject:str_temp];
        }
        [[NSNotificationCenter defaultCenter] postNotificationName:recv_data_egs_health_clutch_notify_name object:nil userInfo:@{@"data":array}];
        return;
    }
    
    if([hexString hasPrefix:recv_datapacket_fault_fast_fill_container]){
        
        NSRange range = [hexString rangeOfString:recv_datapacket_fault_fast_fill_container];
        NSString * subString = [hexString substringFromIndex:range.location + range.length];
        NSMutableArray * array = [NSMutableArray array];
        for (int i = 0; i < 5; i++) {
            NSString * str_temp = [subString substringWithRange:NSMakeRange(i*4, 4)];
            [array addObject:str_temp];
        }
        [[NSNotificationCenter defaultCenter] postNotificationName:recv_data_egs_health_fill_notify_name object:nil userInfo:@{@"data":array}];
        return;
    }
    

    // 这里判断是否是读取故障码的包
    if([hexString containsString:recv_datapacket_fault_dme_container]){
        
        NSRange  dme_range = [hexString rangeOfString:recv_datapacket_fault_dme_container];
        NSString * subString = [hexString substringFromIndex:dme_range.location + dme_range.length];
        NSLog(@"收到dme的数据包： %@",subString);
        if([subString hasPrefix:@"ff"]){

            subString = [subString substringFromIndex:2];
            NSLog(@"去掉dme开头的数据包: %@",subString);
            int len = (int)subString.length / 8;
            int len_last = (int)subString.length % 8;
            NSMutableArray * array = [NSMutableArray array];
            for (int i = 0; i < len; i++) {
                NSString * str_temp = [subString substringWithRange:NSMakeRange(i * 8, 8)];
                [array addObject:str_temp];
            }
            if(len_last > 0){
                NSString * str_temp = [subString substringFromIndex:subString.length - len_last];
                [array addObject:str_temp];
            }
            NSDictionary * dataDict = @{@"data":array};
            [[NSNotificationCenter defaultCenter] postNotificationName:recv_data_dme_notify_name object:nil userInfo:dataDict];
            NSLog(@"发送的dme数据包: %@",dataDict);
        }
        return;
    }
    if([hexString containsString:recv_datapacket_fault_egs_container]){
        
        NSRange  egs_range = [hexString rangeOfString:recv_datapacket_fault_egs_container];
        NSLog(@"收到egs的数据包： %@",subString);
        NSString * subString = [hexString substringFromIndex:egs_range.location + egs_range.length];
        if([subString hasPrefix:@"ff"]){
            subString = [subString substringFromIndex:2];
            NSLog(@"去掉egs开头的数据包: %@",subString);
            int len = (int)subString.length / 8;
            int len_last = (int)subString.length % 8;
            NSMutableArray * array = [NSMutableArray array];
            for (int i = 0; i < len; i++) {
                NSString * str_temp = [subString substringWithRange:NSMakeRange(i * 8, 8)];
                [array addObject:str_temp];
            }
            if(len_last > 0){
                NSString * str_temp = [subString substringFromIndex:subString.length - len_last];
                [array addObject:str_temp];
            }
            NSDictionary * dataDict = @{@"data":array};
            [[NSNotificationCenter defaultCenter] postNotificationName:recv_data_egs_notify_name object:nil userInfo:dataDict];
            NSLog(@"发送egs数据包: %@",dataDict);
        }
        return;
    }
    
    // 这里判断是否是测速的包
    
    if([hexString containsString:packet_speed_test] && ![hexString containsString:packet_recv_mark]){
        // 这里因为发送速度太快，所以需要处理粘包的问题
        if([hexString hasPrefix:recv_datapacket_broadcast]){
            hexString = [hexString stringByReplacingOccurrencesOfString:recv_datapacket_broadcast withString:@""];
        }
        NSLog(@"是测速的包: %@",hexString);
        // 这里判断是否是关键字段信息的包
        NSString * speed_test_sero_1_prefix = [speed_test_datapacket_sero_1_prefix stringByReplacingOccurrencesOfString:@" " withString:@""];
        speed_test_sero_1_prefix = [speed_test_sero_1_prefix lowercaseString];
        
        NSString * speed_test_sero_2_prefix = [speed_test_datapacket_sero_2_prefix stringByReplacingOccurrencesOfString:@" " withString:@""];
        speed_test_sero_2_prefix = [speed_test_sero_2_prefix lowercaseString];
        
        if([hexString hasPrefix:speed_test_sero_1_prefix] || [hexString hasPrefix:speed_test_sero_2_prefix]){
            
            TcpSpeedTestHandler * speedHandler = [[TcpSpeedTestHandler alloc] init];
            NSDictionary * data  = nil;
            if(speed_test_sero == 1){
                data = [speedHandler Sero1parseSpeedTestData:hexString];
            }else if (speed_test_sero == 2){
                data = [speedHandler Sero2parseSpeedTestData:hexString];
            }
            if(data){
                NSLog(@"测试速分支: %d 发送测速数据包: %@",speed_test_sero,data);
                [[NSNotificationCenter defaultCenter] postNotificationName:recv_tcp_speed_test_notify_name object:nil userInfo:data];
            }
            return;
        }else{
            /*
             
             #define recv_speed_test_package_1_notify_name @"recv_speed_test_package_1_notify"
             #define recv_speed_test_package_2_sero_1_notify_name @"recv_speed_test_package_2_sero_1_notify"
             #define recv_speed_test_package_2_sero_2_notify_name @"recv_speed_test_package_2_sero_2_notify"
             #define recv_speed_test_package_3_sero_2_notify_name @"recv_speed_test_package_3_sero_2_notify"
             
             */
            // 这里判断处理步骤的包
            NSString * speed_test_package_1 = [recv_datapacket_test_1_2 stringByReplacingOccurrencesOfString:@" " withString:@""];
            speed_test_package_1 = [speed_test_package_1 lowercaseString];
            // 判断是否是第一个数据包的回复
            if([hexString isEqualToString:speed_test_package_1]){
                NSLog(@"收到第一个数据包");
                [[NSNotificationCenter defaultCenter] postNotificationName:recv_speed_test_package_1_notify_name object:nil];
            }else{
                NSString * speed_test_package_2_mg_1 = [recv_datapacket_test_2_2 stringByReplacingOccurrencesOfString:@" " withString:@""];
                speed_test_package_2_mg_1 = [speed_test_package_2_mg_1 lowercaseString];
                
                NSString * speed_test_package_2_mevd_2 = [recv_datapacket_test_2_2_mevd stringByReplacingOccurrencesOfString:@" " withString:@""];
                speed_test_package_2_mevd_2 = [speed_test_package_2_mevd_2 lowercaseString];
                
                // 这里判断是否是第二个包的回复
                // 第一个分支 的回复。 和。第二个分支补充的一个包的回复是一样的，这里要区分
                if([hexString isEqualToString:speed_test_package_2_mg_1]){
                    if(speed_test_sero == 0){
                        speed_test_sero = 1;
                        [[NSNotificationCenter defaultCenter] postNotificationName:recv_speed_test_package_2_sero_1_notify_name object:nil];
                    }else if (speed_test_sero == 2){
                        [[NSNotificationCenter defaultCenter] postNotificationName:recv_speed_test_package_3_sero_2_notify_name object:nil];
                    }
                    // 第二个分支
                }else if ([hexString isEqualToString:speed_test_package_2_mevd_2]){
                    speed_test_sero = 2;
                    [[NSNotificationCenter defaultCenter] postNotificationName:recv_speed_test_package_2_sero_2_notify_name object:nil];
                }
            }
            return;
        }
        
    }
    
    
  //  [[NSNotificationCenter defaultCenter] postNotificationName:@"a" object:hexString];
    
    //

//    NSString * anquan_prefix_3

    // 1. 首先判断是否是 vin 回复的字段值
    if(vin_parse == 0){
        if(hexString.length > recv_vin_length){
            NSString * subString = [hexString substringWithRange:NSMakeRange(recv_vin_f190_index, 4)];
            if([subString isEqualToString:packet_vin]){
                vin_parse = 1;
            }
        }
    // 2.其次判断是否是 svt 回复的字段值
    }else if (svt_parse == 0){
        if(hexString.length > recv_svt_length){
            NSString * subString = [hexString substringWithRange:NSMakeRange(recv_svt_f101_index, 4)];
            if([subString isEqualToString:packet_svt]){
                svt_parse = 1;
            }
        }
    // 3.其次判断是否是读取的cafd的值
    }else{
        // 如果是第四个分支的话是没有cafd读取的
        ECUInteractive * interactive = [ECUInteractive loadInteractive];
        int serotype = [interactive getSeroTypeOnlyCheck];
        if(cafd_parse == 0 && [hexString containsString:recv_datapacket_cafd_container] && serotype != 4){
            cafd_parse = 1;
        }
    }
    
    NSString * anquan_prefix_1 = [recv_anquan_1_prefix stringByReplacingOccurrencesOfString:@" " withString:@""];
    NSString * anquan_prefix_2 = [recv_anquan_2_prefix stringByReplacingOccurrencesOfString:@" " withString:@""];
    
    if(vin_parse == 1){
        NSString * dstString = [parseHandler tceReceiveData:data];
        if(dstString && [dstString length] > 0){
        NSDictionary * notifyDict = @{@"vin":dstString};
            dispatch_async(dispatch_get_main_queue(), ^{
                [[NSNotificationCenter defaultCenter] postNotificationName:recv_vin_notify_name object:notifyDict];
            });
        
       // [[NSNotificationCenter defaultCenter] postNotificationName:@"a" object:dstString];
        
        vin_parse = 2;
    }
    }else if (svt_parse == 1){
        //  这里需要处理粘包
        NSString * dataString = [NSData hexStringFromHexData:data];
        if([dataString hasPrefix:@"000000050002f41822f101"]){
            data = [NSData hexDataFromHexString:[dataString stringByReplacingOccurrencesOfString:@"000000050002f41822f101" withString:@""]];
        }
        
        NSString * dstString = [parseHandler tceReceiveData:data];
        NSLog(@"收到svt消息: %@",dstString);
        NSError * error;
        NSData * dataa = [dstString dataUsingEncoding:NSUTF8StringEncoding];
        NSDictionary * jsonDict = [NSJSONSerialization JSONObjectWithData:dataa options:NSJSONReadingFragmentsAllowed error:&error];
        if([jsonDict.allKeys containsObject:@"sgbms"] && !error){
            NSArray * sgbms = jsonDict[@"sgbms"];
            NSDictionary * notify_dict = @{@"sgbms":sgbms};
            NSLog(@"发送svt通知: %@",notify_dict);
            dispatch_async(dispatch_get_main_queue(), ^{
                [[NSNotificationCenter defaultCenter] postNotificationName:recv_svt_notify_name object:notify_dict];
            });
        }
        svt_parse = 2;
    }else if (cafd_parse == 1 && [hexString containsString:recv_datapacket_cafd_container]){
        
        NSLog(@"收到cafd: %@",hexString);
        //[cafdArray addObject:hexString];
        NSDictionary * dataDict = @{@"cafd":hexString};
        cafd_serial++;
        if(cafd_serial == 1){
//            [[NSUserDefaults standardUserDefaults] setObject:hexString forKey:@"cafd1"];
//            [[NSUserDefaults standardUserDefaults] synchronize];
            [[NSNotificationCenter defaultCenter] postNotificationName:recv_tcp_cafd_1_notify_name object:nil userInfo:dataDict];
        }else if (cafd_serial == 2){
//            [[NSUserDefaults standardUserDefaults] setObject:hexString forKey:@"cafd2"];
//            [[NSUserDefaults standardUserDefaults] synchronize];
            [[NSNotificationCenter defaultCenter] postNotificationName:recv_tcp_cafd_2_notify_name object:nil userInfo:dataDict];
        }else if (cafd_serial == 3){
//            [[NSUserDefaults standardUserDefaults] setObject:hexString forKey:@"cafd3"];
//            [[NSUserDefaults standardUserDefaults] synchronize];
            [[NSNotificationCenter defaultCenter] postNotificationName:recv_tcp_cafd_3_notify_name object:nil userInfo:dataDict];
        }else if (cafd_serial == 4){
//            [[NSUserDefaults standardUserDefaults] setObject:hexString forKey:@"cafd4"];
//            [[NSUserDefaults standardUserDefaults] synchronize];
            [[NSNotificationCenter defaultCenter] postNotificationName:recv_tcp_cafd_4_notify_name object:nil userInfo:dataDict];
 
            ECUInteractive * interactive = [ECUInteractive loadInteractive];
            int serotype = [interactive getSeroTypeOnlyCheck];
            if(serotype == 3 || serotype == 5 || serotype == 6){
            }else{
                cafd_serial = 0;
                cafd_parse = 2;
            }
        }else if (cafd_serial == 5){
//            [[NSUserDefaults standardUserDefaults] setObject:hexString forKey:@"cafd4"];
//            [[NSUserDefaults standardUserDefaults] synchronize];
            [[NSNotificationCenter defaultCenter] postNotificationName:recv_tcp_cafd_5_notify_name object:nil userInfo:dataDict];
 
            cafd_serial = 0;
            cafd_parse = 2;
        }

    } else if(progress == 4){

        if([hexString containsString:@"0118f4"]){
            isRecvData = true;
        }
        if(isRecvData){
            if(waitList == nil){
                waitList = [NSMutableArray array];
            }
            if(waitingString == nil){
                waitingString = @"";
            }
            // 这里进行安全算法的判断
        if(([hexString hasPrefix:anquan_prefix_1] || [hexString hasPrefix:anquan_prefix_2]) && hexString.length > anquan_suanfa_min_len){
            
            NSLog(@"收到安全算法时 self.timetou: %d,time_t: %p",self->isTimeout,self->timeout_t);
                   self->isTimeout = false;
                    if(self->timeout_t){
                        dispatch_source_cancel(timeout_t);
                        self->timeout_t = nil;
                    }
                 
                   NSString * dstString =  [parseHandler tceReceiveData:data];
                   NSDictionary * dataDict = @{@"anquan":dstString};
                   dispatch_async(dispatch_get_main_queue(), ^{
                       NSLog(@"收到安全算法，现在发送通知: %@",dataDict);
                      [[NSNotificationCenter defaultCenter] postNotificationName:recv_anquan_notify_name object:nil userInfo:dataDict];
                  });
           }
            waitingString = hexString;
//            waitingString = [waitingString stringByAppendingString:hexString];
         //   if([hexString containsString:@"78"]){
//                hexString = [hexString stringByReplacingOccurrencesOfString:@"78" withString:@"-"];
//                NSArray<NSString *> *items = [hexString componentsSeparatedByString:@"-"];
//                for (int i =0; i< items.count; i++) {
//                    if(i != items.count - 1){
//                        [waitList addObject:[NSString stringWithFormat:@"%@78",items[i]]];
//                    }else{
//                        [waitList addObject:items[i]];
//                    }
//                }
//            }else{
//
                [waitList addObject:hexString];
//
//            }
            // 这里需要对是否加锁进行判断，因为有些包是没有进行加锁的
            if(semaphore && isLock == YES){
//            if(semaphore){
                dispatch_semaphore_signal(semaphore);
                // 因为df的包不只一条回复，在0118f4之后，还会有包进来，所以这里需要对是否收到包进行重置，并且将加锁状态重置
               // isRecvData = NO;   // 这个变量不能在这里重新初始化，会导致不执行正常的错误处理流程
                isLock = NO;
            }
        }
      //  pthread_mutex_unlock(&pLock);
    }
}
-(void)sendTcpCafd1Message{
    NSString * packet = [send_datapacket_cafd_1 stringByReplacingOccurrencesOfString:@" " withString:@""];
    NSData * dataPacket = [NSData hexDataFromHexString:packet];
    long tag = random();
    [tcpSocket writeData:dataPacket withTimeout:-1 tag:tag];
    [tcpSocket readDataWithTimeout:-1 tag:tag];
}
-(void)sendTcpCafd2Message{
    NSString * packet = [send_datapacket_cafd_2 stringByReplacingOccurrencesOfString:@" " withString:@""];
    NSData * dataPacket = [NSData hexDataFromHexString:packet];
    long tag = random();
    [tcpSocket writeData:dataPacket withTimeout:-1 tag:tag];
    [tcpSocket readDataWithTimeout:-1 tag:tag];
}
-(void)sendTcpCafd3Message{
    NSString * packet = [send_datapacket_cafd_3 stringByReplacingOccurrencesOfString:@" " withString:@""];
    NSData * dataPacket = [NSData hexDataFromHexString:packet];
    long tag = random();
    [tcpSocket writeData:dataPacket withTimeout:-1 tag:tag];
    [tcpSocket readDataWithTimeout:-1 tag:tag];
}
-(void)sendTcpCafd4Message{
    NSString * packet = [send_datapacket_cafd_4 stringByReplacingOccurrencesOfString:@" " withString:@""];
    NSData * dataPacket = [NSData hexDataFromHexString:packet];
    long tag = random();
    [tcpSocket writeData:dataPacket withTimeout:-1 tag:tag];
    [tcpSocket readDataWithTimeout:-1 tag:tag];
}
-(void)sendTcpCafd5Message{
    NSString * packet = [send_datapacket_cafd_5 stringByReplacingOccurrencesOfString:@" " withString:@""];
    NSData * dataPacket = [NSData hexDataFromHexString:packet];
    long tag = random();
    [tcpSocket writeData:dataPacket withTimeout:-1 tag:tag];
    [tcpSocket readDataWithTimeout:-1 tag:tag];
}

-(void)sendSpeedTestPacket1{
    
    NSString * packet = [send_datapacket_test_1 stringByReplacingOccurrencesOfString:@" " withString:@""];
    NSData * dataPacket = [NSData hexDataFromHexString:packet];
    long tag = random();
    [tcpSocket writeData:dataPacket withTimeout:-1 tag:tag];
    [tcpSocket readDataWithTimeout:-1 tag:tag];
    
    NSLog(@"发送: %@",packet);
}

-(void)sendSpeedTestPacket2{
    
    NSString * packet = [send_datapacket_test_2 stringByReplacingOccurrencesOfString:@" " withString:@""];
    NSData * dataPacket = [NSData hexDataFromHexString:packet];
    long tag = random();
    [tcpSocket writeData:dataPacket withTimeout:-1 tag:tag];
    [tcpSocket readDataWithTimeout:-1 tag:tag];
    
    NSLog(@"发送: %@",packet);
}
-(void)sendSpeedTestPacket3Sero2{
    NSString * packet = [send_datapacket_test_3_1_mevd stringByReplacingOccurrencesOfString:@" " withString:@""];
    NSData * dataPacket = [NSData hexDataFromHexString:packet];
    long tag = random();
    [tcpSocket writeData:dataPacket withTimeout:-1 tag:tag];
    [tcpSocket readDataWithTimeout:-1 tag:tag];
    
    NSLog(@"发送: %@",packet);
}
-(void)sendSpeedTestPacket3{
    NSString * packet = [send_datapacket_test_3 stringByReplacingOccurrencesOfString:@" " withString:@""];
    NSData * dataPacket = [NSData hexDataFromHexString:packet];
    long tag = random();
    [tcpSocket writeData:dataPacket withTimeout:-1 tag:tag];
    [tcpSocket readDataWithTimeout:-1 tag:tag];
    
    NSLog(@"发送: %@",packet);
}
// 这里是发送Fault code的代码  （读取故障码）
-(void)sendFaultCodepacket{
    
}
-(Boolean)check78code {
    static int waitcount = 0;
    sleep(0.4);
    waitcount ++;
//    if(![waitList[waitList.count - 1] substringFromIndex:waitList[waitList.count - 1].le])
    if(![[[waitList lastObject] substringFromIndex:[(NSString *)[waitList lastObject] length] - 2] containsString:@"78"]){
        waitcount = 0;
        return true;
    }else{
        if(waitcount >= 100){
            waitcount = 0;
            return false;
        }else{
            return [self check78code];
        }
    }
    return [self check78code];
}
-(Boolean)checkBinary78code {
    
    static int waitcount = 0;
    sleep(0.4);
    waitcount ++;
//    if(![waitList[waitList.count - 1] substringFromIndex:waitList[waitList.count - 1].le])

    if([[[waitingString uppercaseString] uppercaseString] containsString:@"F47678"]){
        
        return true;
    }


    if(![[[waitList lastObject] substringFromIndex:[(NSString *)[waitList lastObject] length] - 2] containsString:@"78"]){
        waitcount = 0;
        return true;
    }else{
        if(waitcount >= 100){
            waitcount = 0;
            return false;
        }else{
            return [self checkBinary78code];
        }
    }

    return [self checkBinary78code];
}

-(Boolean)sendTcpControllerPacket:(NSString *)packet{
    if(tcpSocket == nil)return false;
    // sleep(1);
    static int sendCount = 0;
    isRecvData = false;waitingString = @"";waitList = @[].mutableCopy;
    self->isTimeout = NO;
    // 首先截取出来取到的包的序列号
    NSString * seq_str = [packet substringWithRange:NSMakeRange(packet_seq, 1)];
    send_seq = [seq_str intValue];
    
    NSData * dataPacket = [NSData hexDataFromHexString:packet];
    long tag = random();
    [tcpSocket writeData:dataPacket withTimeout:-1 tag:tag];
    [tcpSocket readDataWithTimeout:-1 tag:tag];
    
    sendCount ++;
    
    NSString * end_1_data = [send_data_end_1 stringByReplacingOccurrencesOfString:@" "  withString:@""];
    NSString * end_1_no_space = [send_end_1_packet_1 stringByReplacingOccurrencesOfString:@" " withString:@""];
    NSString * end_4_no_space = [send_end_4_packet_4 stringByReplacingOccurrencesOfString:@" " withString:@""];
    NSString * end_4_packet_5_no_space = [send_end_4_packet_5 stringByReplacingOccurrencesOfString:@" " withString:@""];
    NSString * spec_packet = [send_spec_data_packet_1 stringByReplacingOccurrencesOfString:@" " withString:@""];
    NSString * end_1_packet_5 = [send_end_1_packet_5 stringByReplacingOccurrencesOfString:@" " withString:@""];
    NSString * end_1101_string = [send_1101_data_packet stringByReplacingOccurrencesOfString:@" " withString:@""];
   
    // 因为第14-15位为 df 的包，硬件设备可能返回一条或者多条纪录，所以这里也使用休眠直接跳过，因为有多个回复不知道具体数量，无法确定是否发送完成
    // 这里是需要跳过的包，因为这些包，硬件设备不会返回正常的应答值，不能解锁当前线程，这里就直接使用休眠跳过回复检查
    if([packet isEqualToString:end_1_data] || [packet isEqualToString:end_1_no_space] || [packet isEqualToString:end_4_no_space] || [packet isEqualToString:end_4_packet_5_no_space] || [packet isEqualToString:spec_packet] || [packet isEqualToString:end_1_packet_5] || [packet isEqualToString:end_1101_string]){
        
        NSLog(@"发送不考虑回复的指令: %@,开始延时1.2s",packet);
        isLock = NO;
        usleep(1200000);
        sendCount = 0;
        return true;
    }
    
    // 现在检查安全算法的包，如果在5s后没有收到硬件针对安全算法的回包，就认为超时，出错
    NSString * anquan_suanfa_1 = [send_end_2_packet_2 stringByReplacingOccurrencesOfString:@" " withString:@""];
    NSString * anquan_suanfa_2 = [safe_data_packet_2 stringByReplacingOccurrencesOfString:@" " withString:@""];
    if([packet isEqualToString:anquan_suanfa_1] || [packet isEqualToString:anquan_suanfa_2]){
        self->isTimeout = true;
        // 因为每隔0.1秒执行一次，所以这里5秒钟的超时值就是 50
        NSLog(@"这里进入安全算法的计时器");
        __block int timecount = 0;
        //设置时间间隔
        NSTimeInterval period = 0.1f;
        dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
        timeout_t = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, queue);
        
        // 第一次不会立刻执行，会等到间隔时间后再执行
        //    dispatch_time_t start = dispatch_time(DISPATCH_TIME_NOW, period * NSEC_PER_SEC);
        //    dispatch_source_set_timer(_timer, start, period * NSEC_PER_SEC, 0);
        
        // 第一次会立刻执行，然后再间隔执行
        dispatch_source_set_timer(timeout_t, dispatch_walltime(NULL, 0), period * NSEC_PER_SEC, 0);
        // 事件回调
        dispatch_source_set_event_handler(timeout_t, ^{
                timecount ++;
            NSLog(@"------timecount: %d",timecount);
                if(timecount >= 50 && self->isTimeout == true){
                    NSLog(@"-------> timeCount: %d self.istimecount: %d",timecount,self->isTimeout);
//                    self->isTimeout = false;
                    if(self->semaphore){
                        dispatch_semaphore_signal(self->semaphore);
                    }
                   
                    if(self->timeout_t){
                        dispatch_source_cancel(self->timeout_t);
                        self->timeout_t = nil;
                    }
                    timecount = 0;
                }
        });
        // 开启定时器
        if (timeout_t) {
            dispatch_resume(timeout_t);
        }
        sendCount = 0;
        
    }
    
    NSLog(@"发送指令   发送数据: %@ 等待回复",packet);
    // 11 01  的数据包是用于硬件设备重启的包，这里需要等待4s，因为小于 4s 设备还没有重新启动
    NSString * datapacket_1101 = [send_1101_data_packet stringByReplacingOccurrencesOfString:@" " withString:@""];
    if([packet isEqualToString:datapacket_1101]){
        NSLog(@"发送1101设备重启的指令，现在休眠4s等待设备重启");
        usleep(4000000);
    }
    NSLog(@"进入等待回复解锁");
    isLock = YES;
    dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
    if(tcpSocket == nil){
        NSLog(@"此时数据线被拨除，应当返回失败");
        return false;
    }
    NSLog(@"发送指令   收到回复 开始处理错误");
    
    if(isRecvData == true){
        
        if(sendCount > 2){
            sendCount = 0;
            NSLog(@"--------.  现在是检测count的值 sendCount: %d",sendCount);
            return false;
        }
        if([[[waitList lastObject] uppercaseString] containsString:@"00000004000118F436"]){
            sleep(2);
            [self sendTcpControllerPacket:packet];
        }
        
        if([[waitingString uppercaseString] containsString:@"F47F"]){
            
//            NSRange index_range = [waitingString rangeOfString:@"F47F"];
//            NSString * nextString = [waitingString substringWithRange:NSMakeRange(index_range.location + 6, 2)];
            
            NSString * nextString = [waitingString substringFromIndex:packet_error_11];
//            if([nextString isEqualToString:@"78"]){
//                waitingString = @"";
//                bool result78 = [self check78code];
//                if(result78 == false){
//                    return false;
//                }
//
//            }else
            if ([nextString isEqualToString:@"21"] || [nextString isEqualToString:@"37"]){
                
                waitingString = @"";
                usleep(500000);
                [self sendTcpControllerPacket:packet];
            }else if ([nextString isEqualToString:@"12"] || [nextString isEqualToString:@"33"] || [nextString isEqualToString:@"7f"] || [nextString isEqualToString:@"24"]){

                NSLog(@"收到返回失败的状态 : %@",waitingString);
                waitingString = @"";
                sendCount = 0;
                return false;
            }else if ([nextString isEqualToString:@"35"]){
                waitingString = @"";
                sendCount = 0;
                return false;
            }
        }
        NSString * succ_packet_1 = [check_succ_packet_1_unit_1 stringByReplacingOccurrencesOfString:@" " withString:@""];
        if([packet hasPrefix:succ_packet_1] && [packet hasSuffix:@"0000"]){
            NSLog(@"当前包含有 %@  现在判断回复是否出错",packet);
            if([waitingString isEqualToString:recv_datapacket_020200]){
                NSLog(@"当前包 %@ 包返回值正确",packet);
                sendCount = 0;
                return true;
            }else if ([waitingString isEqualToString:recv_datapacket_020201]){
                NSLog(@"当前包 %@ 包返回值失败",packet);
                sendCount = 0;
                return false;
            }else{
                sendCount = 0;
                return false;
            }
        }
        sendCount = 0;
        return true;
    }
    NSLog(@"等处理完错误后，再判断是否数据超时");
    if(self->isTimeout == true){
        NSLog(@"发送的包超时");
        self->isTimeout = false;
        if(self->timeout_t){
            dispatch_source_cancel(self->timeout_t);
            self->timeout_t = nil;
        }
     
        sendCount = 0;
        return false;
    }
    sendCount = 0;
    return true;
}
-(BOOL)Sero4sendInstallControllerPacket:(NSString *)packet{
    if(tcpSocket == nil){
        NSLog(@"此时数据线被拨除,应当返回失败");
        return false;
    }
    // sleep(1);
    static int sendCount = 0;
    isRecvData = false;waitingString = @"";waitList = @[].mutableCopy;
    self->isTimeout = NO;
    // 首先截取出来取到的包的序列号
    NSString * seq_str = [packet substringWithRange:NSMakeRange(packet_seq, 1)];
    send_seq = [seq_str intValue];
    
    NSData * dataPacket = [NSData hexDataFromHexString:packet];
    long tag = random();
    [tcpSocket writeData:dataPacket withTimeout:-1 tag:tag];
    [tcpSocket readDataWithTimeout:-1 tag:tag];
    
    sendCount ++;
    
    NSString * end_1_data = [send_data_end_1 stringByReplacingOccurrencesOfString:@" "  withString:@""];
    NSString * end_1_no_space = [send_end_1_packet_1 stringByReplacingOccurrencesOfString:@" " withString:@""];
    NSString * end_4_no_space = [send_end_4_packet_4 stringByReplacingOccurrencesOfString:@" " withString:@""];
    NSString * end_4_packet_5_no_space = [send_end_4_packet_5 stringByReplacingOccurrencesOfString:@" " withString:@""];
    NSString * end_1_packet_5 = [send_end_1_packet_5 stringByReplacingOccurrencesOfString:@" " withString:@""];
    NSString * spec_packet = [send_spec_data_packet_1 stringByReplacingOccurrencesOfString:@" " withString:@""];
    NSString * end_1101_string = [send_1101_data_packet stringByReplacingOccurrencesOfString:@" " withString:@""];
    NSString * data_packet_0f_0c_0c = [send_spec_data_packet_2 stringByReplacingOccurrencesOfString:@" " withString:@""];
    NSString * spec_data_packet_spec_3 = [send_spec_data_packet_3 stringByReplacingOccurrencesOfString:@" " withString:@""];
    NSString * data_packet_spec_4 = [send_spec_data_packet_4 stringByReplacingOccurrencesOfString:@" " withString:@""];
    NSString * spec_data_packet_5 = [send_spec_data_packet_5 stringByReplacingOccurrencesOfString:@" " withString:@""];
    NSString * spec_data_packet_6 = [send_spec_data_packet_6 stringByReplacingOccurrencesOfString:@" " withString:@""];
    NSString * data_packet_safe_1 = [safe_data_packet_1 stringByReplacingOccurrencesOfString:@" " withString:@""];
    // 因为第14-15位为 df 的包，硬件设备可能返回一条或者多条纪录，所以这里也使用休眠直接跳过，因为有多个回复不知道具体数量，无法确定是否发送完成
    // 这里是需要跳过的包，因为这些包，硬件设备不会返回正常的应答值，不能解锁当前线程，这里就直接使用休眠跳过回复检查
    if([packet isEqualToString:end_1_data] || [packet isEqualToString:end_1_no_space] || [packet isEqualToString:end_4_no_space] || [packet isEqualToString:end_4_packet_5_no_space] || [packet isEqualToString:spec_packet] || [packet isEqualToString:end_1_packet_5] || [packet isEqualToString:end_1101_string] || [packet isEqualToString:data_packet_0f_0c_0c] || [packet isEqualToString:spec_data_packet_spec_3] || [packet isEqualToString:data_packet_spec_4] || [packet isEqualToString:spec_data_packet_5] || [packet isEqualToString:spec_data_packet_6] || ([packet isEqualToString:data_packet_safe_1])){
        
        NSLog(@"发送不考虑回复的指令: %@,开始延时1.2s",packet);
        isLock = NO;
        usleep(1200000);
        sendCount = 0;
        return true;
    }
    
    // 现在检查安全算法的包，如果在5s后没有收到硬件针对安全算法的回包，就认为超时，出错
    NSString * anquan_suanfa_1 = [send_end_2_packet_2 stringByReplacingOccurrencesOfString:@" " withString:@""];
    NSString * anquan_suanfa_2 = [safe_data_packet_2 stringByReplacingOccurrencesOfString:@" " withString:@""];
    if([packet isEqualToString:anquan_suanfa_1] || [packet isEqualToString:anquan_suanfa_2]){
        self->isTimeout = true;
        // 因为每隔0.1秒执行一次，所以这里5秒钟的超时值就是 50
        NSLog(@"这里进入安全算法的计时器");
        __block int timecount = 0;
        //设置时间间隔
        NSTimeInterval period = 0.1f;
        dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
        timeout_t = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, queue);
        
        // 第一次不会立刻执行，会等到间隔时间后再执行
        //    dispatch_time_t start = dispatch_time(DISPATCH_TIME_NOW, period * NSEC_PER_SEC);
        //    dispatch_source_set_timer(_timer, start, period * NSEC_PER_SEC, 0);
        
        // 第一次会立刻执行，然后再间隔执行
        dispatch_source_set_timer(timeout_t, dispatch_walltime(NULL, 0), period * NSEC_PER_SEC, 0);
        // 事件回调
        dispatch_source_set_event_handler(timeout_t, ^{
                timecount ++;
            NSLog(@"------timecount: %d",timecount);
                if(timecount >= 50 && self->isTimeout == true){
                    NSLog(@"-------> timeCount: %d self.istimecount: %d",timecount,self->isTimeout);
//                    self->isTimeout = false;
                    if(self->semaphore){
                        dispatch_semaphore_signal(self->semaphore);
                    }
                    if(self->timeout_t){
                        dispatch_source_cancel(self->timeout_t);
                        self->timeout_t = nil;
                    }
                    timecount = 0;
                }
        });
        // 开启定时器
        if (timeout_t) {
            dispatch_resume(timeout_t);
        }
        sendCount = 0;
        
    }
    
    NSLog(@"分支四发送指令   发送数据: %@ 等待回复",packet);
    // 11 01  的数据包是用于硬件设备重启的包，这里需要等待4s，因为小于 4s 设备还没有重新启动
    NSString * datapacket_1101 = [send_1101_data_packet stringByReplacingOccurrencesOfString:@" " withString:@""];
    if([packet isEqualToString:datapacket_1101]){
        NSLog(@"分支四发送1101设备重启的指令，现在休眠4s等待设备重启");
        usleep(4000000);
    }
    NSLog(@"分支四进入等待回复解锁");
    isLock = YES;
    dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
    if(tcpSocket == nil){
        NSLog(@"此时数据线被拨除,应当返回失败");
        return false;
    }
    NSLog(@"分支四发送指令   收到回复 开始处理错误");

    if(isRecvData == true){
        
        if(sendCount > 2){
            sendCount = 0;
            NSLog(@"--------.  现在是检测count的值 sendCount: %d",sendCount);
            return false;
        }
        if([[[waitList lastObject] uppercaseString] containsString:@"00000004000118F436"]){
            sleep(2);
            [self Sero4sendInstallControllerPacket:packet];
        }
        
        if([[waitingString uppercaseString] containsString:@"F47F"]){
            
//            NSRange index_range = [waitingString rangeOfString:@"F47F"];
//            NSString * nextString = [waitingString substringWithRange:NSMakeRange(index_range.location + 6, 2)];
            
            NSString * nextString = [waitingString substringFromIndex:packet_error_11];
//            if([nextString isEqualToString:@"78"]){
//                waitingString = @"";
//                bool result78 = [self check78code];
//                if(result78 == false){
//                    return false;
//                }
//
//            }else
            if ([nextString isEqualToString:@"21"] || [nextString isEqualToString:@"37"]){
                
                waitingString = @"";
                usleep(500000);
                [self sendTcpControllerPacket:packet];
            }else if ([nextString isEqualToString:@"12"] || [nextString isEqualToString:@"33"] || [nextString isEqualToString:@"7f"] || [nextString isEqualToString:@"24"]){

                NSLog(@"收到返回失败的状态 : %@",waitingString);
                waitingString = @"";
                sendCount = 0;
                return false;
            }else if ([nextString isEqualToString:@"35"]){
                waitingString = @"";
                sendCount = 0;
                return false;
            }
        }
        
        NSString * succ_packet_1 = [check_succ_packet_1_unit_1 stringByReplacingOccurrencesOfString:@" " withString:@""];
        if([packet hasPrefix:succ_packet_1] && [packet hasSuffix:@"0000"]){
            NSLog(@"当前包含有 %@  现在判断回复是否出错",packet);
            if([waitingString isEqualToString:recv_datapacket_020200]){
                NSLog(@"当前包 %@ 包返回值正确",packet);
                sendCount = 0;
                return true;
            }else if ([waitingString isEqualToString:recv_datapacket_020201]){
                NSLog(@"当前包 %@ 包返回值失败",packet);
                sendCount = 0;
                return false;
            }else{
                sendCount = 0;
                return false;
            }
        }
    
        sendCount = 0;
        return true;
    }
    NSLog(@"等处理完错误后，再判断是否数据超时");
    if(self->isTimeout == true){
        NSLog(@"发送的包超时");
        self->isTimeout = false;
        dispatch_source_cancel(self->timeout_t);
        sendCount = 0;
        return false;
    }
    sendCount = 0;
    return true;
}


-(void)checkDatapacketTimeOut {
    
    
}
-(Boolean)sendTcpBinaryPacket:(NSString *)packet{
    if(tcpSocket == nil){
        NSLog(@"此时数据线被拨除,应当返回失败");
        return false;
    }
    //  sleep(1);
    static int sendtims = 0;
    isRecvData = false;waitingString = @"";waitList = @[].mutableCopy;
    NSData * dataPacket = [NSData hexDataFromHexString:packet];
    long tag = random();
    [tcpSocket writeData:dataPacket withTimeout:-1 tag:tag];
    [tcpSocket readDataWithTimeout:-1 tag:tag];
    sendtims ++;
    NSLog(@"发送文件   发送数据: %@ 开始等待回复",packet);
    isLock = YES;
    dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
    if(tcpSocket == nil){
        NSLog(@"此时数据线被拨除,应当返回失败");
        return false;
    }
    NSLog(@"发送文件   已经回复，现在判断处理错误");
    if(isRecvData == true){
        if(sendtims > 2){
            sendtims = 0;
            return false;
        }
        if([[[waitList lastObject] uppercaseString] containsString:@"00000004000118F436"]){
            return  [self sendTcpBinaryPacket:packet];
        }
        if([[[waitList lastObject] uppercaseString] containsString:@"F47F"]){
            if([[waitingString  uppercaseString] containsString:@"F47678"]){
                sendtims = 0;
                return true;
            }
            if(waitingString.length >= packet_len_min){
                //            NSRange index_range = [waitingString rangeOfString:@"F47F"];
                //            NSString * nextString = [waitingString substringWithRange:NSMakeRange(index_range.location + 6, 2)];
                NSString * nextString = [waitingString substringFromIndex:packet_error_11];
                //            if([nextString isEqualToString:@"78"]){
                //                waitingString = @"";
                //                bool result78 = [self checkBinary78code];
                //                if(result78 == false){
                //                    return false;
                //                }
                //            }else
                if ([nextString isEqualToString:@"21"] || [nextString isEqualToString:@"37"]){
                    sleep(0.4);
                    return  [self sendTcpBinaryPacket:packet];
                }else if ([nextString isEqualToString:@"12"] || [nextString isEqualToString:@"33"] || [nextString isEqualToString:@"7f"] || [nextString isEqualToString:@"24"]){
                    sendtims = 0;
                    return false;
                }
            }
        }
        sendtims = 0;
        return true;
    }
    sendtims = 0;
    return true;
}

// 数据包不用处理错误
-(void)sendDatapacket:(NSString *)packet{
    if(tcpSocket == nil){
        NSLog(@"此时数据线被拨除,应当返回失败");
        return;
    }
    
    packet = [packet stringByReplacingOccurrencesOfString:@" " withString:@""];
    NSData * dataPacket = [NSData hexDataFromHexString:packet];
    long tag = random();
    [tcpSocket writeData:dataPacket withTimeout:-1 tag:tag];
    [tcpSocket readDataWithTimeout:-1 tag:tag];
}
@end
