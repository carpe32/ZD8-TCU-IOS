//
//  VehicleLoaclNetworkManager.m
//  CarLinkChannel
//
//  Created by 刘润泽 on 2024/9/23.
//

#import "VehicleLoaclNetworkManager.h"
static const DDLogLevel ddLogLevel = DDLogLevelVerbose;
@interface VehicleLoaclNetworkManager()<UdpBackDelegate,TcpHandleNotification>
{
    dispatch_source_t _Connect_Timer;
    NSString *localIp;
    NSString *VehicleIP;
}
@property (nonatomic,strong) UdpBase *udpManager;
@property (nonatomic,strong) TcpBase *TcpManager;
@property (nonatomic,strong) UDSPackageHandle* UdsHandle;
@end
@implementation VehicleLoaclNetworkManager


-(instancetype)init{
    self = [super init];
    if(self){
        if(_Connect_Timer){
            dispatch_source_cancel(_Connect_Timer);
            _Connect_Timer = nil;
        }
        //设置时间间隔
        NSTimeInterval period = 0.5f;
        dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
        _Connect_Timer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, queue);
        
        dispatch_source_set_timer(_Connect_Timer, dispatch_walltime(NULL, 0), period * NSEC_PER_SEC, 0);
        dispatch_source_set_event_handler(_Connect_Timer, ^{
            NSString *GetVehicleIp = [NetworkTool getEthNetworkIp];
            if(GetVehicleIp != nil){
                dispatch_source_cancel(self->_Connect_Timer);
                self->_Connect_Timer = nil;
                self.udpManager = [[UdpBase alloc] initWithIp:GetVehicleIp];
                self.udpManager.delegate = self;
                self->localIp = GetVehicleIp;
            }
        });
        // 开启定时器
        if (_Connect_Timer) {
            dispatch_resume(_Connect_Timer);
        }
    }
    return self;
}
//This method is used to Monitor Vehicle data
-(void)RecDataListen:(NSData*)data{
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [self.UdsHandle InputData:data];
    });
    [self SaveDataToLog:1 :data];
}
- (void)setupDataReceiveCallback {
    [self.UdsHandle registerDataReceivedCallback:^(UdsStructured *element) {
        // 在这里处理接收到的数据，例如将其入队
        UDSQueue *queue = [UDSQueue sharedInstance];
        [queue enqueue:element];
        // 你可以在这里触发其他事件或回调来处理接收到的数据
    }];
}

