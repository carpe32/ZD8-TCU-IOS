//
//  ViewController.m
//  CarLinkChannel
//
//  Created by job on 2023/3/22.
//      00008101-00090DD421E9003A

#import "ViewController.h"
//#import <ExternalAccessory/ExternalAccessory.h>
//#import <ExternalAccessory/ExternalAccessory.h>
#import "NSData+Category.h"
#import "TcpParserHandler.h"
#import "Constents.h"



#import "CocoaAsyncSocket.h"
#import <ifaddrs.h>
#import <resolv.h>
#import <arpa/inet.h>
#import <net/if.h>
#import <netdb.h>
#import <netinet/ip.h>
#import <net/ethernet.h>
#import <net/if_dl.h>

#define MDNS_PORT       5353
#define QUERY_NAME      "_apple-mobdev2._tcp.local"
#define DUMMY_MAC_ADDR  @"02:00:00:00:00:00"
#define IOS_CELLULAR    @"pdp_ip0"
#define IOS_WIFI        @"en0"
#define IOS_VPN         @"utun0"
#define IP_ADDR_IPv4    @"ipv4"
#define IP_ADDR_IPv6    @"ipv6"





#define datapacket_boardcast @"000000000011"
#define datapacket_vin @"000000050001f41822f190"
#define datapacket_svt @"000000050001f41822f101"

typedef NS_ENUM(NSInteger, step) {
    parser_vin = 1,
    parser_svt,
};

@interface ViewController () <GCDAsyncSocketDelegate,GCDAsyncUdpSocketDelegate>
{
    UIButton * startButton;
    UIButton * sendButton;
    UIButton * tcpInitButton;
    UIButton * vinTcpButton;
    UIButton * svtTcpButton;
    UIButton * clearButton;
    UITextView * textView;
    GCDAsyncUdpSocket * udpSocket;
    GCDAsyncSocket * tcpSocket;
    
    TcpParserHandler *parseHandler;
    
//    NSString * remote_ip;
//    long remote_port;
}

@end

@implementation ViewController

/*
 * 获取设备当前网络IP地址
 */
- (NSString *)getIPAddress:(BOOL)preferIPv4
{
    NSArray *searchArray = preferIPv4 ?
    @[ IOS_VPN @"/" IP_ADDR_IPv4, IOS_VPN @"/" IP_ADDR_IPv6, IOS_WIFI @"/" IP_ADDR_IPv4, IOS_WIFI @"/" IP_ADDR_IPv6, IOS_CELLULAR @"/" IP_ADDR_IPv4, IOS_CELLULAR @"/" IP_ADDR_IPv6 ] :
    @[ IOS_VPN @"/" IP_ADDR_IPv6, IOS_VPN @"/" IP_ADDR_IPv4, IOS_WIFI @"/" IP_ADDR_IPv6, IOS_WIFI @"/" IP_ADDR_IPv4, IOS_CELLULAR @"/" IP_ADDR_IPv6, IOS_CELLULAR @"/" IP_ADDR_IPv4 ] ;
    
    NSDictionary *addresses = [self getIPAddr];
    
    __block NSString *address;
    [searchArray enumerateObjectsUsingBlock:^(NSString *key, NSUInteger idx, BOOL * _Nonnull stop) {
        address = addresses[key];
        //筛选出IP地址格式
        if([self isValidatIP:address]) *stop = YES;
    }];
    return address ? address : @"0.0.0.0";
}

