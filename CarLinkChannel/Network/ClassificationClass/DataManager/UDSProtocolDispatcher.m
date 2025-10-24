//
//  UDSProtocolDispatcher.m
//  TTS Tuning
//
//  Created by 刘润泽 on 2024/9/3.
//

#import "UDSProtocolDispatcher.h"

@interface UDSProtocolDispatcher(){
    uint8_t UseFid;
}
@property(nonatomic, strong) VehicleLoaclNetworkManager *networkManager;
@end

@implementation UDSProtocolDispatcher


// 实现带参数的初始化方法
- (instancetype)initWithFid:(uint8_t)Fid :(VehicleLoaclNetworkManager *)NetworkManager{
    self = [super init];
    if (self) {
        self.networkManager = NetworkManager;
        UseFid = Fid;
    }
    return self;
}

-(NSArray *)ReadCafd:(int)Count :(int)timeOut{
    NSMutableArray  *CafdArray = [NSMutableArray array];
    for(int i = 0;i<Count;i++)
    {
        NSData *RecData = [self.networkManager ReadDataByIdentifier:0x30 index:i TimeOut:timeOut];
        NSString * CafdString = [NSData hexStringFromHexData:RecData];
        [CafdArray addObject:CafdString];
    }
    return CafdArray;
}

-(OperationResult *)ReadTcuHealth:(int)type{
    OperationResult *result = [[OperationResult alloc] init];
    NSData *SendData;
    if(type == 0)
    {
        SendData =[NSData dataWithBytes:(uint8_t[]){0x3A} length:1];
    }
    else
        SendData =[NSData dataWithBytes:(uint8_t[]){0x40} length:1];
    
    UDSResponse *ResultData = [self.networkManager UDS_ReadByIndentifier:UseFid :[NSData dataWithBytes:(uint8_t[]){0x41} length:1] :SendData :5000];
        
    if(ResultData.status == UdsResponseStatusSuccess)
    {
        result.state = YES;
        result.receiveData = [ResultData.payload subdataWithRange:NSMakeRange(1, ResultData.payload.length - 1)];
    }
    else if(ResultData.status == UdsResponseStatusError)
    {
        result.state = NO;
        result.failureReason = OperationRequestError;
        result.receiveData = ResultData.payload;
    }
    else
    {
        result.state = NO;
        result.failureReason =  OperationTimeOut ;
    }
    return result;
}

-(OperationResult *)changeDiagnosticSession:(uint8_t)Type :(int)timeout :(BOOL)reciveState{
    UDSResponse *ResultData = [self.networkManager UDS_DiagnosticControl:UseFid Sid:Type :timeout];
    OperationResult *result = [[OperationResult alloc] init];
    result.operationName = OperationChangeSession;
    result.OperationFID = ResultData.OperationFID;
    if(ResultData.status == UdsResponseStatusSuccess)
    {
        result.state = YES;
    }
    else if(ResultData.status == UdsResponseStatusError)
    {
        if(reciveState)
            result.state = NO;
        else
            result.state = YES;
        
        result.failureReason = OperationRequestError;
        result.receiveData = ResultData.payload ;
    }
    else
    {
        result.state = NO;
        result.failureReason =  OperationTimeOut ;
    }
    return result;
}

-(OperationResult *)EnterDiagMode:(uint8_t)delay{
    [self.networkManager UDS_RoutinContro:0x40 :[NSData dataWithBytes:(uint8_t[]){0x01} length:1] :[NSData dataWithBytes:(uint8_t[]){0x10,0x01,0x0a,0x0a,0x43} length:5] :3000];
    OperationResult *result = [[OperationResult alloc] init];
    result.state = YES;
    sleep(delay);
    return result;
}

-(OperationResult *)RoutineControlRequest:(uint8_t)Sid :(NSData *)Senddata :(int)timeOut :(BOOL)reciveState CheckType:(uint8_t)type{
    NSData *sidData = [NSData dataWithBytes:&Sid length:1];
    UDSResponse *ResultData  = [self.networkManager UDS_RoutinContro:UseFid :sidData :Senddata :timeOut];
    OperationResult *result = [[OperationResult alloc] init];
    result.operationName = OperationSetRoutineControl;
    result.OperationFID = ResultData.OperationFID;
    if(ResultData.status == UdsResponseStatusSuccess)
    {
        result.state = YES;
    }
    else if(ResultData.status == UdsResponseStatusError)
    {
        if(reciveState)
            result.state = NO;
        else
            result.state = YES;
        
        result.failureReason = OperationRequestError;
        result.receiveData = ResultData.payload;
    }
    else
    {
        result.state = NO;
        result.failureReason =  OperationTimeOut ;
    }
    if(type == 1)
        result.CheckOperation = true;
    result.receiveData = ResultData.payload;
 
    return result;
}