- (UDSResponse *)UdsSendAndRecVehicleData:(uint8_t)destAddr
                               Functionid:(uint8_t)functionID
                            SubFunctionId:(NSData *)subFunctionId
                                  parameterData:(NSData *)parameterData
                                        timeout:(uint64_t)timeoutMs {

    __block uint8_t SetFid = functionID;
    // 创建并发送数据包
    NSData *sendData = [UDSPackageHandle createUDSSendPacket:destAddr
                                                  Functionid:SetFid
                                               SubFunctionId:subFunctionId
                                               parameterData:parameterData];
    
//    if(SetFid != 0x36){
        NSMutableData *combinedData = [NSMutableData data];
        [combinedData appendBytes:&SetFid length:1];
        [combinedData appendData:subFunctionId];
        [combinedData appendData:parameterData];
        [self SaveDataToLog:0 :combinedData];
//    }
    
    [self.TcpManager SendData:sendData];
    
    // 创建信号量，用于等待响应
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
    __block UDSResponse *response = [[UDSResponse alloc] init];
    response.OperationFID = SetFid;
    __block BOOL timedOut = NO;
    __block uint64_t currentTimeoutMs = timeoutMs;

    // 创建 GCD 定时器
    dispatch_queue_t timerQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    dispatch_source_t timer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, timerQueue);
    
    // 设置定时器的开始时间和间隔
    dispatch_source_set_timer(timer, dispatch_time(DISPATCH_TIME_NOW, currentTimeoutMs * NSEC_PER_MSEC), DISPATCH_TIME_FOREVER, 0);
    
    // 设置定时器事件处理
    dispatch_source_set_event_handler(timer, ^{
        // 超时处理
        timedOut = YES;
        response.status = UdsResponseStatusTimeout;
        dispatch_semaphore_signal(semaphore);
        dispatch_source_cancel(timer);
    });
    
    // 启动定时器
    dispatch_resume(timer);

    // 注册接收回调
    [self.UdsHandle registerDataReceivedCallback:^(UdsStructured *element) {
        if (timedOut) return;  // 如果已经超时，直接返回

        // 检查数据包是否匹配
        if (element.sourceAddress == destAddr && element.functionID == (SetFid + 0x40)) {
            response.status = UdsResponseStatusSuccess;
            response.payload = element.payload;
            dispatch_semaphore_signal(semaphore);
            dispatch_source_cancel(timer);  // 成功后取消定时器
        } else if (element.functionID == 0x7F && element.subFunctionID == SetFid) {
            const unsigned char *bytes = [element.payload bytes];
            if (bytes[0] == 0x78) {
                @synchronized (self) {
                    dispatch_source_set_timer(timer, dispatch_time(DISPATCH_TIME_NOW, timeoutMs * NSEC_PER_MSEC), DISPATCH_TIME_FOREVER, 0);
                }
            } else {
                response.status = UdsResponseStatusError;
                response.payload = element.payload;
                dispatch_semaphore_signal(semaphore);
                dispatch_source_cancel(timer);  // 失败后取消定时器
            }
        }
    }];
    
    // 使用有限等待时间而不是DISPATCH_TIME_FOREVER
    while (dispatch_semaphore_wait(semaphore, dispatch_time(DISPATCH_TIME_NOW, 100 * NSEC_PER_MSEC)) != 0) {
        if (timedOut) {
            break;  // 如果定时器触发超时，退出等待
        }
    }
    
    return response;
}

- (NSArray<UDSMultipleResponse *> *)UdsSendAndRecVehicleDataFromAllTime:(uint8_t)destAddr
                               Functionid:(uint8_t)functionID
                            SubFunctionId:(NSData *)subFunctionId
                                  parameterData:(NSData *)parameterData
                                  timeout:(uint64_t)timeoutMs {
    
    NSData *sendData = [UDSPackageHandle createUDSSendPacket:destAddr
                                                  Functionid:functionID
                                               SubFunctionId:subFunctionId
                                               parameterData:parameterData];
    
    __block NSMutableArray<UDSMultipleResponse *> *receivedDataArray = [[NSMutableArray alloc] init];
    
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
    [self.UdsHandle registerDataReceivedCallback:^(UdsStructured *element) {
           // 将接收到的数据转换为 UDSMultipleResponse 对象
        UDSMultipleResponse *response = [[UDSMultipleResponse alloc] init];
        if(element.functionID == (functionID + 0x40))
        {
            response.ECUID = element.sourceAddress;
            response.Data = element.payload;
            // 确保线程安全地添加到数组中
            @synchronized (receivedDataArray) {
                [receivedDataArray addObject:response];
            }
        }
       }];
    [self.TcpManager SendData:sendData];

    // 在超时时间后释放信号量
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(timeoutMs * NSEC_PER_MSEC)), dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        dispatch_semaphore_signal(semaphore);
    });

    // 等待信号量，直到超时
    dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);

    return receivedDataArray;
}

-(void)SaveDataToLog:(BOOL)state :(NSData *)LogData{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{
        NSMutableString *dataString = [NSMutableString string];
        const uint8_t *bytes = (const uint8_t *)[LogData bytes];
        for (NSUInteger i = 0; i < LogData.length; i++) {
            [dataString appendFormat:@"%02X", bytes[i]];
            if (i < LogData.length - 1) {
                [dataString appendString:@" "]; // 添加空格
            }
        }
        
        if(state == 0)
            DDLogInfo(@"Send: %@",dataString);
        else
            DDLogInfo(@"Rec: %@",dataString);
    });
}