- (BOOL)isValidatIP:(NSString *)ipAddress {
    if (ipAddress.length == 0) {
        return NO;
    }
    NSString *urlRegEx = @"^([01]?\\d\\d?|2[0-4]\\d|25[0-5])\\."
    "([01]?\\d\\d?|2[0-4]\\d|25[0-5])\\."
    "([01]?\\d\\d?|2[0-4]\\d|25[0-5])\\."
    "([01]?\\d\\d?|2[0-4]\\d|25[0-5])$";
    
    NSError *error;
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:urlRegEx options:0 error:&error];
    
    if (regex != nil) {
        NSTextCheckingResult *firstMatch=[regex firstMatchInString:ipAddress options:0 range:NSMakeRange(0, [ipAddress length])];
        return firstMatch;
    }
    return NO;
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
/*
 * 获取设备物理地址

- (nullable NSString *)getMacAddress {
    res_9_init();
    int len;
    //get currnet ip address
    NSString *ip = [self currentIPAddressOf:IOS_WIFI];
    if(ip == nil) {
        fprintf(stderr, "could not get current IP address of en0\n");
        return DUMMY_MAC_ADDR;
    }//end if
    
    //set port and destination
    _res.nsaddr_list[0].sin_family = AF_INET;
    _res.nsaddr_list[0].sin_port = htons(MDNS_PORT);
    _res.nsaddr_list[0].sin_addr.s_addr = [self IPv4Pton:ip];
    _res.nscount = 1;
    
    unsigned char response[NS_PACKETSZ];
    
    
    //send mdns query
    if((len = res_9_query(QUERY_NAME, ns_c_in, ns_t_ptr, response, sizeof(response))) < 0) {
        
        fprintf(stderr, "res_search(): %s\n", hstrerror(h_errno));
        return DUMMY_MAC_ADDR;
    }//end if
    
    //parse mdns message
    ns_msg handle;
    if(ns_initparse(response, len, &handle) < 0) {
        fprintf(stderr, "ns_initparse(): %s\n", hstrerror(h_errno));
        return DUMMY_MAC_ADDR;
    }//end if
    
    //get answer length
    len = ns_msg_count(handle, ns_s_an);
    if(len < 0) {
        fprintf(stderr, "ns_msg_count return zero\n");
        return DUMMY_MAC_ADDR;
    }//end if
    
    //try to get mac address from data
    NSString *macAddress = nil;
    for(int i = 0 ; i < len ; i++) {
        ns_rr rr;
        ns_parserr(&handle, ns_s_an, 0, &rr);
        
        if(ns_rr_class(rr) == ns_c_in &&
           ns_rr_type(rr) == ns_t_ptr &&
           !strcmp(ns_rr_name(rr), QUERY_NAME)) {
            char *ptr = (char *)(ns_rr_rdata(rr) + 1);
            int l = (int)strcspn(ptr, "@");
            
            char *tmp = calloc(l + 1, sizeof(char));
            if(!tmp) {
                perror("calloc()");
                continue;
            }//end if
            memcpy(tmp, ptr, l);
            macAddress = [NSString stringWithUTF8String:tmp];
            free(tmp);
        }//end if
    }//end for each
    macAddress = macAddress ? macAddress : DUMMY_MAC_ADDR;
    return macAddress;
}//end getMacAddressFromMDNS
 */
- (nonnull NSString *)currentIPAddressOf: (nonnull NSString *)device {
    struct ifaddrs *addrs;
    NSString *ipAddress = nil;
    
    if(getifaddrs(&addrs) != 0) {
        return nil;
    }//end if
    
    //get ipv4 address
    for(struct ifaddrs *addr = addrs ; addr ; addr = addr->ifa_next) {
        if(!strcmp(addr->ifa_name, [device UTF8String])) {
            if(addr->ifa_addr) {
                struct sockaddr_in *in_addr = (struct sockaddr_in *)addr->ifa_addr;
                if(in_addr->sin_family == AF_INET) {
                    ipAddress = [self IPv4Ntop:in_addr->sin_addr.s_addr];
                    break;
                }//end if
            }//end if
        }//end if
    }//end for
    
    freeifaddrs(addrs);
    return ipAddress;
}//end currentIPAddressOf:

- (nullable NSString *)IPv4Ntop: (in_addr_t)addr {
    char buffer[INET_ADDRSTRLEN] = {0};
    return inet_ntop(AF_INET, &addr, buffer, sizeof(buffer)) ?
    [NSString stringWithUTF8String:buffer] : nil;
}//end IPv4Ntop:

- (in_addr_t)IPv4Pton: (nonnull NSString *)IPAddr {
    in_addr_t network = INADDR_NONE;
    return inet_pton(AF_INET, [IPAddr UTF8String], &network) == 1 ?
    network : INADDR_NONE;
}//end IPv4Pton:
- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    [self initView];
 //  [self addNotifiCation];
    UINavigationController * nav;
    parseHandler = [[TcpParserHandler alloc] init];
//    self.view.layer.cornerRadius
//    self.view.layer.masksToBounds
//    self.view.layer.borderColor
//    self.view.layer.borderWidth
    
    
}