-(OperationResult *)SetDTCState:(BOOL)state :(int)timeOut :(BOOL)ReciveState{
    UDSResponse *ResultData = [self.networkManager UDS_ControlDTCSetting:UseFid SetState:state :timeOut];
    OperationResult *result = [[OperationResult alloc] init];
    result.operationName = OperationSetDTCState;
    result.OperationFID = ResultData.OperationFID;
    if(ResultData.status == UdsResponseStatusSuccess)
    {
        result.state = YES;
    }
    else if(ResultData.status == UdsResponseStatusError)
    {
        if(ReciveState)
            result.state = NO;
        else
            result.state = YES;
        
        result.failureReason = OperationRequestError;
        result.receiveData = ResultData.payload ;
    }
    else
    {
        result.state = NO;
        result.failureReason =  OperationTimeOut ;
    }
    return result;
}

-(OperationResult *)SetNormalCommunicationState:(NSData *)State :(int)timeOut :(BOOL)ReciveState{
    UDSResponse *ResultData = [self.networkManager UDS_CommunicationControl:UseFid :[NSData dataWithBytes:(uint8_t[]){0x01} length:1] SetState:State :timeOut];
    OperationResult *result = [[OperationResult alloc] init];
    result.operationName = OperationSetCommunication;
    result.OperationFID = ResultData.OperationFID;
    if(ResultData.status == UdsResponseStatusSuccess)
    {
        result.state = YES;
    }
    else if(ResultData.status == UdsResponseStatusError)
    {
        if(ReciveState)
            result.state = NO;
        else
            result.state = YES;
        
        result.failureReason = OperationRequestError;
        result.receiveData = ResultData.payload ;
    }
    else
    {
        result.state = NO;
        result.failureReason =  OperationTimeOut ;
    }
    return result;
}

-(OperationResult *)applySecurityProtocol:(SecurityType)Type :(NSArray *)VehicleVerInfo :(int)timeOut{
    OperationResult *result = [[OperationResult alloc] init];
    result.operationName = OperationSecurityProcess;
    NSString *BtldInfo = @"";
    for(NSString *info in VehicleVerInfo)
    {
        NSRange Btldrange = [info rangeOfString:list_btld];
        if (Btldrange.location != NSNotFound) {
            BtldInfo = info;
        }
    }
    

    if(Type == Vehicle1SecurityType11)
    {
        return [self SecurityType11Process:BtldInfo :timeOut];
    }
    else
        return [self SecurityType01Process:BtldInfo :timeOut];
}

-(OperationResult *)WriteIdentifier:(uint16_t)Type :(NSData *)Senddata :(int)timeOut :(BOOL)ReciveState{
    uint8_t Ident[2] = {};
    Ident[0] = (uint8_t)(Type>>8)&0xFF;
    Ident[1] = (uint8_t)Type&0xFF;
    
    NSData *SendIdent = [NSData dataWithBytes:Ident length:sizeof(Ident)];
    UDSResponse *ResultData = [self.networkManager WriteDataByIdentifierToEcu:UseFid :SendIdent :Senddata :timeOut];
    OperationResult *result = [[OperationResult alloc] init];
    result.operationName = OperationWriteDataByIdentifier;
    result.OperationFID = ResultData.OperationFID;
    if(ResultData.status == UdsResponseStatusSuccess)
    {
        result.state = YES;
    }
    else if(ResultData.status == UdsResponseStatusError)
    {
        if(ReciveState)
            result.state = NO;
        else
            result.state = YES;
        
        result.failureReason = OperationRequestError;
        result.receiveData = ResultData.payload ;
    }
    else
    {
        result.state = NO;
        result.failureReason =  OperationTimeOut ;
    }
    return result;
}

