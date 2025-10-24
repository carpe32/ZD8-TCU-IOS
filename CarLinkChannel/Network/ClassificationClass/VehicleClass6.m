//
//  VehicleClass1.m
//  TTS Tuning
//
//  Created by 刘润泽 on 2024/8/7.
//

#import "VehicleClass6.h"

@interface VehicleClass6()

@property(nonatomic, strong) UDSProtocolDispatcher *ProtocolDispatcher;
@property(nonatomic, strong) UDSOperationResult *OperationResult;
@end

@implementation VehicleClass6

- (instancetype)initWithManager:(VehicleLoaclNetworkManager *)NetworkManager{
    self = [super init];
    if (self) {
        self.ProtocolDispatcher = [[UDSProtocolDispatcher alloc] initWithFid:0x18 :NetworkManager];
        self.OperationResult = [[UDSOperationResult alloc] init];
    }
    return self;
}

-(NSArray *)ReadCafd{
    return [self.ProtocolDispatcher ReadCafd:5 :3000];
}

-(void)ClearFault{
    [self.ProtocolDispatcher ClearDiagnosticInfo];
}

-(NSDictionary *)ReadHealth{
    NSMutableDictionary *ResultDic = [NSMutableDictionary dictionary];
    OperationResult *PressureResult = [self.ProtocolDispatcher ReadTcuHealth:0];
    if(PressureResult.state == YES)
    {
        ResultDic[@"pressure"] = PressureResult.receiveData;
    }
    OperationResult *TimeResult = [self.ProtocolDispatcher ReadTcuHealth:1];
    if(TimeResult.state == YES)
    {
        ResultDic[@"time"] = TimeResult.receiveData;
    }
    
    return ResultDic;
}

