//
//  KeyChainProcess.h
//  TTS Tuning
//
//  Created by 刘润泽 on 2024/8/14.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface KeyChainProcess : NSObject


+ (void)saveToKeychain:(NSDictionary *)data forKey:(NSString *)key;
+ (BOOL)deleteFromKeychainForKey:(NSString *)key;
+ (NSDictionary *)getFromKeychainForKey:(NSString *)key;
+ (BOOL)updateKeychainData:(NSDictionary *)data forKey:(NSString *)key;
+(void)deleteFormVehicle:(NSString *)key VIN:(NSString *)VehicleVin;
+(void)AddDataToKeychain:(NSDictionary *)dictionary forKey:(NSString *)key;
+(void)Updatechain:(NSDictionary *)dictionary forKey:(NSString *)key;
@end

NS_ASSUME_NONNULL_END