//- (void)addNotifiCation {
//    
//    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_accessoryDidConnect:) name:EAAccessoryDidConnectNotification object: nil];
//    
//    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_accessoryDidDisconnect:) name:EAAccessoryDidDisconnectNotification object:nil];
//    
//    [[EAAccessoryManager sharedAccessoryManager] registerForLocalNotifications];
//    
//    [[EAAccessoryManager sharedAccessoryManager] connectedAccessories];
//
//}

- (void)_accessoryDidConnect:(NSNotification *)notification {

 //   [self updateTextMsg:@"连接上了"];
}

- (void)_accessoryDidDisconnect:(NSNotification *)notification {
    
 //   [self updateTextMsg:@"断开连接了"];
}

- (void)initView {
    
    startButton = [self.view viewWithTag:10];
    sendButton = [self.view viewWithTag:20];
    textView = [self.view viewWithTag:30];
    tcpInitButton = [self.view viewWithTag:32];
    vinTcpButton = [self.view viewWithTag:33];
    svtTcpButton = [self.view viewWithTag:34];
    clearButton = [self.view viewWithTag:40];
    
    UITapGestureRecognizer * startTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(start)];
    UITapGestureRecognizer * sendTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(send)];
    UITapGestureRecognizer * exitTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(exit)];

    
    [startButton addGestureRecognizer:startTap];
    [sendButton addGestureRecognizer:sendTap];
    [tcpInitButton addTarget:self action:@selector(TcpInit) forControlEvents:UIControlEventTouchUpInside];
    [vinTcpButton addTarget:self action:@selector(TcpVinSend) forControlEvents:UIControlEventTouchUpInside];
    [svtTcpButton addTarget:self action:@selector(TcpSvtSend) forControlEvents:UIControlEventTouchUpInside];
    [clearButton addTarget:self action:@selector(clearText) forControlEvents:UIControlEventTouchUpInside];
    
    [self.view addGestureRecognizer:exitTap];
    
}
/**
 * This method is called immediately prior to socket:didAcceptNewSocket:.
 * It optionally allows a listening socket to specify the socketQueue for a new accepted socket.
 * If this method is not implemented, or returns NULL, the new accepted socket will create its own default queue.
 *
 * Since you cannot autorelease a dispatch_queue,
 * this method uses the "new" prefix in its name to specify that the returned queue has been retained.
 *
 * Thus you could do something like this in the implementation:
 * return dispatch_queue_create("MyQueue", NULL);
 *
 * If you are placing multiple sockets on the same queue,
 * then care should be taken to increment the retain count each time this method is invoked.
 *
 * For example, your implementation might look something like this:
 * dispatch_retain(myExistingQueue);
 * return myExistingQueue;
**/
- (nullable dispatch_queue_t)newSocketQueueForConnectionFromAddress:(NSData *)address onSocket:(GCDAsyncSocket *)sock{
    
  //  [self updateTextMsg:@"newSocketQueueForConnectionFromAddress"];
    return dispatch_queue_create(0, 0);
}

/**
 * Called when a socket accepts a connection.
 * Another socket is automatically spawned to handle it.
 *
 * You must retain the newSocket if you wish to handle the connection.
 * Otherwise the newSocket instance will be released and the spawned connection will be closed.
 *
 * By default the new socket will have the same delegate and delegateQueue.
 * You may, of course, change this at any time.
**/
- (void)socket:(GCDAsyncSocket *)sock didAcceptNewSocket:(GCDAsyncSocket *)newSocket{
    
  //  [self updateTextMsg:[NSString stringWithFormat:@"tcp 收到主机允许连接的回调"]];
}

/**
 * Called when a socket connects and is ready for reading and writing.
 * The host parameter will be an IP address, not a DNS name.
**/
- (void)socket:(GCDAsyncSocket *)sock didConnectToHost:(NSString *)host port:(uint16_t)port{
    
  //  [self updateTextMsg:[NSString stringWithFormat:@"连接到主机: %@ 端口: %d",host,port]];
  //  [sock readDataWithTimeout:-1 tag:0];
}

/**
 * Called when a socket connects and is ready for reading and writing.
 * The host parameter will be an IP address, not a DNS name.
 **/
- (void)socket:(GCDAsyncSocket *)sock didConnectToUrl:(NSURL *)url{
    
   // [self updateTextMsg:[NSString stringWithFormat:@"didConnectToUrl : %@",url.absoluteString]];
}