-(void)LoadFileToVehicle:(NSString *)FilePath :(NSString *)VehcileVin :(NSArray *)VehicleVersionInfo :(NSArray *)CafdInfo{
    NSArray *SendCafd = CafdInfo;
    FirmwareDataManager *Datamanager = [[FirmwareDataManager alloc] initWithFile:FilePath];
    OperationResult *result = [[OperationResult alloc] init];
    if(Datamanager.isValidBinFile){
        if(Datamanager.SetState2)
        {
            NSMutableArray *operationsSteg1 = [NSMutableArray array];
            [operationsSteg1 addObject:^OperationResult*{return [self.ProtocolDispatcher EnterDiagMode:3];}];
            [operationsSteg1 addObject:^OperationResult*{return [self.ProtocolDispatcher changeDiagnosticSession:0x01 :10000 :NO];}];                  //Enter default session
            [operationsSteg1 addObject:^OperationResult*{return [self.ProtocolDispatcher RoutineControlRequest:0x01 :[NSData dataWithBytes:(uint8_t[]){0x02, 0x03} length:2] :10000 :NO CheckType:0];}];       //routine control 0x01 0x02, 0x03
            [operationsSteg1 addObject:^OperationResult *{return [self.ProtocolDispatcher changeDiagnosticSession:0x03 :10000 :NO];}];                  //Enter extended diagnostic session
            [operationsSteg1 addObject:^OperationResult *{return [self.ProtocolDispatcher RoutineControlRequest:0x01 :[NSData dataWithBytes:(uint8_t[]){0x0f, 0x0c,0x03} length:3] :10000 :NO CheckType:0];}];  //routine control 0x01 0x0f, 0x0c,0x03
            [operationsSteg1 addObject:^OperationResult *{return [self.ProtocolDispatcher SetDTCState:false :10000 :NO];}];                             //close DTC (Diagnostic Toruble Code) 85 02
            [operationsSteg1 addObject:^OperationResult *{return [self.ProtocolDispatcher SetNormalCommunicationState:[NSData dataWithBytes:(uint8_t[]){0x01} length:1] :10000 :NO];}];//close CAN 28 01 01
            [operationsSteg1 addObject:^OperationResult *{return [self.ProtocolDispatcher RoutineControlRequest:0x01 :[NSData dataWithBytes:(uint8_t[]){0x10,0x03,0x01} length:3]  :10000 :NO CheckType:0];}];  //routine control 0x01 0x10,0x03,0x01
            if (![self.OperationResult executeOperations:operationsSteg1 delegate:self.delegate]) {
                 return; // 如果操作失败，停止执行后续代码
             }
        }
        
        NSUInteger FlashAllCount = [self GetAllStepCount:Datamanager.BlockInfo];
        [self.delegate DidGetFlashAllCount:FlashAllCount];
        
        for(FlashBlockInfo *BlockInfo in Datamanager.BlockInfo)
        {
            if(BlockInfo.SecurityState){                                                                //if need 27(security)
                NSMutableArray *operationsSecurity = [NSMutableArray array];
//                [operationsSecurity addObject:^OperationResult *{return [self.ProtocolDispatcher changeDiagnosticSession:0x02 :5000 :YES];}];              //Enter Programming session
                [operationsSecurity addObject:^OperationResult *{return [self.ProtocolDispatcher applySecurityProtocol:Vehicle1SecurityType11 :VehicleVersionInfo :10000];}];                     //security process
                [operationsSecurity addObject:^OperationResult *{return [self.ProtocolDispatcher WriteIdentifier:0xF15a :[NSData dataWithBytes:(uint8_t[]){0x23,0x05 ,0x16,0x8f,0x04,0xd2,0x01,0x00,0x00,0x10,0x00,0x00,0x00} length:13] :10000 :YES];}];
                if (![self.OperationResult executeOperations:operationsSecurity delegate:self.delegate]) {
                     return; // 如果操作失败，停止执行后续代码
                 }
            }
            
            if(BlockInfo.RoutineControlState == 1){
                uint8_t RoutinData[9] = {0xFF, 0x00, 0x02, 0x40};
                memcpy(RoutinData + 4, [BlockInfo.RoutineData bytes], 4);
                RoutinData[8] = 0x06;
                NSData *routinDataCopy = [NSData dataWithBytes:RoutinData length:9];
                usleep(10000);
                result = [self.OperationResult executeOperationWithBlock:^OperationResult *{return [self.ProtocolDispatcher RoutineControlRequest:0x01 :routinDataCopy :10000 :YES CheckType:0];} delegate:self.delegate];
                NSLog(@"result state: %d", result.state);
                if(!result.state) {
                    NSLog(@"Returning due to failed state");
                    return;
                }
                NSLog(@"Returning successfully");
            }
            else if(BlockInfo.RoutineControlState == 3){
                NSMutableArray *operations3103 = [NSMutableArray array];
                [operations3103 addObject:^OperationResult *{return [self.ProtocolDispatcher RoutineControlRequest:0x01 :[NSData dataWithBytes:(uint8_t[]){0xFF,0x00,0x02,0x40,0x09,0x77,0xfd,0x00} length:8] :10000 :YES CheckType:0];}];
                [operations3103 addObject:^OperationResult *{return [self.ProtocolDispatcher RoutineControlRequest:0x01 :[NSData dataWithBytes:(uint8_t[]){0xFF,0x00,0x02,0x40,0x09,0x67,0xfd,0x00} length:8] :10000 :YES CheckType:0];}];
                [operations3103 addObject:^OperationResult *{return [self.ProtocolDispatcher RoutineControlRequest:0x01 :[NSData dataWithBytes:(uint8_t[]){0xFF,0x00,0x02,0x40,0x09,0x03,0xfd,0x00} length:8] :10000 :YES CheckType:0];}];
                if (![self.OperationResult executeOperations:operations3103 delegate:self.delegate]) {
                     return; // 如果操作失败，停止执行后续代码
                 }
            }

            // Send ready for play
            result = [self.OperationResult executeOperationWithBlock:^OperationResult *{return [self.ProtocolDispatcher RequestStartDownloadToFlash:BlockInfo.RequestDownloadFormatID :0x44 :BlockInfo.BlockStartAddr :BlockInfo.BlockLength :10000 :YES];} delegate:self.delegate];       //34
            if(!result.state)
                return;
            
            NSArray *SendInfoArray = [self GetFlashData:BlockInfo.BlockData];
            
            NSMutableArray *operationsFlashData = [NSMutableArray array];
            for(FlashInfo *codeInfo in SendInfoArray){
                [operationsFlashData addObject:^OperationResult *{return [self.ProtocolDispatcher SendFileDataToVehicle:[NSData dataWithBytes:(uint8_t[]){codeInfo.index} length:1] :codeInfo.data :30000 :YES];}];    //send flash data
            }
            [operationsFlashData addObject:^OperationResult *{return [self.ProtocolDispatcher sendTesterPresent:1000];}];     //send present 3e 80
            [operationsFlashData addObject:^OperationResult *{return [self.ProtocolDispatcher sendExitTrans:5000 :YES];}];    //exit trans
            if (![self.OperationResult executeOperations:operationsFlashData delegate:self.delegate]) {
                 return; // 如果操作失败，停止执行后续代码
             }
            
            if(BlockInfo.CheckOperationState){
                uint8_t Senddata[10] = {0x02,0x02,0x12,0x40};
                memcpy(Senddata + 4,[BlockInfo.RoutineData bytes],4);
                Senddata[8] = 0;
                Senddata[9] = 0;
                NSData *SendDataCopy = [NSData dataWithBytes:Senddata length:10];
                result = [self.OperationResult executeOperationWithBlock:^OperationResult *{return [self.ProtocolDispatcher RoutineControlRequest:0x01 :SendDataCopy :10000 :YES CheckType:0];} delegate:self.delegate];
                if(!result.state)
                    return;
                
                if(BlockInfo.FF01State !=0x02)
                {
                    result = [self.OperationResult executeOperationWithBlock:^OperationResult *{return [self.ProtocolDispatcher RoutineControlRequest:0x01 :[NSData dataWithBytes:(uint8_t[]){0xff,0x01} length:2] :10000 :YES CheckType:0];} delegate:self.delegate];
                    if(!result.state)
                        return;
                }
            }
            
            if(BlockInfo.IsDefaultSessionRequired){
                result = [self.OperationResult executeOperationWithBlock:^OperationResult *{return [self.ProtocolDispatcher ResetEcu:3000 :NO :7];} delegate:self.delegate];
                if(!result.state)
                    return;
            }
            if(BlockInfo.SendOtherState){
                NSMutableArray *operationsOther = [NSMutableArray array];
                [operationsOther addObject:^OperationResult *{return [self.ProtocolDispatcher changeDiagnosticSession:0x03 :10000 :NO];}];         //Enter Extended Diagnostic Session 10 03
                [operationsOther addObject:^OperationResult *{return [self.ProtocolDispatcher RoutineControlRequest:0x01 :[NSData dataWithBytes:(uint8_t[]){0x0F,0x0c,0x03} length:3] :10000 :NO CheckType:0];}];
                [operationsOther addObject:^OperationResult *{return [self.ProtocolDispatcher SetDTCState:false :10000 :NO];}];
                [operationsOther addObject:^OperationResult *{return [self.ProtocolDispatcher SetNormalCommunicationState:[NSData dataWithBytes:(uint8_t[]){0x01} length:1] :10000 :NO];}];
                [operationsOther addObject:^OperationResult *{return [self.ProtocolDispatcher RoutineControlRequest:0x01 :[NSData dataWithBytes:(uint8_t[]){0x10,0x03,0x01} length:3] :10000 :NO CheckType:0];}];
                [operationsOther addObject:^OperationResult *{return [self.ProtocolDispatcher changeDiagnosticSession:0x01 :10000 :NO];}];         //Enter default session
                [operationsOther addObject:^OperationResult *{return [self.ProtocolDispatcher changeDiagnosticSession:0x03 :10000 :NO];}];         //Enter Extended Diagnostic Session
                if (![self.OperationResult executeOperations:operationsOther delegate:self.delegate]) {
                     return; // 如果操作失败，停止执行后续代码
                 }
            }
        }
        if(Datamanager.EndState1){
            NSMutableArray *operationsEnd = [NSMutableArray array];
            [operationsEnd addObject:^OperationResult *{return [self.ProtocolDispatcher RoutineControlRequest:0x01 :[NSData dataWithBytes:(uint8_t[]){0xFF,0x01} length:2] :10000  :NO CheckType:0];}];
            
            NSData *SendVindata = [VehcileVin dataUsingEncoding:NSASCIIStringEncoding];
            [operationsEnd addObject:^OperationResult *{return [self.ProtocolDispatcher WriteIdentifier:0xF190 :SendVindata :10000 :NO];}];
            [operationsEnd addObject:^OperationResult *{return [self.ProtocolDispatcher ResetEcu:10000 :NO :7];}];
            [operationsEnd addObject:^OperationResult *{return [self.ProtocolDispatcher changeDiagnosticSession:0x03 :10000 :NO];}];         //Enter Extended Diagnostic Session
            [operationsEnd addObject:^OperationResult *{return [self.ProtocolDispatcher RoutineControlRequest:0x01 :[NSData dataWithBytes:(uint8_t[]){0x0f,0x0c,0x00} length:3]  :10000 :NO CheckType:0];}];
            [operationsEnd addObject:^OperationResult *{return [self.ProtocolDispatcher ReadEcuInfo:[NSData dataWithBytes:(uint8_t[]){0x01} length:1] :10000 :NO];}];
            [operationsEnd addObject:^OperationResult *{return [self.ProtocolDispatcher changeDiagnosticSession:0x01 :5000 :NO];}];         //Enter default session
            [operationsEnd addObject:^OperationResult *{return [self.ProtocolDispatcher changeDiagnosticSession:0x03 :5000 :NO];}];         //Enter Extended Diagnostic Session
            if (![self.OperationResult executeOperations:operationsEnd delegate:self.delegate]) {
                 return; // 如果操作失败，停止执行后续代码
             }
        }
        
        if(Datamanager.EndState2){
            NSMutableArray *operationsEnd2 = [NSMutableArray array];
            [operationsEnd2 addObject:^OperationResult *{return [self.ProtocolDispatcher changeDiagnosticSession:0x41 :5000 :NO];}];
            [operationsEnd2 addObject:^OperationResult *{return [self.ProtocolDispatcher applySecurityProtocol:Vehicle1SecurityType01 :VehicleVersionInfo :5000];}];                     //security process
            if (![self.OperationResult executeOperations:operationsEnd2 delegate:self.delegate]) {
                 return; // 如果操作失败，停止执行后续代码
             }
        }
        result = [self.OperationResult executeOperationWithBlock:^OperationResult *{return [self.ProtocolDispatcher SendCafdToEcu:SendCafd :5000 :NO];} delegate:self.delegate];
        if(!result.state)
            return;
        
        //end3
        
        //end4
        if(Datamanager.EndState4){
            NSMutableArray *operationsEnd4 = [NSMutableArray array];
            [operationsEnd4 addObject:^OperationResult *{return [self.ProtocolDispatcher RoutineControlRequest:0x01 :[NSData dataWithBytes:(uint8_t[]){0x0f,0x01} length:2] :3000 :NO CheckType:0];}];
            NSData *SendVindata = [VehcileVin dataUsingEncoding:NSASCIIStringEncoding];
            SendVindata = [SendVindata subdataWithRange:NSMakeRange(SendVindata.length - 7, 7)];
            [operationsEnd4 addObject:^OperationResult *{return [self.ProtocolDispatcher WriteIdentifier:0x37FE :SendVindata :5000 :NO];}];
            [operationsEnd4 addObject:^OperationResult *{return [self.ProtocolDispatcher ResetEcu:3000 :NO :7];}];         //Enter default session
            [operationsEnd4 addObject:^OperationResult *{return [self.ProtocolDispatcher ClearDiagnosticInfo];}];
            [operationsEnd4 addObject:^OperationResult *{return [self.ProtocolDispatcher ReadDataByPeriodicIdentifier];}];
            if (![self.OperationResult executeOperations:operationsEnd4 delegate:self.delegate]) {
                 return; // 如果操作失败，停止执行后续代码
             }
        }
        
        [self.delegate processSuccess];
    }
}