//Write Programming Information
-(OperationResult *)RequestStartDownloadToFlash:(uint8_t)FormatID :(uint8_t)addrInfo :(uint32_t)FlashAddr :(uint32_t)DataLength :(int)timeOut :(BOOL)ReciveState{
    uint8_t SendData[9] = {};
    SendData[0] = addrInfo;
    SendData[1] = (uint8_t)((FlashAddr >> 24)&0xFF);
    SendData[2] = (uint8_t)((FlashAddr >> 16)&0xFF);
    SendData[3] = (uint8_t)((FlashAddr >> 8)&0xFF);
    SendData[4] = (uint8_t)(FlashAddr&0xFF);
    SendData[5] = (uint8_t)((DataLength >> 24)&0xFF);
    SendData[6] = (uint8_t)((DataLength >> 16)&0xFF);
    SendData[7] = (uint8_t)((DataLength >> 8)&0xFF);
    SendData[8] = (uint8_t)(DataLength&0xFF);
    
    NSData *SendToVehicle = [NSData dataWithBytes:SendData length:sizeof(SendData)];
    UDSResponse *ResultData = [self.networkManager UDS_RequestDownload:UseFid FormatId:FormatID Data:SendToVehicle :timeOut];
    OperationResult *result = [[OperationResult alloc] init];
    result.operationName = OperationTypeWriteProgrammingINFO;
    result.OperationFID = ResultData.OperationFID;
    if(ResultData.status == UdsResponseStatusSuccess)
    {
        result.state = YES;
    }
    else if(ResultData.status == UdsResponseStatusError)
    {
        if(ReciveState)
            result.state = NO;
        else
            result.state = YES;
        
        result.failureReason = OperationRequestError;
        result.receiveData = ResultData.payload ;
    }
    else
    {
        result.state = NO;
        result.failureReason =  OperationTimeOut ;
    }
    return result;
}

-(OperationResult *)SendFileDataToVehicle:(NSData *)index :(NSData *)Senddata :(int)timeOut :(BOOL)ReciveState{
    
    UDSResponse *ResultData = [self.networkManager UDS_TransferDataToEcu:UseFid Index:index Data:Senddata :timeOut];
    OperationResult *result = [[OperationResult alloc] init];
    result.operationName = OperationSendFileToEcu;
    result.OperationFID = ResultData.OperationFID;
    if(ResultData.status == UdsResponseStatusSuccess)
    {
        result.state = YES;
        uint8_t number;
        [index getBytes:&number length:1];
        result.OtherInfo = [NSString stringWithFormat:@"%d", number];
    }
    else if(ResultData.status == UdsResponseStatusError)
    {
        if(ReciveState)
            result.state = NO;
        else
            result.state = YES;
        
        result.failureReason = OperationRequestError;
        result.receiveData = ResultData.payload;
    }
    else
    {
        result.state = NO;
        result.failureReason =  OperationTimeOut ;
    }
    //result.state = YES;
    return result;
}

-(OperationResult *)sendTesterPresent:(int)timeOut{
    [self.networkManager UDS_TesterPresent:0xDF :timeOut];
    
    OperationResult *result = [[OperationResult alloc] init];
    result.state = YES;
    result.operationName = OperationHoldSession;
    return result;
}

-(OperationResult *)sendExitTrans :(int)timeOut :(BOOL)ReciveState{
    UDSResponse *ResultData = [self.networkManager UDS_RequestTransferExit:UseFid :timeOut];
    OperationResult *result = [[OperationResult alloc] init];
    result.operationName = OperationExitTransfer;
    result.state = YES;
    result.OperationFID = ResultData.OperationFID;
    if(ResultData.status == UdsResponseStatusSuccess)
    {
        result.state = YES;
    }
    else if(ResultData.status == UdsResponseStatusError)
    {
        if(ReciveState)
            result.state = NO;
        else
            result.state = YES;
        
        result.failureReason = OperationRequestError;
        result.receiveData = ResultData.payload;
    }
    else
    {
        result.state = NO;
        result.failureReason =  OperationTimeOut ;
    }
    return result;
}


-(OperationResult *)ResetEcu :(int)timeOut :(BOOL)ReciveState :(uint32_t)waitTime{
    UDSResponse *ResultData = [self.networkManager UDS_ResetEcu:UseFid :01 :timeOut];
    OperationResult *result = [[OperationResult alloc] init];
    result.operationName = OperationResetEcu;
    result.OperationFID = ResultData.OperationFID;
    if(ResultData.status == UdsResponseStatusSuccess)
    {
        result.state = YES;
    }
    else if(ResultData.status == UdsResponseStatusError)
    {
        if(ReciveState)
            result.state = NO;
        else
            result.state = YES;
        result.failureReason = OperationRequestError;
        result.receiveData = ResultData.payload ;
    }
    else
    {
        result.state = NO;
        result.failureReason =  OperationTimeOut ;
    }
    
    sleep(waitTime);
    return result;
}