/**
 * Called when a socket has completed reading the requested data into memory.
 * Not called if there is an error.
**/
- (void)socket:(GCDAsyncSocket *)sock didReadData:(NSData *)data withTag:(long)tag{
    
    [sock readDataWithTimeout:-1 tag:tag];
   // char * charData = (char*)data.bytes;
    NSString * hexString = [self convertDataToHexStrBLE:data];
    NSString * dstString = [parseHandler tceReceiveData:data];
  //  NSString * strData = [NSString stringWithUTF8String:charData];
  //  [self updateTextMsg:[NSString stringWithFormat:@"收到tcp 数据tag: %ld data.len: %ld hexString: %@ 解析后的字符串: %@",tag,data.length,hexString,dstString]];

        static bool issendsvt = false;
        if(issendsvt == false && dstString.length > 0){
            [self TcpSvtSend];
            issendsvt = true;
        }
//        NSData * data = [dstString dataUsingEncoding:NSUTF8StringEncoding];
//        NSDictionary * jsonDict = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingFragmentsAllowed error:nil];
//        if([jsonDict.allKeys containsObject:@"sgbms"]){
//            NSString * sgbmsString = @"";
//            NSArray * sgbms = jsonDict[@"sgbms"];
//            for(NSString * item in sgbms){
//                sgbmsString = [sgbmsString stringByAppendingFormat:@"%@\n",item];
//            }
//            [self updateTextMsg:[NSString stringWithFormat:@"ECU版本信息:%@",sgbmsString]];
//        }
 //   }
    NSError * error;
    NSData * dataa = [dstString dataUsingEncoding:NSUTF8StringEncoding];
    NSDictionary * jsonDict = [NSJSONSerialization JSONObjectWithData:dataa options:NSJSONReadingFragmentsAllowed error:&error];
  //  [self updateTextMsg:[NSString stringWithFormat:@"jsonDict:%@",jsonDict]];
    if([jsonDict.allKeys containsObject:@"sgbms"] && !error){
        NSString * sgbmsString = @"";
        NSArray * sgbms = jsonDict[@"sgbms"];
        for(NSString * item in sgbms){
            sgbmsString = [sgbmsString stringByAppendingFormat:@"%@\n",item];
        }
        [self updateTextMsg:[NSString stringWithFormat:@"ECU版本信息: \n%@",sgbmsString]];
    }
}

/**
 * Called when a socket has read in data, but has not yet completed the read.
 * This would occur if using readToData: or readToLength: methods.
 * It may be used for things such as updating progress bars.
**/
- (void)socket:(GCDAsyncSocket *)sock didReadPartialDataOfLength:(NSUInteger)partialLength tag:(long)tag{
    
  //  [self updateTextMsg:@"didReadPartialDataOfLength"];
}

/**
 * Called when a socket has completed writing the requested data. Not called if there is an error.
**/
- (void)socket:(GCDAsyncSocket *)sock didWriteDataWithTag:(long)tag{
  
  //  [self updateTextMsg:[NSString stringWithFormat:@"tcp 发送数据 tag: %ld",tag]];
    
}

/**
 * Called when a socket has written some data, but has not yet completed the entire write.
 * It may be used for things such as updating progress bars.
**/
- (void)socket:(GCDAsyncSocket *)sock didWritePartialDataOfLength:(NSUInteger)partialLength tag:(long)tag{
    
    
  //  [self updateTextMsg:@"didWritePartialDataOfLength"];
}

/**
 * Called if a read operation has reached its timeout without completing.
 * This method allows you to optionally extend the timeout.
 * If you return a positive time interval (> 0) the read's timeout will be extended by the given amount.
 * If you don't implement this method, or return a non-positive time interval (<= 0) the read will timeout as usual.
 *
 * The elapsed parameter is the sum of the original timeout, plus any additions previously added via this method.
 * The length parameter is the number of bytes that have been read so far for the read operation.
 *
 * Note that this method may be called multiple times for a single read if you return positive numbers.
**/
- (NSTimeInterval)socket:(GCDAsyncSocket *)sock shouldTimeoutReadWithTag:(long)tag
                                                                 elapsed:(NSTimeInterval)elapsed
               bytesDone:(NSUInteger)length{
    
   // [self updateTextMsg:@"shouldTimeoutReadWithTag"];
    
    return -1;
}