-(void)RecoveryCafdToVehicle:(NSString *)VehcileVin :(NSArray *)VehicleVersionInfo :(NSArray *)CafdInfo{

    NSMutableArray *operationsOther = [NSMutableArray array];
    [operationsOther addObject:^OperationResult *{return [self.ProtocolDispatcher ResetEcu:3000 :YES :5];}];                             //Reset
    [operationsOther addObject:^OperationResult *{return [self.ProtocolDispatcher changeDiagnosticSession:0x01 :5000 :YES];}];         //Enter default session
    [operationsOther addObject:^OperationResult *{return [self.ProtocolDispatcher changeDiagnosticSession:0x03 :5000 :YES];}];         //Enter Extended Diagnostic Session
    [operationsOther addObject:^OperationResult *{return [self.ProtocolDispatcher changeDiagnosticSession:0x41 :5000 :YES];}];
    [operationsOther addObject:^OperationResult *{return [self.ProtocolDispatcher applySecurityProtocol:Vehicle1SecurityType01 :VehicleVersionInfo :5000];}];   //security process
    [operationsOther addObject:^OperationResult *{return [self.ProtocolDispatcher SendCafdToEcu:CafdInfo :5000 :YES];}];                  //Send Cafd
    [operationsOther addObject:^OperationResult *{return [self.ProtocolDispatcher RoutineControlRequest:0x01 :[NSData dataWithBytes:(uint8_t[]){0x0f,0x01} length:2] :10000 :YES CheckType:0];}];
    NSData *SendVindata = [VehcileVin dataUsingEncoding:NSASCIIStringEncoding];
    SendVindata = [SendVindata subdataWithRange:NSMakeRange(SendVindata.length - 7, 7)];
    [operationsOther addObject:^OperationResult *{return [self.ProtocolDispatcher WriteIdentifier:0x37FE :SendVindata :5000 :YES];}];
    [operationsOther addObject:^OperationResult *{return [self.ProtocolDispatcher changeDiagnosticSession:0x01 :5000 :YES];}];         //Enter default session
    [operationsOther addObject:^OperationResult *{return [self.ProtocolDispatcher sendTesterPresent:1000];}];                             //send present
    [operationsOther addObject:^OperationResult *{return [self.ProtocolDispatcher ClearDiagnosticInfo];}];
    
    if (![self.OperationResult executeOperations:operationsOther delegate:self.delegate]) {
         return; // 如果操作失败，停止执行后续代码
     }
    
    [self.delegate processSuccess];
}