-(OperationResult *)SendCafdToEcu:(NSArray *)CafdData :(int)timeOut :(BOOL)ReciveState{
    OperationResult *result = [[OperationResult alloc] init];
    result.operationName = OperationWriteCafd;
    result.state = YES;
    for(int i = 0; i< CafdData.count;i++)
    {
        
        OperationResult *IdentResult = [self WriteIdentifier:0x3000 + i :[self dataFromHexString:CafdData[i]] :timeOut :ReciveState];
        if(IdentResult.state == NO)
        {
            if([IdentResult.failureReason isEqual:OperationRequestError])
            {
                result.OtherInfo = [NSString stringWithFormat:@"Error : Write Cafd %d Error",i];
                result.receiveData = IdentResult.receiveData;
            }
            else
            {
                result.OtherInfo = [NSString stringWithFormat:@"TimeOut : Write Cafd %d",i];
            }
            break;
        }
    }
    return result;
}

-(OperationResult *)ReadEcuInfo:(NSData *)ReadType :(int)timeOut :(BOOL)ReciveState{
    UDSResponse *ResultData = [self.networkManager UDS_ReadByIndentifier:UseFid :[NSData dataWithBytes:(uint8_t[]){0xf1} length:1]:ReadType :timeOut ];
    OperationResult *result = [[OperationResult alloc] init];
    result.operationName = OperationReadEcuInfo;
    result.OperationFID = ResultData.OperationFID;
    if(ResultData.status == UdsResponseStatusSuccess)
    {
        result.state = YES;
    }
    else if(ResultData.status == UdsResponseStatusError)
    {
        if(ReciveState)
            result.state = NO;
        else
            result.state = YES;
        
        result.failureReason = OperationRequestError;
        result.receiveData = ResultData.payload ;
    }
    else
    {
        result.state = NO;
        result.failureReason =  OperationTimeOut ;
    }
    return result;
}

-(OperationResult *)ClearDiagnosticInfo{
    [self.networkManager ClearDiagnosticInformation:0xDF :[NSData dataWithBytes:(uint8_t[]){0xff} length:1] :[NSData dataWithBytes:(uint8_t[]){0xff,0xff} length:2]];
    usleep(5000000);
    [self.networkManager ClearDiagnosticInformation:0xDF :[NSData dataWithBytes:(uint8_t[]){0xff} length:1] :[NSData dataWithBytes:(uint8_t[]){0xff,0xff} length:2]];
    
    OperationResult *result = [[OperationResult alloc] init];
    result.state = YES;
    result.operationName = OperationClearDiagnosticInformation;
    return result;
}

-(OperationResult *)ReadDataByPeriodicIdentifier{
    
    UDSResponse *ResultData = [self.networkManager BMWCustom1Process:0xf0 :[NSData dataWithBytes:(uint8_t[]){0x01} length:1] :[NSData dataWithBytes:(uint8_t[]){0x0f,0x0b,0xdf,0x00,0x04,0xb1 ,0x01,0x0f,0x06} length:9]];
    OperationResult *result = [[OperationResult alloc] init];
    result.operationName = OperationBMWCustom1;
    result.OperationFID = ResultData.OperationFID;
    if(ResultData.status == UdsResponseStatusSuccess)
    {
        result.state = YES;
    }
    else if(ResultData.status == UdsResponseStatusError)
    {
        result.state = NO;
        result.failureReason = OperationRequestError;
        result.receiveData = ResultData.payload ;
    }
    else
    {
        result.state = NO;
        result.failureReason =  OperationTimeOut ;
    }
    
    result.state = YES;
    return result;
}