/**
 * Called if a write operation has reached its timeout without completing.
 * This method allows you to optionally extend the timeout.
 * If you return a positive time interval (> 0) the write's timeout will be extended by the given amount.
 * If you don't implement this method, or return a non-positive time interval (<= 0) the write will timeout as usual.
 *
 * The elapsed parameter is the sum of the original timeout, plus any additions previously added via this method.
 * The length parameter is the number of bytes that have been written so far for the write operation.
 *
 * Note that this method may be called multiple times for a single write if you return positive numbers.
**/
- (NSTimeInterval)socket:(GCDAsyncSocket *)sock shouldTimeoutWriteWithTag:(long)tag
                                                                  elapsed:(NSTimeInterval)elapsed
               bytesDone:(NSUInteger)length{
    
  //  [self updateTextMsg:@"shouldTimeoutWriteWithTag"];
    
    return -1;
}

/**
 * Conditionally called if the read stream closes, but the write stream may still be writeable.
 *
 * This delegate method is only called if autoDisconnectOnClosedReadStream has been set to NO.
 * See the discussion on the autoDisconnectOnClosedReadStream method for more information.
**/
- (void)socketDidCloseReadStream:(GCDAsyncSocket *)sock{
    
  //  [self updateTextMsg:@"socketDidCloseReadStream"];
}

/**
 * Called when a socket disconnects with or without error.
 *
 * If you call the disconnect method, and the socket wasn't already disconnected,
 * then an invocation of this delegate method will be enqueued on the delegateQueue
 * before the disconnect method returns.
 *
 * Note: If the GCDAsyncSocket instance is deallocated while it is still connected,
 * and the delegate is not also deallocated, then this method will be invoked,
 * but the sock parameter will be nil. (It must necessarily be nil since it is no longer available.)
 * This is a generally rare, but is possible if one writes code like this:
 *
 * asyncSocket = nil; // I'm implicitly disconnecting the socket
 *
 * In this case it may preferrable to nil the delegate beforehand, like this:
 *
 * asyncSocket.delegate = nil; // Don't invoke my delegate method
 * asyncSocket = nil; // I'm implicitly disconnecting the socket
 *
 * Of course, this depends on how your state machine is configured.
**/
- (void)socketDidDisconnect:(GCDAsyncSocket *)sock withError:(nullable NSError *)err{
   
  //  [self updateTextMsg:@"socketDidDisconnect"];
    
}

/**
 * Called after the socket has successfully completed SSL/TLS negotiation.
 * This method is not called unless you use the provided startTLS method.
 *
 * If a SSL/TLS negotiation fails (invalid certificate, etc) then the socket will immediately close,
 * and the socketDidDisconnect:withError: delegate method will be called with the specific SSL error code.
**/
- (void)socketDidSecure:(GCDAsyncSocket *)sock{
    
  //  [self updateTextMsg:@"socketDidSecure"];
    
}

/**
 * Allows a socket delegate to hook into the TLS handshake and manually validate the peer it's connecting to.
 *
 * This is only called if startTLS is invoked with options that include:
 * - GCDAsyncSocketManuallyEvaluateTrust == YES
 *
 * Typically the delegate will use SecTrustEvaluate (and related functions) to properly validate the peer.
 *
 * Note from Apple's documentation:
 *   Because [SecTrustEvaluate] might look on the network for certificates in the certificate chain,
 *   [it] might block while attempting network access. You should never call it from your main thread;
 *   call it only from within a function running on a dispatch queue or on a separate thread.
 *
 * Thus this method uses a completionHandler block rather than a normal return value.
 * The completionHandler block is thread-safe, and may be invoked from a background queue/thread.
 * It is safe to invoke the completionHandler block even if the socket has been closed.
**/
- (void)socket:(GCDAsyncSocket *)sock didReceiveTrust:(SecTrustRef)trust
completionHandler:(void (^)(BOOL shouldTrustPeer))completionHandler{
    
    
  //  [self updateTextMsg:@"tcp didReceiveTrust"];
}



- (void)udpSocket:(GCDAsyncUdpSocket *)sock didConnectToAddress:(NSData *)address{
    
  //  [self updateTextMsg:[NSString stringWithFormat:@"DidConnectToAddress: %@",address]];
    
}
- (void)udpSocketDidClose:(GCDAsyncUdpSocket *)sock withError:(NSError  * _Nullable)error{
    
 //   [self updateTextMsg:[NSString stringWithFormat:@"udpSocketDidClose: %@",error]];
    
}