//This method is used to successfully obtain the vehicle ip
- (void)didReceiveVehicleIPInfo:(NSString *)VehicleIp :(NSString *)port{
    NSLog(@"VehicleIp: %@ port: %@",VehicleIp,port);
    self.udpManager = nil;
    self.TcpManager = [[TcpBase alloc] init];
    self.TcpManager.delegate = self;
    [self.TcpManager Connect:VehicleIp Port:port delegateQue:"com.example.socket.delegateQueue" socketQue:"com.example.socket.socketQueue"];
    self.UdsHandle = [[UDSPackageHandle alloc] init];
    self->VehicleIP = VehicleIp;
}
//This method is used to successfully Connect vehicle
-(void)ConnectSuccess{
    NSLog(@"Vehicle connect success");
    NSDictionary *NetworkMsg = @{@"Loacl":self->localIp ,@"Vehcile":self->VehicleIP};
    [[NSNotificationCenter defaultCenter] postNotificationName:Vehicle_Connect_Success object:nil userInfo:NetworkMsg];
}
//This method is used to Read Vehicle Vin
-(NSString *)ReadVehicleVin{
    uint8_t ReadVinbyte = 0x90;
    NSData *ReadVinData = [NSData dataWithBytes:&ReadVinbyte length:1];
    uint8_t Sid = 0xF1;
    NSData *SidData = [NSData dataWithBytes:&Sid length:1];
    
    UDSResponse *VehicleResponse = [self UdsSendAndRecVehicleData:0x18 Functionid:0x22 SubFunctionId:SidData parameterData:ReadVinData timeout:1000];
    
    if(VehicleResponse.status == UdsResponseStatusSuccess)
    {
        NSData *vinData = [VehicleResponse.payload subdataWithRange:NSMakeRange(1, VehicleResponse.payload.length - 1)];
        NSString *vin = [[NSString alloc] initWithData:vinData encoding:NSUTF8StringEncoding];
        return vin;
    }
    return nil;
}

//read Svt
-(NSData *)ReadVehicleSvt{
    uint8_t ReadVinbyte = 0x01;
    NSData *ReadVinData = [NSData dataWithBytes:&ReadVinbyte length:1];
    uint8_t Sid = 0xF1;
    NSData *SidData = [NSData dataWithBytes:&Sid length:1];
    UDSResponse *VehicleResponse = [self UdsSendAndRecVehicleData:0x18 Functionid:0x22 SubFunctionId:SidData parameterData:ReadVinData timeout:3000];
    
    if(VehicleResponse.status == UdsResponseStatusSuccess)
    {
        NSData *SvtData = [VehicleResponse.payload subdataWithRange:NSMakeRange(1, VehicleResponse.payload.length - 1)];
        return SvtData;
    }
    return nil;
}
//read SN
-(NSData *)ReadVehicleSN{
    uint8_t ReadVinbyte = 0x8C;
    NSData *ReadVinData = [NSData dataWithBytes:&ReadVinbyte length:1];
    uint8_t Sid = 0xF1;
    NSData *SidData = [NSData dataWithBytes:&Sid length:1];
    UDSResponse *VehicleResponse = [self UdsSendAndRecVehicleData:0x18 Functionid:0x22 SubFunctionId:SidData parameterData:ReadVinData timeout:3000];
    
    if(VehicleResponse.status == UdsResponseStatusSuccess)
    {
        return [VehicleResponse.payload subdataWithRange:NSMakeRange(1, VehicleResponse.payload.length - 1)];
    }
    return nil;
}