-(NSDictionary *)readPowerUnitDataDuringDrive:(BOOL)state{
    OperationResult *result = [self.ProtocolDispatcher ReadDMEDriverDataFromVehicle:1000 :YES];
    if(result.state == YES)
    {
        if(state)
        {
            const uint8_t *Origalbytes = [result.receiveData bytes];
            uint8_t rawThrottleValueinteger = Origalbytes[1];
            uint8_t rawThrottleValuedecimal = Origalbytes[2];
            uint16_t rawturboValue  =  (Origalbytes[3] << 8) | Origalbytes[4];
            uint16_t rawRPMValue    =  (Origalbytes[5] << 8) | Origalbytes[6];
            uint8_t rawGearValue     = Origalbytes[7];
            uint16_t rawSpeedValue    = (Origalbytes[8] << 8) | Origalbytes[9];
            
            rawThrottleValueinteger = rawThrottleValueinteger*100/255;
            rawThrottleValuedecimal = rawThrottleValuedecimal*100/255;
            float ThrottleValue = ((float)rawThrottleValueinteger + ((float)rawThrottleValuedecimal / 100.0))*10;
            if(ThrottleValue > 99)
                ThrottleValue = 99;
            
            float TurboValue = 0;
            if(rawturboValue < 0x336E)
                TurboValue = 0;
            else
            {
                TurboValue = (rawturboValue - 0x336E)/13.1;
            }
            
            if(TurboValue < 0)
                TurboValue = 0;
            
            uint16_t RPMValue = rawRPMValue/2;
            uint16_t SpeedValue = rawSpeedValue/100;
            int sero = 2;
            return  @{ @"Throttle":@(ThrottleValue), @"turbo":@(TurboValue), @"Gear":@(rawGearValue), @"rpm":@(RPMValue), @"Speed":@(SpeedValue) ,@"sero":@(sero)};
        }
        else
        {
            const uint8_t *Origalbytes = [result.receiveData bytes];
            uint8_t rawThrottleValue = Origalbytes[1];
            uint16_t rawturboValue  =  (Origalbytes[2] << 8) | Origalbytes[3];
            uint16_t rawRPMValue    =  (Origalbytes[4] << 8) | Origalbytes[5];
            uint8_t rawGearValue     = Origalbytes[6];
            uint16_t rawSpeedValue    = Origalbytes[7];
            rawThrottleValue = (rawThrottleValue*100/255)*10;
            if(rawThrottleValue>100)
                rawThrottleValue = 100;
            
            
            float TurboValue = 0;
            if(rawturboValue < 0x3300)
                TurboValue = 0;
            else
            {
                TurboValue = (rawturboValue - 0x3300)/12.0;
            }
            
            if(TurboValue < 0)
                TurboValue = 0;
            
            uint16_t RPMValue = rawRPMValue/2;
            int sero = 1;
            return  @{ @"Throttle":@(rawThrottleValue), @"turbo":@(TurboValue), @"Gear":@(rawGearValue), @"rpm":@(RPMValue), @"Speed":@(rawSpeedValue) ,@"sero":@(sero)};
        }
    }

    return  nil;
}


