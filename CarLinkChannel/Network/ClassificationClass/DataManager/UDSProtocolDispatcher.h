//
//  UDSProtocolDispatcher.h
//  TTS Tuning
//
//  Created by 刘润泽 on 2024/9/3.
//

#import <Foundation/Foundation.h>
#import "VehicleLoaclNetworkManager.h"
#import "OperationResult.h"
#import "VehicleTypeProgramming.h"
#import "LicenseKeyManager.h"

NS_ASSUME_NONNULL_BEGIN

@interface UDSProtocolDispatcher : NSObject
- (instancetype)initWithFid:(uint8_t)Fid :(VehicleLoaclNetworkManager *)NetworkManager;

-(NSArray *)ReadCafd:(int)Count :(int)timeOut;
-(OperationResult *)ReadTcuHealth:(int)type;
-(OperationResult *)changeDiagnosticSession:(uint8_t)Type  :(int)timeout :(BOOL)reciveState;
-(OperationResult *)RoutineControlRequest:(uint8_t)Sid :(NSData *)Senddata :(int)timeOut :(BOOL)reciveState CheckType:(uint8_t)type;
-(OperationResult *)SetDTCState:(BOOL)state :(int)timeOut :(BOOL)ReciveState;
-(OperationResult *)SetNormalCommunicationState:(NSData *)State :(int)timeOut :(BOOL)ReciveState;
-(OperationResult *)applySecurityProtocol:(SecurityType)Type :(NSArray *)VehicleVerInfo :(int)timeOut;
-(OperationResult *)WriteIdentifier:(uint16_t)Type :(NSData *)Senddata :(int)timeOut :(BOOL)ReciveState;
-(OperationResult *)RequestStartDownloadToFlash:(uint8_t)FormatID :(uint8_t)addrInfo :(uint32_t)FlashAddr :(uint32_t)DataLength :(int)timeOut :(BOOL)ReciveState;
-(OperationResult *)SendFileDataToVehicle:(NSData *)index :(NSData *)Senddata :(int)timeOut :(BOOL)ReciveState;
-(OperationResult *)sendTesterPresent:(int)timeOut;
-(OperationResult *)sendExitTrans :(int)timeOut :(BOOL)ReciveState;
-(OperationResult *)ResetEcu :(int)timeOut :(BOOL)ReciveState :(uint32_t)waitTime;
-(OperationResult *)SendCafdToEcu:(NSArray *)CafdData :(int)timeOut :(BOOL)ReciveState;
-(OperationResult *)ReadEcuInfo:(NSData *)ReadType :(int)timeOut :(BOOL)ReciveState;
-(OperationResult *)ClearDiagnosticInfo;
-(OperationResult *)ReadDataByPeriodicIdentifier;
-(OperationResult *)ReadDMEDriverDataFromVehicle:(int)timeOut :(BOOL)ReciveState;
-(OperationResult *)EnterDiagMode:(uint8_t)delay;
@end

NS_ASSUME_NONNULL_END
