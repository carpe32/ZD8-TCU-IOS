//
//  VehicleTypeProgramming.h
//  CarLinkChannel
//
//  Created by 刘润泽 on 2024/9/23.
//

#ifndef VehicleTypeProgramming_h
#define VehicleTypeProgramming_h

#import "FirmwareDataManager.h"
#import "FlashInfo.h"
#import "OperationResult.h"
@protocol FlashFeedbackDelegate <NSObject>
-(void)didUpdateProgress:(NSString *)StepName Info:(NSString *)info;
-(void)didEncounterError:(NSString *)StepName ErrorInfo:(NSString *)info ErrorData:(NSData *)errorData ErrorFID:(uint8_t)FID;
-(void)DidGetFlashAllCount:(NSInteger)Count;
-(void)processSuccess;
@end


@protocol VehicleTypeProgramming <NSObject>
- (NSArray *)ReadCafd;
-(void)ClearFault;
-(NSDictionary *)ReadHealth;
-(void)LoadFileToVehicle:(NSString *)FilePath :(NSString *)VehcileVin :(NSArray *)VehicleVersionInfo :(NSArray *)CafdInfo;
-(void)RecoveryCafdToVehicle:(NSString *)VehcileVin :(NSArray *)VehicleVersionInfo :(NSArray *)CafdInfo;
-(NSDictionary *)readPowerUnitDataDuringDrive:(BOOL)state;
@property (weak, nonatomic) id<FlashFeedbackDelegate> delegate;
@end


#define OperationTimeOut @"Time out"
#define OperationRequestError @"Request error"

#define OperationTypeWriteProgrammingINFO  @"Write Programming Information"
#define OperationSetDTCState  @"Set DTC State"
#define OperationSetRoutineControl @"Set Routine Control"
#define OperationResetEcu @"Reset ECU"
#define OperationChangeSession @"Change Session"
#define OperationWriteDataByIdentifier @"Write Data By Identifier"
#define OperationSetCommunication @"Set Communication model"
#define OperationSendFileToEcu @"Send File Data"
#define OperationHoldSession @"Hold Session"
#define OperationExitTransfer @"Exit Transfer"
#define OperationSecurityProcess @"Security Process"
#define OperationSecurityStep1 @"Security Step1"
#define OperationWriteCafd @"Write Cafd"
#define OperationClearDiagnosticInformation @"Clear Diagnostic Informatio"
#define OperationBMWCustom1 @"Custom1"
#define OperationReadEcuInfo  @"Read Ecu info"
#define OperationBasicDeficiency  @"Basic deficiency"
typedef NS_ENUM(NSInteger, SecurityType) {
    Vehicle1SecurityType11 = 0x11,
    Vehicle1SecurityType01 = 0x01
};
#endif /* VehicleTypeProgramming_h */
