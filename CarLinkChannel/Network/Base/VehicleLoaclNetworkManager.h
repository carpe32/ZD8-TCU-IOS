//
//  VehicleLoaclNetworkManager.h
//  CarLinkChannel
//
//  Created by 刘润泽 on 2024/9/23.
//

#import <Foundation/Foundation.h>
#import "NetworkTool.h"
#import "UdpBase.h"
#import "TcpBase.h"
#import "UDSPackageHandle.h"
#import "UDSResponse.h"

NS_ASSUME_NONNULL_BEGIN

@interface VehicleLoaclNetworkManager : NSObject

-(NSString *)ReadVehicleVin;
-(NSData *)ReadVehicleSvt;
-(NSData *)ReadVehicleSN;

-(UDSResponse *)UDS_ReadByIndentifier:(uint8_t)EcuAddr :(NSData *)Sid :(NSData *)ControlData :(uint64_t)timeOut;
-(UDSResponse *)UDS_DiagnosticControl:(uint8_t)EcuAddr Sid:(uint8_t)SID :(uint64_t)timeOut;
-(UDSResponse *)UDS_ResetEcu:(uint8_t)EcuAddr :(uint8_t)ResetType :(uint64_t)timeOut;
-(NSData *)ReadDataByIdentifier:(uint8_t)Sid index:(uint8_t)index TimeOut:(uint64_t)timeOut;
-(UDSResponse *)UDS_RoutinContro:(uint8_t)EcuAddr :(NSData *)Sid :(NSData *)ControlData :(uint64_t)timeOut;
-(UDSResponse *)UDS_ControlDTCSetting:(uint8_t)EcuAddr SetState:(BOOL)State :(uint64_t)timeOut;
-(UDSResponse *)UDS_CommunicationControl:(uint8_t)EcuAddr :(NSData*)Sid SetState:(NSData *)State :(uint64_t)timeOut;
-(UDSResponse *)UDS_SecurityRequest:(uint8_t)EcuAddr :(NSData *)Sid :(NSData *)SendData :(uint64_t)timeOut;
-(UDSResponse *)UDS_RequestDownload:(uint8_t)EcuAddr FormatId:(uint8_t)Sid Data:(NSData *)SendData :(uint64_t)timeOut;
-(UDSResponse *)UDS_TransferDataToEcu:(uint8_t)EcuAddr Index:(NSData *)index Data:(NSData *)data :(uint64_t)timeOut;
-(void)UDS_TesterPresent:(uint8_t)EcuAddr :(uint64_t)timeOut;
-(UDSResponse *)UDS_RequestTransferExit:(uint8_t)EcuAddr :(uint64_t)timeOut;
-(UDSResponse *)WriteDataByIdentifierToEcu:(uint8_t)EcuAddr :(NSData *)Identifier :(NSData *)WriteData :(uint64_t)timeOut;
-(UDSResponse *)ClearDiagnosticInformation:(uint8_t)EcuAddr :(NSData *)Sid :(NSData *)ClearData;
-(UDSResponse *)BMWCustom1Process:(uint8_t)EcuAddr :(NSData *)Sid :(NSData *)Data;
-(UDSResponse *)SetVedioSate:(uint8_t)EcuAddr :(NSData *)Sid :(NSData *)SetData;
-(NSArray<UDSMultipleResponse *> *)readDiagnosesDataWithinTimeout:(NSData *)Sid :(NSData *)SendData :(uint64_t)TimeOut;
-(UDSResponse *)readOnlyDiagnosesData:(uint8_t)EcuAddr :(NSData *)Sid :(NSData *)SendData;

@end

typedef NS_ENUM(NSInteger, ServiceIdentifier) {
    ServiceIdentifierDiagnosticSessionControl = 0x10, // 诊断会话控制
    ServiceIdentifierECUReset = 0x11,                 // ECU复位
    ServiceIdentifierClearDiagnosticInformation = 0x14, // 清除故障码
    ServiceIdentifierReadDTCInformation = 0x19,       // 读取故障码
    ServiceIdentifierReadDataByIdentifier = 0x22,     // 读取数据标识符
    ServiceIdentifierReadMemoryByAddress = 0x23,      // 读取存储的数据
    ServiceIdentifierReadECUIdentification = 0x1A,    // 读取ECU标识符
    ServiceIdentifierSecurityAccess = 0x27,           // 安全访问
    ServiceIdentifierCommunicationControl = 0x28,     //通信控制（用于开关某个通信方式，比如禁用CAN）
    
    ServiceIdentifierWriteDataByIdentifier = 0x2E,    // 写入数据标识符
    ServiceIdentifierSetVehicleVedioState = 0x2C,
    
    ServiceIdentifierRoutineControl = 0x31,           // 远程激活例程
    ServiceIdentifierRequestDownload = 0x34,          // 请求下载
    ServiceIdentifierRequestUpload = 0x35,            // 请求上传
    ServiceIdentifierTransferData = 0x36,             // 传输数据
    ServiceIdentifierRequestTransferExit = 0x37,       // 传输退出
    ServiceIdentifierRequestTesterPresent = 0x3E,       //保持
    ServiceIdentifierDTCSettingControl = 0x85,          //诊断码控制
    ServiceIdentifierBMWCustom1 = 0xB1       //通过标识符读取数据
};
NS_ASSUME_NONNULL_END
