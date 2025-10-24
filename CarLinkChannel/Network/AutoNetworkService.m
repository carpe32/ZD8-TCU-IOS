//
//  AutoNetworkService.m
//  CarLinkChannel
//
//  Created by 刘润泽 on 2024/9/23.
//

#import "AutoNetworkService.h"
static const DDLogLevel ddLogLevel = DDLogLevelVerbose;
@interface AutoNetworkService()
{
    int serotype;
    NSArray *CafdInfo;
    NSString *VehicleVIN;
}
@property(nonatomic, strong) VehicleLoaclNetworkManager *LocalNetworkManager;
@property(nonatomic, strong) id<VehicleTypeProgramming> currentProgrammer;
@end


@implementation AutoNetworkService

static AutoNetworkService *NetworksharedManager = nil;
static dispatch_once_t onceToken;
static BOOL needsReset = NO;
//shard manager
+(instancetype)sharedInstance{
    if (needsReset) {
        // 重置单例和onceToken
        NetworksharedManager = nil;
        onceToken = 0;
        needsReset = NO;
    }
    
    dispatch_once(&onceToken, ^{
        NetworksharedManager = [[self alloc] init];
        [NetworksharedManager initializeTCPConnection];
    });
    
    return NetworksharedManager;
}
//reset shared
+ (void)resetSharedManager {
    needsReset = YES;
}
//init network(start with udp)
- (void)initializeTCPConnection {
    self.LocalNetworkManager = [[VehicleLoaclNetworkManager alloc] init];
}

-(void)setVehicleType:(int)type{

    switch (type)
    {
        case 1:
            self.currentProgrammer = [[VehicleClass1 alloc] initWithManager:self.LocalNetworkManager];
             break;
         case 2:
             self.currentProgrammer = [[VehicleClass2 alloc] initWithManager:self.LocalNetworkManager];
             break;
         case 3:
             self.currentProgrammer = [[VehicleClass3 alloc] initWithManager:self.LocalNetworkManager];
             break;
         case 4:
             self.currentProgrammer = [[VehicleClass4 alloc] initWithManager:self.LocalNetworkManager];
             break;
         case 5:
             self.currentProgrammer = [[VehicleClass5 alloc] initWithManager:self.LocalNetworkManager];
             break;
         case 6:
             self.currentProgrammer = [[VehicleClass6 alloc] initWithManager:self.LocalNetworkManager];
             break;
         default:
             NSLog(@"Invalid type: %d", type);
             break;
    }
}

//Read Vin
-(NSString *)ReadVehicleVIN{
    self->VehicleVIN = [self.LocalNetworkManager ReadVehicleVin];
    return self->VehicleVIN;
}
-(NSString *)ReadSaveVIN{
    return self->VehicleVIN;
}

//Read Svt
-(NSArray *)ReadVehicleSvt{
    NSData *SvtOriginalData = [self.LocalNetworkManager ReadVehicleSvt];
    // 将 NSData 对象转换为十六进制字符串
    NSString *SvtHexString = [NSData hexStringFromHexData:SvtOriginalData];
    // 将十六进制字符串转换为大写形式
    SvtHexString = [SvtHexString uppercaseString];
    // 使用 LuaInvoke 类进行解析
    LuaInvoke *invoke = [[LuaInvoke alloc] init];
    NSString *SvtString =  [invoke parseEcuWithHexString:SvtHexString];
    NSLog(@"svt information : %@" ,SvtString);
    NSData *jsonData = [SvtString dataUsingEncoding:NSUTF8StringEncoding];
    NSError *error;
    NSDictionary *jsonDict = [NSJSONSerialization JSONObjectWithData:jsonData options:0 error:&error];
    if([jsonDict.allKeys containsObject:@"sgbms"] && !error){
        NSArray * sgbmsArray = jsonDict[@"sgbms"];
        for (NSString *sgbm in sgbmsArray) {
            NSLog(@"%@", sgbm);
        }
        
        NSString *result = [sgbmsArray componentsJoinedByString:@"\r\n                                   "];
        DDLogInfo(@"%@",result);
        return sgbmsArray;
    }
    DDLogInfo(@"Read Svt Error");
    return nil;
}
-(void)WakeUpGetway{
    [self.LocalNetworkManager UDS_RoutinContro:0x40 :[NSData dataWithBytes:(uint8_t[]){0x01} length:1] :[NSData dataWithBytes:(uint8_t[]){0x10,0x01,0x0a,0x0a,0x43} length:5] :1000];

}

-(NSData *)ReadVehicleSN{
    return [self.LocalNetworkManager ReadVehicleSN];
}

//Read Cafd
-(NSArray *)ReadCafd:(int)VehicleClass{
    CafdInfo = [self.currentProgrammer ReadCafd];
    return CafdInfo;
}

-(NSDictionary *)ReadTCUHealthData{
    return [self.currentProgrammer ReadHealth];
}

-(void)SetVehicleClass:(int)classType{
    [self setVehicleType:classType];
}

-(void)ClearFaultForVehicle{
    [self.currentProgrammer ClearFault];
}