/**
 * Called when the datagram with the given tag has been sent.
**/
- (void)udpSocket:(GCDAsyncUdpSocket *)sock didSendDataWithTag:(long)tag{
    
  //  [self updateTextMsg:[NSString stringWithFormat:@"didsendDataWithTag: %ld",tag]];
}

/**
 * Called if an error occurs while trying to send a datagram.
 * This could be due to a timeout, or something more serious such as the data being too large to fit in a sigle packet.
**/
- (void)udpSocket:(GCDAsyncUdpSocket *)sock didNotSendDataWithTag:(long)tag dueToError:(NSError * _Nullable)error{
  //  [self updateTextMsg:[NSString stringWithFormat:@"消息发送失败 tag: %ld",tag]];
}

- (void)udpSocket:(GCDAsyncUdpSocket *)sock didReceiveData:(NSData *)data
                                             fromAddress:(NSData *)address
withFilterContext:(nullable id)filterContext{
    
   // NSString * ip_str = [[NSString alloc] initWithData:address encoding:NSUTF8StringEncoding];
    
//    char * addressdata = (char*)address.bytes;
//    int address_1 = (addressdata >> 12) & 0xff;
//    int address_2 = (addressdata >> 8) & 0xff;
//    int address_3 = (addressdata >> 4) & 0xff;
//    int address_4 = (addressdata >> 0) & 0xff;
    
    
    // NSString * address_ip = [NSString stringWithFormat:@"%d.%d.%d.%d",address_1,address_2,address_3,address_4];
    
    NSString * address_ip = [GCDAsyncUdpSocket hostFromAddress:address];
    uint16_t port = [GCDAsyncUdpSocket portFromAddress:address];
    
    NSMutableData * mutableData = [[NSMutableData alloc] initWithData:data];
    NSData * carNumData = [mutableData subdataWithRange:NSMakeRange(39, 17)];
    
    char * carNumChar = (char*)carNumData.bytes;
    NSString * carNum = [NSString stringWithUTF8String:carNumChar];
   
//    self.view.layer.cornerRadius;
//    self.view.layer.masksToBounds;
    
  //  [self updateTextMsg:[NSString stringWithFormat:@"收到来自ip: %@ 端口: %d  的数据包: %@ ",address_ip,port,carNum]];
    [self updateTextMsg:[NSString stringWithFormat:@"车辆vin: \n%@",carNum]];
    
    [self TcpInit];
}

- (void)exit {
    [textView resignFirstResponder];
}
- (void)start {
    
   // NSError * UDPError;
    NSError * error;
    udpSocket = [[GCDAsyncUdpSocket alloc] initWithDelegate:self delegateQueue:dispatch_queue_create(0, 0) socketQueue:dispatch_queue_create(0, 0)];
  //  [udpSocket setIPv4Enabled:YES];
   // [udpSocket setIPv6Enabled:NO];
   // [udpSocket enableBroadcast:YES error:&UDPError];
   // if(UDPError){
    //    [self updateTextMsg:[NSString stringWithFormat:@" udpsocket 开启组播失败: %@",UDPError]];
   // }
    
    
    // 获取本机的Ip 这里需要判断是否是以169开头
    NSString * localip = @"";
    NSString * interface = @"";
    NSDictionary * ipDict = [self getIPAddr];
   // [self updateTextMsg:[self getIPAddress:YES]];
  //  [self updateTextMsg:ipDict];
    for (NSString * key in ipDict.allKeys) {
        NSString * ipaddress = ipDict[key];
        if([ipaddress hasPrefix:@"169."]){
         //   [self updateTextMsg:ipaddress];
           // NSArray * items = [key componentsSeparatedByString:@"/"];
            interface = ipaddress;
        }
    }
    BOOL succ = [udpSocket bindToPort:local_port interface:interface error:&error];
    if(error){
      //  [self updateTextMsg:[NSString stringWithFormat:@"绑定ip失败: %@",error.description]];
        return;
    }
    if(succ){
      //  [self updateTextMsg:@"绑定ip成功"];
    }
    [udpSocket beginReceiving:&error];
    if(error){
      //  [self updateTextMsg:[NSString stringWithFormat:@" 开启响应数据失败： %@",error]];
    }
    [self updateTextMsg:[NSString stringWithFormat:@"车辆ip: \n%@",remote_ip]];
  // [udpSocket bindToPort:local_port error:&error];
 //  if(error){
   //     NSLog(@"------>   error: %@",error);
   // }else{
   //     [self updateTextMsg:@"创建udp成功"];
   // }
    
    //获取配件的所有信息
   /* NSMutableArray *accessoryList = [[NSMutableArray alloc] initWithArray:[[EAAccessoryManager sharedAccessoryManager] connectedAccessories]];
    // 比如：获取配件名称
    if(accessoryList.count > 0){
        NSString *name = [accessoryList[0] name];
        
        [self updateTextMsg:name];
    }else{
        
        [self updateTextMsg:@"name 数量为空 "];
    }*/
}
- (void) send {

    NSData * data = [self hexStringTodata:datapacket_boardcast];
    
 //   [self updateTextMsg:@"发送数据之前"];
    [udpSocket sendData:data toHost:remote_ip port:gateway_port withTimeout:-1 tag:1000];
//   [self updateTextMsg:@"发送数据之后"];
    
}