//22
-(NSData *)ReadDataByIdentifier:(uint8_t)Sid index:(uint8_t)index TimeOut:(uint64_t)timeOut{
    uint8_t ReadVinbyte = index;
    NSData *ReadVinData = [NSData dataWithBytes:&ReadVinbyte length:1];
    NSData *SidData = [NSData dataWithBytes:&Sid length:1];
    UDSResponse *VehicleResponse = [self UdsSendAndRecVehicleData:0x18 Functionid:0x22 SubFunctionId:SidData parameterData:ReadVinData timeout:timeOut];
    
    if(VehicleResponse.status == UdsResponseStatusSuccess)
    {
        NSData *RecData = [VehicleResponse.payload subdataWithRange:NSMakeRange(1, VehicleResponse.payload.length - 1)];
        return RecData;
    }
    return nil;
}
-(UDSResponse *)UDS_ReadByIndentifier:(uint8_t)EcuAddr :(NSData *)Sid :(NSData *)ControlData :(uint64_t)timeOut{
    return [self UdsSendAndRecVehicleData:EcuAddr Functionid:ServiceIdentifierReadDataByIdentifier SubFunctionId:Sid parameterData:ControlData timeout:timeOut];
}

//UDS -Routine Control(31)
-(UDSResponse *)UDS_RoutinContro:(uint8_t)EcuAddr :(NSData *)Sid :(NSData *)ControlData :(uint64_t)timeOut{
    return [self UdsSendAndRecVehicleData:EcuAddr Functionid:ServiceIdentifierRoutineControl SubFunctionId:Sid parameterData:ControlData timeout:timeOut];
}
//UDS - DIagnost control
-(UDSResponse *)UDS_DiagnosticControl:(uint8_t)EcuAddr Sid:(uint8_t)SID :(uint64_t)timeOut{
    NSData *SidData = [NSData dataWithBytes:&SID length:1];
    return [self UdsSendAndRecVehicleData:EcuAddr Functionid:ServiceIdentifierDiagnosticSessionControl SubFunctionId:SidData parameterData:nil timeout:timeOut];
}

//UDS - Control DTC(Diagnostic Toruble Code) Setting
-(UDSResponse *)UDS_ControlDTCSetting:(uint8_t)EcuAddr SetState:(BOOL)State :(uint64_t)timeOut{
    uint8_t StateData;
    if(State)
        StateData = 0x01;
    else
        StateData = 0x02;
    
    NSData *SidData = [NSData dataWithBytes:&StateData length:1];
    return [self UdsSendAndRecVehicleData:EcuAddr Functionid:ServiceIdentifierDTCSettingControl SubFunctionId:SidData parameterData:nil timeout:timeOut];
}
/*
 Sid:
    01: Normal Communication Message (eg: CAN)
    02: Network Management Message
    03: Both Normal and Network Management Messages
 state:
    00: all enable
    01: Tx disable Rx enable
    02: Tx enable  Rx disable
    03: All disable
 */
-(UDSResponse *)UDS_CommunicationControl:(uint8_t)EcuAddr :(NSData*)Sid SetState:(NSData *)State :(uint64_t)timeOut{
    return [self UdsSendAndRecVehicleData:EcuAddr Functionid:ServiceIdentifierCommunicationControl SubFunctionId:Sid parameterData:State timeout:timeOut];
}