-(void)performCarECUFlash:(NSString *)Filepath :(NSString *)VIN :(NSArray *)VehicleVersionInfo delegate:(id<FlashFeedbackDelegate>)delegate{
    self.currentProgrammer.delegate = delegate;
    
//    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"SELF BEGINSWITH %@", @"CAFD"];
//    NSArray *filteredArray = [VehicleVersionInfo filteredArrayUsingPredicate:predicate];
//    if(filteredArray.count == 0)
//    {
        UploadManager *uploadManager = [UploadManager sharedInstance];
        CafdInfo = [uploadManager ReadServerCafd];
//    }
    [self.currentProgrammer LoadFileToVehicle:Filepath :VIN :VehicleVersionInfo :CafdInfo];
}

-(void)performRecoveryCafd:(NSString *)VIN :(NSArray *)VehicleVersionInfo delegate:(id<FlashFeedbackDelegate>)delegate{
    self.currentProgrammer.delegate = delegate;
    
    UploadManager *uploadManager = [UploadManager sharedInstance];
    CafdInfo = [uploadManager ReadServerCafd];
    
    [self.currentProgrammer RecoveryCafdToVehicle:VIN :VehicleVersionInfo :CafdInfo];
}

-(void)ServerRecoveryCafd:(NSString *)VIN :(NSArray *)VehicleVersionInfo :(NSArray *)Cafd delegate:(id<FlashFeedbackDelegate>)delegate{
    self.currentProgrammer.delegate = delegate;
    
    UploadManager *uploadManager = [UploadManager sharedInstance];
    CafdInfo = [uploadManager ReadServerCafd];
    
    [self.currentProgrammer RecoveryCafdToVehicle:VIN :VehicleVersionInfo :Cafd];
}

-(BOOL)TestVedioSetState{
    [self.LocalNetworkManager SetVedioSate:0x12 :[NSData dataWithBytes:(uint8_t[]){0x03} length:1] :[NSData dataWithBytes:(uint8_t[]){0xF3,0x00} length:2]];
    UDSResponse *result02 =[self.LocalNetworkManager SetVedioSate:0x12 :[NSData dataWithBytes:(uint8_t[]){0x01} length:1] :[NSData dataWithBytes:(uint8_t[]){0xF3,0x00 ,0x58 ,0x14 ,0x01 ,0x02 ,0x42 ,0x05 ,0x01 ,0x02 ,0x58 ,0x19 ,0x01 ,0x02 ,0x58 ,0x81 ,0x01 ,0x01 ,0x58 ,0x0D ,0x01 ,0x02} length:22]];
    
    if(result02.status == UdsResponseStatusSuccess)
    {
        return YES;
    }
    else
    {
        UDSResponse *result = [self.LocalNetworkManager SetVedioSate:0x12 :[NSData dataWithBytes:(uint8_t[]){0x01} length:1] :[NSData dataWithBytes:(uint8_t[]){0xf3,0x00,0x58,0x14,0x01,0x01,0x42,0x05,0x01,0x02,0x58,0x19,0x01,0x02,0x58,0x81,0x01,0x01,0x58,0x0d,0x01,0x01} length:22]];
        return NO;
    }
}

-(NSDictionary *)ReadVehcileAboutSpeedData:(BOOL)state{
    return [self.currentProgrammer readPowerUnitDataDuringDrive:state];
}

-(void)SendEnterDiagnostic{
    [self.LocalNetworkManager UDS_RoutinContro:0x40 :[NSData dataWithBytes:(uint8_t[]){0x01} length:1] :[NSData dataWithBytes:(uint8_t[]){0x10,0x01,0x0a,0x0a,0x43} length:5] :1000];
}

-(void)RemoveTransportMode{
    [self.LocalNetworkManager UDS_RoutinContro:0x18 :[NSData dataWithBytes:(uint8_t[]){0x01} length:1] :[NSData dataWithBytes:(uint8_t[]){0x0F,0x0C,0x00} length:3] :3000];
    [self.LocalNetworkManager UDS_RoutinContro:0x12 :[NSData dataWithBytes:(uint8_t[]){0x01} length:1] :[NSData dataWithBytes:(uint8_t[]){0x0F,0x0C,0x00} length:3] :3000];
    [self.LocalNetworkManager UDS_RoutinContro:0x63 :[NSData dataWithBytes:(uint8_t[]){0x01} length:1] :[NSData dataWithBytes:(uint8_t[]){0x0F,0x0C,0x00} length:3] :3000];
}

-(void)SendDataForegslearnreset{
    [self.LocalNetworkManager WriteDataByIdentifierToEcu:0x18 :[NSData dataWithBytes:(uint8_t[]){0x41,0x50} length:2] :[NSData dataWithBytes:(uint8_t[]){0x00} length:1] :3000];
}

-(NSArray<UDSMultipleResponse *> *)ReadDiagnose{
    return [self.LocalNetworkManager readDiagnosesDataWithinTimeout:[NSData dataWithBytes:(uint8_t[]){0x02} length:1] :[NSData dataWithBytes:(uint8_t[]){0x0C} length:1] :3000];
}

-(NSData *)ReadOnlyDiagnose:(uint8_t)EcuId{
    UDSResponse *Result = [self.LocalNetworkManager readOnlyDiagnosesData:EcuId :[NSData dataWithBytes:(uint8_t[]){0x02} length:1] :[NSData dataWithBytes:(uint8_t[]){0x0C} length:1]];
    if(Result.status == UdsResponseStatusSuccess)
    {
        return Result.payload;
    }
    
    return nil;
}

@end
