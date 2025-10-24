//
//  TcpSpeedTestHandler.m
//  CarLinkChannel
//
//  Created by job on 2023/4/25.
//

#import "TcpSpeedTestHandler.h"

@interface TcpSpeedTestHandler()
{
//    CommunityInterface * communityInterface;
    
    AutoNetworkService *Network;
    
    float ThrottleValue;
    float turboBoostValue;
    uint16_t engineRPMValue;
    uint8_t currentGear;
    uint8_t speedValue;
}

@end
@implementation TcpSpeedTestHandler
-(instancetype)init{
    self = [super init];
    if(self){
        Network = [AutoNetworkService sharedInstance];
    }
    return  self;
}

-(BOOL)startSpeedTest {
    return [self->Network TestVedioSetState];
  //  return true;
}


- (NSDictionary *)ReadSpeedDataFromVehicle:(BOOL)state {
    return [self->Network ReadVehcileAboutSpeedData:state];
   // return nil;
}



-(void)sendSpeedTestPacket2{
//    [self->communityInterface sendSpeedTestPacket2];
}
-(void)sendSpeedTestPacket3Sero2 {
//    [self->communityInterface sendSpeedTestPacket3Sero2];
}
-(void)sendspeedTest {
//    [self->communityInterface sendSpeedTestPacket3];
}
-(NSDictionary *)Sero1parseSpeedTestData:(NSString *)dataString{
    
    NSString * speedString = [dataString substringFromIndex:packet_speed_index];
    
    NSString * youmenString1 = [speedString substringWithRange:NSMakeRange(0, 2)];
    NSString * youmenStirng2 = [speedString substringWithRange:NSMakeRange(2, 2)];
    
    // 2023-07-10 年，涡轮压力过大，现在对这个值从原来的4位长度修改到2位长度
    NSString * wolunString = [speedString substringWithRange:NSMakeRange(4, 4)];
    NSString * zhuanshuString = [speedString substringWithRange:NSMakeRange(8, 4)];
    
    NSString * dangweiString = [speedString substringWithRange:NSMakeRange(12, 2)];
    NSString * shuduString = [speedString substringWithRange:NSMakeRange(14, 4)];
    
    unsigned int youmen1 = 0,youmen2 = 0,wolun = 0,zhuanshu = 0,danwei = 0,shudu = 0;
 
   // NSString *hexCharStr = [hexString substringWithRange:range];
    NSScanner *scanner = [[NSScanner alloc] initWithString:youmenString1];
    [scanner scanHexInt:&youmen1];
    
    scanner = [[NSScanner alloc] initWithString:youmenStirng2];
    [scanner scanHexInt:&youmen2];
    
    scanner = [[NSScanner alloc] initWithString:wolunString];
    [scanner scanHexInt:&wolun];
    
    scanner = [[NSScanner alloc] initWithString:zhuanshuString];
    [scanner scanHexInt:&zhuanshu];
    
    scanner = [[NSScanner alloc] initWithString:dangweiString];
    [scanner scanHexInt:&danwei];
    
    scanner = [[NSScanner alloc] initWithString:shuduString];
    [scanner scanHexInt:&shudu];
    
    youmen1 = youmen1 * 99 / 255;
    youmen2 = youmen2 * 99 / 255;
    NSString * speed = @"";
    if(youmen1 > 9){
        speed = @"99";
    }else{
        if(youmen2 > 9){
            speed = [NSString stringWithFormat:@"%d",youmen1 * 10 + 9];
        }else{
            speed = [NSString stringWithFormat:@"%d",youmen1 * 10 + youmen2];
        }
        
    }
    
    
    NSString * woluntemp = @"336E";
    unsigned  int woluntempint = 0;
    scanner = [[NSScanner alloc] initWithString:woluntemp];
    [scanner scanHexInt:&woluntempint];
    

    CGFloat wolunfloat = 0;
    if(wolun < woluntempint){
       wolunfloat = 0;
    }else{
       wolunfloat = ( wolun - woluntempint ) / 13.1;
    }
    
    if(wolunfloat <0 ){
        wolunfloat = 0;
    }
    
    zhuanshu = zhuanshu / 2;
    
    shudu = shudu / 100;
    
//    NSLog(@"---------------->  测速 分支1: %@,wolunString: %@,wolun: %d,woluntempint: %d,wolunfloat: %lf",dataString,wolunString,wolun,woluntempint,wolunfloat);
    
    return @{@"youmen1":speed,@"wolun":@(wolunfloat),@"zhuanshu":@(zhuanshu),@"dangwei":@(danwei),@"shudu":@(shudu),@"sero":@"1"};
}
-(NSDictionary *)Sero2parseSpeedTestData:(NSString *)dataString{
    
    NSString * speedString = [dataString substringFromIndex:packet_speed_index];
    
    NSString * youmenString1 = [speedString substringWithRange:NSMakeRange(0, 2)];
    
    // 2023-07-10 年，涡轮压力过大，现在对这个值从原来的4位长度修改到2位长度
    NSString * wolunString = [speedString substringWithRange:NSMakeRange(2, 4)];
//    NSString * wolunString = [speedString substringWithRange:NSMakeRange(2, 2)];
    NSString * zhuanshuString = [speedString substringWithRange:NSMakeRange(6, 4)];
    
    NSString * dangweiString = [speedString substringWithRange:NSMakeRange(10, 2)];
    NSString * shuduString = [speedString substringWithRange:NSMakeRange(12, 2)];
    
    unsigned int youmen1 = 0,wolun = 0,zhuanshu = 0,danwei = 0,shudu = 0;

   // NSString *hexCharStr = [hexString substringWithRange:range];
    NSScanner *scanner = [[NSScanner alloc] initWithString:youmenString1];
    [scanner scanHexInt:&youmen1];
    

    
    scanner = [[NSScanner alloc] initWithString:wolunString];
    [scanner scanHexInt:&wolun];
    
    scanner = [[NSScanner alloc] initWithString:zhuanshuString];
    [scanner scanHexInt:&zhuanshu];
    
    scanner = [[NSScanner alloc] initWithString:dangweiString];
    [scanner scanHexInt:&danwei];
    
    scanner = [[NSScanner alloc] initWithString:shuduString];
    [scanner scanHexInt:&shudu];
    
    youmen1 = youmen1 * 99 / 255;
    NSString * speed = [NSString stringWithFormat:@"%d",youmen1];
    
    
    NSString * woluntemp = @"3300";
    unsigned int woluntempint = 0;
    scanner = [[NSScanner alloc] initWithString:woluntemp];
    [scanner scanHexInt:&woluntempint];
    
    
    CGFloat wolunfloat = 0;
    if(wolun < woluntempint){
        wolunfloat = 0;
    }else{
        wolunfloat = ( wolun - woluntempint ) / 12.0;
    }

    if(wolunfloat < 0 ){
        wolunfloat = 0;
    }
    
    zhuanshu = zhuanshu / 2;
    
    
//    NSLog(@"---------------->  测速 分支2: %@,wolunString: %@,wolun: %d,woluntempint: %d,wolunfloat: %lf",dataString,wolunString,wolun,woluntempint,wolunfloat);
    
    return @{@"youmen1":speed,@"wolun":@(wolunfloat),@"zhuanshu":@(zhuanshu),@"dangwei":@(danwei),@"shudu":@(shudu),@"sero":@"2"};
}
@end
