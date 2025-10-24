//
//  AutoNetworkService.h
//  CarLinkChannel
//
//  Created by 刘润泽 on 2024/9/23.
//

#import <Foundation/Foundation.h>
#import "VehicleLoaclNetworkManager.h"

#import "UploadManager.h"
#import "LuaInvoke.h"
#import "NSData+Category.h"
#import "VehicleClass1.h"
#import "VehicleClass2.h"
#import "VehicleClass3.h"
#import "VehicleClass4.h"
#import "VehicleClass5.h"
#import "VehicleClass6.h"

#import "VehicleTypeProgramming.h"
NS_ASSUME_NONNULL_BEGIN

@interface AutoNetworkService : NSObject
+(instancetype)sharedInstance;
-(NSString *)ReadVehicleVIN;
-(NSString *)ReadSaveVIN;
-(NSArray *)ReadVehicleSvt;
-(NSData *)ReadVehicleSN;
-(NSArray *)ReadCafd:(int)VehicleClass;
-(void)SetVehicleClass:(int)classType;
-(void)ClearFaultForVehicle;
-(NSDictionary *)ReadTCUHealthData;
-(BOOL)TestVedioSetState;
-(NSDictionary *)ReadVehcileAboutSpeedData:(BOOL)state;
-(void)SendEnterDiagnostic;
-(void)RemoveTransportMode;
-(void)SendDataForegslearnreset;
-(NSArray<UDSMultipleResponse *> *)ReadDiagnose;
-(NSData *)ReadOnlyDiagnose:(uint8_t)EcuId;

-(void)WakeUpGetway;

-(void)performCarECUFlash:(NSString *)Filepath :(NSString *)VIN :(NSArray *)VehicleVersionInfo delegate:(id<FlashFeedbackDelegate>)delegate;
-(void)performRecoveryCafd:(NSString *)VIN :(NSArray *)VehicleVersionInfo delegate:(id<FlashFeedbackDelegate>)delegate;
-(void)ServerRecoveryCafd:(NSString *)VIN :(NSArray *)VehicleVersionInfo :(NSArray *)Cafd delegate:(id<FlashFeedbackDelegate>)delegate;
@end

NS_ASSUME_NONNULL_END