-(void) TcpInit {
    
    tcpSocket = [[GCDAsyncSocket alloc] initWithDelegate:self delegateQueue:dispatch_queue_create(0, 0) socketQueue:dispatch_queue_create(0, 0)];
    NSError * error;
    BOOL isConnect = [tcpSocket connectToHost:remote_ip onPort:remote_tcp_port error:&error];
    if(error){
        [self updateTextMsg:[NSString stringWithFormat:@"tcp 连接出错: %@",error]];
        return;
    }
    if(!isConnect){
       // [self updateTextMsg:[NSString stringWithFormat:@"tcp 连接到 %@ 失败",remote_ip]];
        return;
    }else{
     //   [self updateTextMsg:@"tcp 连接成功"];
        [self TcpVinSend];
    }
}
-(void) clearText{
    textView.text = @"";
}


-(void) TcpVinSend {

    NSData * vinData = [self hexStringTodata:datapacket_vin];
    long tag = random();
    [tcpSocket writeData:vinData withTimeout:-1 tag:tag];
    [tcpSocket readDataWithTimeout:-1 tag:tag];
  // [self updateTextMsg:[NSString stringWithFormat:@"tcp 发送数据: %@ tag: %ld",[self convertDataToHexStrBLE:vinData],tag]];
}
-(void) TcpSvtSend {
    
    NSData * svtData = [self hexStringTodata:datapacket_svt];
    long tag = random();
    [tcpSocket writeData:svtData withTimeout:-1 tag:tag];
    [tcpSocket readDataWithTimeout:-1 tag:tag];
    
  //  [self updateTextMsg:[NSString stringWithFormat:@"tcp 发送数据: %@ tag: %ld",[self convertDataToHexStrBLE:svtData],tag]];
}



-(NSString*)convertDataToHexStrBLE:(NSData*)data {
    
    if(!data || [data length] ==0)
        
    {
        return nil;
    }
    
    NSMutableString * string = [[NSMutableString alloc]initWithCapacity:[data length]];
    
    [data enumerateByteRangesUsingBlock:^(const void*bytes,NSRange byteRange,BOOL*stop) {
        unsigned char*dataBytes = (unsigned char*)bytes;
        for(NSInteger i =0; i < byteRange.length; i++)
        {
          //  NSString * hexStr = [NSString stringWithFormat:@"%x", (dataBytes[i]) &0xff];
            NSString * hexStr = [NSString stringWithFormat:@"%02x", (dataBytes[i]) &0xff];
            [string appendString:hexStr];
         /*   if([hexStr length] ==2) {
                [string appendString:hexStr];
            }else
            {
                [string appendFormat:@"0%@", hexStr];
            }*/
        }
    }];
    
    return string;
}



- (NSData *)hexStringTodata:(NSString *)hexString {
    
    Byte byte[[hexString length] / 2];
    for (int i = 0; i < sizeof(byte); i++) {
        NSString *str = [hexString substringWithRange:NSMakeRange(i*2,2)];
     char *p;
     unsigned int num = strtoul([str UTF8String], &p,16);//将16进制转换成十进制
    byte[i] = num;
    }
    NSData * data = [NSData dataWithBytes:byte length:hexString.length / 2];
    
    return data;
}



-(void) updateTextMsg:(NSString *)msg {
    
    dispatch_async(dispatch_get_main_queue(), ^{
        textView.text = [textView.text stringByAppendingFormat:@"\n%@",msg];
    });
 
  //  [textView setContentOffset:CGPointMake(0, textView.contentSize.height) animated:YES];
}

@end