-(OperationResult *)SecurityType11Process:(NSString *)btldInfo :(int)timeOut
{
    OperationResult *result = [[OperationResult alloc] init];
    result.operationName = OperationSecurityProcess;
    OperationResult *Step1Result =  [self changeDiagnosticSession:0x02 :5000 :YES];

    if(Step1Result.state == YES)
    {
        usleep(200000);
        OperationResult *Step2Result = [self SendAndReciveSecurityAccess:Vehicle1SecurityType11 :[NSData dataWithBytes:(uint8_t[]){0xFF,0xFF,0xFF,0xFF} length:4] :timeOut];
        if(Step2Result.state == YES)
        {
            NSString *ChallengeData = [self convertDataToPercentEncodedString:Step2Result.receiveData];
            
            dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
            __block NSData *ResponseData = nil;
            
            LicenseKeyManager *LicenseManager = [[LicenseKeyManager alloc] init];
            NSLog(@"%@",btldInfo);
            [LicenseManager getanquansuanfabtld:btldInfo parmarsvar3:ChallengeData doneBlock:^(NSData * suanfa){
                ResponseData = suanfa;
                dispatch_semaphore_signal(semaphore); // 发送信号量，解除阻塞
            } withError:^(NSError * error){
                result.state = NO;
                result.OtherInfo = @"Encryption Network Error";
                dispatch_semaphore_signal(semaphore); // 发送信号量，解除阻塞
            }];
            
            dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
            
            if(ResponseData.length > 5)
            {
                OperationResult *Step3Result = [self SendAndReciveSecurityAccess:0x12 :ResponseData :timeOut];
                if(Step3Result.state == YES)
                {
                    result.state = YES;
                }
                else
                {
                    result.state = NO;
                    if([Step3Result.failureReason isEqual:OperationRequestError])
                    {
                        result.OtherInfo = @"request Response error";
                        result.receiveData = Step3Result.receiveData;
                    }
                    else
                    {
                        result.OtherInfo = @"request challenge Time out";
                    }
                }
            }
            else
                result.state = NO;
        }
        else
        {
            result.state = NO;
            if([Step2Result.failureReason isEqual: OperationRequestError])  //27 return 7f
            {
                result.OtherInfo = @"request challenge error";
                result.receiveData = Step2Result.receiveData;
            }
            else                                                            //27 time out
            {
                result.OtherInfo = @"request challenge Time out";
            }
        }
    }
    else
    {
        result.state = NO;
        if([Step1Result.failureReason isEqual: OperationRequestError])  //10 02 return 7f
        {
            result.OtherInfo = @"Change Session Error";
            result.receiveData = Step1Result.receiveData;
        }
        else                                                             //10 02 time out
        {
            result.OtherInfo = @"Change Session Time out";
        }
    }

    return result;
}

-(NSData *)ApplySecurityData:(NSString *) data BTLD:(NSString *)btld{
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
    __block NSData *ResponseData = nil;
    
    __block BOOL applystate = NO;
    LicenseKeyManager *LicenseManager = [[LicenseKeyManager alloc] init];
    [LicenseManager getanquansuanfabtld:btld parmarsvar3:data doneBlock:^(NSData * suanfa){
        ResponseData = suanfa;
        applystate = YES;
        dispatch_semaphore_signal(semaphore); // 发送信号量，解除阻塞
    } withError:^(NSError * error){
        applystate = NO;
        //result.OtherInfo = @"Encryption Network Error";
        dispatch_semaphore_signal(semaphore); // 发送信号量，解除阻塞
    }];
    
    dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
    if(applystate == NO)
        return nil;
    else
        return ResponseData;
}


-(OperationResult *)SecurityType01Process:(NSString *)btldInfo :(int)timeOut
{
    OperationResult *result = [[OperationResult alloc] init];
    result.operationName = OperationSecurityProcess;
    OperationResult *Step2Result = [self SendAndReciveSecurityAccess:Vehicle1SecurityType01 :[NSData dataWithBytes:(uint8_t[]){0xFF,0xFF,0xFF,0xFF} length:4] :timeOut];
        if(Step2Result.state == YES)
        {
            NSString *ChallengeData = [self convertDataToPercentEncodedString:Step2Result.receiveData];
            
            dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
            __block NSData *ResponseData = nil;
            
            LicenseKeyManager *LicenseManager = [[LicenseKeyManager alloc] init];
            [LicenseManager getanquansuanfabtld:btldInfo parmarsvar3:ChallengeData doneBlock:^(NSData * suanfa){
                ResponseData = suanfa;
                dispatch_semaphore_signal(semaphore); // 发送信号量，解除阻塞
            } withError:^(NSError * error){
                result.state = NO;
                result.OtherInfo = @"Encryption Network Error";
                dispatch_semaphore_signal(semaphore); // 发送信号量，解除阻塞
            }];
            
            dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
            if(ResponseData.length !=0)
            {
                OperationResult *Step3Result = [self SendAndReciveSecurityAccess:0x02 :ResponseData :timeOut];
                if(Step3Result.state == YES)
                {
                    result.state = YES;
                }
                else
                {
                    result.state = NO;
                    if([Step3Result.failureReason isEqual:OperationRequestError])
                    {
                        result.OtherInfo = @"request Response error";
                        result.receiveData = Step3Result.receiveData;
                    }
                    else
                    {
                        result.OtherInfo = @"request challenge Time out";
                    }
                }
            }
        }
        else
        {
            result.state = NO;
            if([Step2Result.failureReason isEqual: OperationRequestError])  //27 return 7f
            {
                result.OtherInfo = @"request challenge error";
                result.receiveData = Step2Result.receiveData;
            }
            else                                                            //27 time out
            {
                result.OtherInfo = @"request challenge Time out";
            }
        }
    
    return result;
}

