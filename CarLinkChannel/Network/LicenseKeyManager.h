//
//  HTTPManager.h
//  TTS Tuning
//
//  Created by 刘润泽 on 2024/8/13.
//

#import <Foundation/Foundation.h>
#import "Constents.h"
#import "HTTPManager.h"
#import "XmlProcess.h"

NS_ASSUME_NONNULL_BEGIN

@interface LicenseKeyManager : NSObject

-(void)checkVin:(NSString *)vin isValid:(void(^)(int result))resultBlock withError:(void(^)(NSError* error))errorBlock;
-(void)ValidWithVin:(NSString *)vin Code:(NSString *)code returnBlock:(void(^)(NSString *result))resultBlock withError:(void(^)(NSError* error))errorBlock;
-(int)checkVehicleActivationStatusWithVIN:(NSString *)Vin;
-(void)getListFileDoneBlock:(void(^)(NSString *liststring))resultBlock withError:(void(^)(NSError *error))errorBlock;
-(void)getanquansuanfabtld:(NSString *)btldValue parmarsvar3:(NSString *)var3 doneBlock:(void(^)(NSData *anquan))resultBlock withError:(void(^)(NSError *error))errorBlock;
-(BOOL)RegisterBinName:(NSString *)Vin FileName:(NSString *)BinName error:(NSError **)outError timeout:(NSTimeInterval)timeoutSeconds;
@end

NS_ASSUME_NONNULL_END