-(UDSResponse *)UDS_SecurityRequest:(uint8_t)EcuAddr :(NSData *)Sid :(NSData *)SendData :(uint64_t)timeOut{
    return [self UdsSendAndRecVehicleData:EcuAddr Functionid:ServiceIdentifierSecurityAccess SubFunctionId:Sid parameterData:SendData timeout:timeOut];
}
//Request Download (34)
-(UDSResponse *)UDS_RequestDownload:(uint8_t)EcuAddr FormatId:(uint8_t)Sid Data:(NSData *)SendData :(uint64_t)timeOut{
    
    NSData *SidData = [NSData dataWithBytes:&Sid length:1];
    return [self UdsSendAndRecVehicleData:EcuAddr Functionid:ServiceIdentifierRequestDownload SubFunctionId:SidData parameterData:SendData timeout:timeOut];
}
-(UDSResponse *)UDS_TransferDataToEcu:(uint8_t)EcuAddr Index:(NSData *)index Data:(NSData *)data :(uint64_t)timeOut{
    return [self UdsSendAndRecVehicleData:EcuAddr Functionid:ServiceIdentifierTransferData SubFunctionId:index parameterData:data timeout:timeOut];
}
-(void)UDS_TesterPresent:(uint8_t)EcuAddr :(uint64_t)timeOut{
    uint8_t Sid = 0x80;
    NSData *SidData = [NSData dataWithBytes:&Sid length:1];
    [self UdsSendAndRecVehicleData:EcuAddr Functionid:ServiceIdentifierRequestTesterPresent SubFunctionId:SidData parameterData:nil timeout:timeOut];
}
-(UDSResponse *)UDS_RequestTransferExit:(uint8_t)EcuAddr :(uint64_t)timeOut{
    return [self UdsSendAndRecVehicleData:EcuAddr Functionid:ServiceIdentifierRequestTransferExit SubFunctionId:nil parameterData:nil timeout:timeOut];
}
-(UDSResponse *)UDS_ResetEcu:(uint8_t)EcuAddr :(uint8_t)ResetType :(uint64_t)timeOut{
    NSData *SidData = [NSData dataWithBytes:&ResetType length:1];
    return [self UdsSendAndRecVehicleData:EcuAddr Functionid:ServiceIdentifierECUReset SubFunctionId:SidData parameterData:nil timeout:timeOut];
}

-(UDSResponse *)WriteDataByIdentifierToEcu:(uint8_t)EcuAddr :(NSData *)Identifier :(NSData *)WriteData :(uint64_t)timeOut{
    const uint8_t *IdentBuffer = [Identifier bytes];
    uint8_t SidInt = IdentBuffer[0];
    NSData *SidData = [NSData dataWithBytes:&SidInt length:1];
    NSData *SendData;
    if(Identifier.length>1)
    {
        NSData *subData1 = [Identifier subdataWithRange:NSMakeRange(1, Identifier.length - 1)];
        NSMutableData *combinedData = [NSMutableData dataWithData:subData1];
        [combinedData appendData:WriteData];
        SendData = combinedData;
    }
    else
        SendData = WriteData;
    
    return [self UdsSendAndRecVehicleData:EcuAddr Functionid:ServiceIdentifierWriteDataByIdentifier SubFunctionId:SidData parameterData:SendData timeout:timeOut];
}

-(UDSResponse *)ClearDiagnosticInformation:(uint8_t)EcuAddr :(NSData *)Sid :(NSData *)ClearData{
    return [self UdsSendAndRecVehicleData:EcuAddr Functionid:ServiceIdentifierClearDiagnosticInformation SubFunctionId:Sid parameterData:ClearData timeout:500];
}

-(UDSResponse *)BMWCustom1Process:(uint8_t)EcuAddr :(NSData *)Sid :(NSData *)Data{
    return [self UdsSendAndRecVehicleData:EcuAddr Functionid:ServiceIdentifierBMWCustom1 SubFunctionId:Sid parameterData:Data timeout:3000];
}

-(UDSResponse *)SetVedioSate:(uint8_t)EcuAddr :(NSData *)Sid :(NSData *)SetData{
    return [self UdsSendAndRecVehicleData:EcuAddr Functionid:ServiceIdentifierSetVehicleVedioState SubFunctionId:Sid parameterData:SetData timeout:3000];
}

-(NSArray<UDSMultipleResponse *> *)readDiagnosesDataWithinTimeout:(NSData *)Sid :(NSData *)SendData :(uint64_t)TimeOut{
    return[self UdsSendAndRecVehicleDataFromAllTime:0xDF Functionid:ServiceIdentifierReadDTCInformation SubFunctionId:Sid parameterData:SendData timeout:TimeOut];
}

-(UDSResponse *)readOnlyDiagnosesData:(uint8_t)EcuAddr :(NSData *)Sid :(NSData *)SendData{
    return[self UdsSendAndRecVehicleData:EcuAddr Functionid:ServiceIdentifierReadDTCInformation SubFunctionId:Sid parameterData:SendData timeout:1000];
}

@end
