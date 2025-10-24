//
//  VehicleClass1.h
//  CarLinkChannel
//
//  Created by 刘润泽 on 2024/9/23.
//

#import <Foundation/Foundation.h>
#import "VehicleLoaclNetworkManager.h"
#import "NSData+Category.h"
#import "VehicleTypeProgramming.h"
#import "LicenseKeyManager.h"
#import "FlashBlockInfo.h"
#import "UDSProtocolDispatcher.h"
#import "UDSOperationResult.h"
NS_ASSUME_NONNULL_BEGIN

@interface VehicleClass1 : NSObject <VehicleTypeProgramming>
- (instancetype)initWithManager:(VehicleLoaclNetworkManager *)NetworkManager;
-(void)LoadFileToVehicle:(NSString *)FilePath :(NSString *)VehcileVin :(NSArray *)VehicleVersionInfo :(NSArray *)CafdInfo;
-(void)RecoveryCafdToVehicle:(NSString *)VehcileVin :(NSArray *)VehicleVersionInfo :(NSArray *)CafdInfo;
-(NSArray *)ReadCafd;
-(void)ClearFault;
@property (weak, nonatomic) id<FlashFeedbackDelegate> delegate;
@end
NS_ASSUME_NONNULL_END