-(NSUInteger)GetAllStepCount:(NSArray *)array{
    NSUInteger count = 0;
    for(FlashBlockInfo *codeInfo in array){
        
        NSUInteger GetBlockLgenth = codeInfo.BlockData.length;
        long numberOfPackets = GetBlockLgenth/2999;
        long lastPacketSize = GetBlockLgenth%2999;
        count+= numberOfPackets;
        if(lastPacketSize!=0)
            count++;
    }
    return count;
}


-(NSArray *)GetFlashData:(NSData *)SendData{
    NSMutableArray *CodeArray = [NSMutableArray array];
    
    long numberOfPackets =SendData.length/2999;
    long lastPacketSize = SendData.length%2999;
    for(int i = 0;i<numberOfPackets;i++)
    {
        FlashInfo *infor = [[FlashInfo alloc] init];
        infor.index = i + 1;
        infor.data = [SendData subdataWithRange:NSMakeRange(0 + i*2999, 2999)];
    
        [CodeArray addObject:infor];
    }
    
    if(lastPacketSize>0)
    {
        FlashInfo *infor = [[FlashInfo alloc] init];
        infor.index = numberOfPackets + 1;
        infor.data = [SendData subdataWithRange:NSMakeRange(numberOfPackets*2999, lastPacketSize)];
        [CodeArray addObject:infor];
    }
    return CodeArray;
}



@end