-(OperationResult *)SendAndReciveSecurityAccess:(uint8_t)Sid :(NSData *)SendData :(int)timeOut{
    UDSResponse *ResultData = [self.networkManager UDS_SecurityRequest:UseFid :[NSData dataWithBytes:(uint8_t[]){Sid} length:1] :SendData :timeOut];
    OperationResult *result = [[OperationResult alloc] init];
    result.operationName = OperationSecurityStep1;
    result.OperationFID = ResultData.OperationFID;
    if(ResultData.status == UdsResponseStatusSuccess)
    {
        result.state = YES;
        result.receiveData = [ResultData.payload subdataWithRange:NSMakeRange(0, ResultData.payload.length)];
    }
    else if(ResultData.status == UdsResponseStatusError)
    {
        result.state = NO;
        result.failureReason = OperationRequestError;
        result.receiveData = ResultData.payload;
    }
    else
    {
        result.state = NO;
        result.failureReason =  OperationTimeOut ;
    }
    return result;
}

-(OperationResult *)ReadDMEDriverDataFromVehicle:(int)timeOut :(BOOL)ReciveState{
    UDSResponse *ResultData = [self.networkManager UDS_ReadByIndentifier:0x12 :[NSData dataWithBytes:(uint8_t[]){0xF3} length:1] :[NSData dataWithBytes:(uint8_t[]){0x00} length:1] :timeOut];
    OperationResult *result = [[OperationResult alloc] init];
    result.operationName = OperationSetCommunication;
    result.OperationFID = ResultData.OperationFID;
    if(ResultData.status == UdsResponseStatusSuccess)
    {
        result.state = YES;
        result.receiveData = ResultData.payload;
    }
    else if(ResultData.status == UdsResponseStatusError)
    {
        if(ReciveState)
            result.state = NO;
        else
            result.state = YES;
        
        result.failureReason = OperationRequestError;
        result.receiveData = ResultData.payload ;
    }
    else
    {
        result.state = NO;
        result.failureReason =  OperationTimeOut ;
    }
    return result;
}

- (NSString *)convertDataToPercentEncodedString:(NSData *)data {
    NSMutableString *hexString = [NSMutableString string];
    const unsigned char *dataBytes = [data bytes];
    NSUInteger dataLength = [data length];

    for (NSUInteger i = 0; i < dataLength; i++) {
        [hexString appendFormat:@"%02x", dataBytes[i]];
        if (i < dataLength - 1) {
            [hexString appendString:@","];
        }
    }
    NSString * chararray = @"abcdefABCDEF1234567890,";
    NSCharacterSet * charset = [[NSCharacterSet characterSetWithCharactersInString:chararray] invertedSet];
    
    return [hexString  stringByAddingPercentEncodingWithAllowedCharacters:charset];
}

- (NSData *)dataFromHexString:(NSString *)hexString {
    NSMutableData *data = [[NSMutableData alloc] initWithCapacity:[hexString length] / 2];
    
    for (int i = 0; i < [hexString length]; i += 2) {
        NSString *hexCharStr = [hexString substringWithRange:NSMakeRange(i, 2)];
        unsigned int hexByte;
        [[NSScanner scannerWithString:hexCharStr] scanHexInt:&hexByte];
        uint8_t byte = (uint8_t)hexByte;
        [data appendBytes:&byte length:1];
    }
    
    return data;
}

@end
