//
//  KeyChainProcess.m
//  TTS Tuning
//
//  Created by 刘润泽 on 2024/8/14.
//

#import "KeyChainProcess.h"

@implementation KeyChainProcess
//save
+ (void)saveToKeychain:(NSDictionary *)dictionary forKey:(NSString *)key {
    NSError *error;
    NSData *data = [NSPropertyListSerialization dataWithPropertyList:dictionary format:NSPropertyListBinaryFormat_v1_0 options:0 error:&error];
    // 将数据存储到Keychain
    // 创建Keychain存储的查询字典
    NSMutableDictionary *keychainQuery = [NSMutableDictionary dictionary];
    keychainQuery[(__bridge id)kSecClass] = (__bridge id)kSecClassGenericPassword;
    keychainQuery[(__bridge id)kSecAttrService] = @"com.ZD8Lisence.appname";
    keychainQuery[(__bridge id)kSecAttrAccount] = key;
    keychainQuery[(__bridge id)kSecValueData] = data;

    // 存储数据
    OSStatus status = SecItemAdd((__bridge CFDictionaryRef)keychainQuery, NULL);
    if (status == errSecSuccess) {
        NSLog(@"Data stored successfully.");
    } else {
        NSLog(@"Failed to store data: %d", (int)status);
    }
}

+(void)AddDataToKeychain:(NSDictionary *)dictionary forKey:(NSString *)key {
    NSDictionary *OriginalDic = [self getFromKeychainForKey:key];
    NSMutableDictionary *mutableDict = [OriginalDic mutableCopy];
    
    if (!mutableDict) {
        mutableDict = [NSMutableDictionary dictionary];
    }
    
    [mutableDict addEntriesFromDictionary:dictionary];
    [self deleteFromKeychainForKey:key];
    [self saveToKeychain:mutableDict forKey:key];
}

+(void)deleteFormVehicle:(NSString *)key VIN:(NSString *)VehicleVin {
    NSDictionary *OriginalDic = [self getFromKeychainForKey:key];
    NSMutableDictionary *mutableDict = [OriginalDic mutableCopy];
    
    if (mutableDict) {
        [mutableDict removeObjectForKey:VehicleVin];
        
        if (mutableDict.count == 0) {
            [self deleteFromKeychainForKey:key];
        } else {
            [self saveToKeychain:mutableDict forKey:key];
        }
    }
}

+(void)Updatechain:(NSDictionary *)dictionary forKey:(NSString *)key{
    NSDictionary *OriginalDic = [self getFromKeychainForKey:key];
    NSMutableDictionary *mutableDict = nil;

    if (OriginalDic) {
        mutableDict = [OriginalDic mutableCopy];
    } else {
        NSLog(@"Keychain 返回空，初始化一个新字典");
        mutableDict = [NSMutableDictionary dictionary];
    }
    [mutableDict addEntriesFromDictionary:dictionary];
    [self deleteFromKeychainForKey:key];
    [self saveToKeychain:mutableDict forKey:key];
}

//del
+ (BOOL)deleteFromKeychainForKey:(NSString *)key {
    // 创建 Keychain 查询字典
    NSMutableDictionary *keychainQuery = [NSMutableDictionary dictionary];
    keychainQuery[(__bridge id)kSecClass] = (__bridge id)kSecClassGenericPassword;
    keychainQuery[(__bridge id)kSecAttrService] = @"com.ZD8Lisence.appname";
    keychainQuery[(__bridge id)kSecAttrAccount] = key;

    // 删除数据
    OSStatus status = SecItemDelete((__bridge CFDictionaryRef)keychainQuery);
    
    if (status == errSecSuccess) {
        NSLog(@"Data deleted successfully.");
        return YES;
    } else {
        NSLog(@"Failed to delete data: %d", (int)status);
        return NO;
    }
}
//update
+ (BOOL)updateKeychainData:(NSDictionary *)data forKey:(NSString *)key {
    if([self deleteFromKeychainForKey:key])
    {
        [self saveToKeychain:data forKey:key];
        return true;
    }
    else
        return false;
}

//check
+ (NSDictionary *)getFromKeychainForKey:(NSString *)key {
    // 创建 Keychain 查询字典
    NSMutableDictionary *keychainQuery = [NSMutableDictionary dictionary];
    keychainQuery[(__bridge id)kSecClass] = (__bridge id)kSecClassGenericPassword;
    keychainQuery[(__bridge id)kSecAttrService] = @"com.ZD8Lisence.appname";
    keychainQuery[(__bridge id)kSecAttrAccount] = key;
    keychainQuery[(__bridge id)kSecReturnData] = @YES;  // 需要返回数据
    keychainQuery[(__bridge id)kSecMatchLimit] = (__bridge id)kSecMatchLimitOne;  // 只匹配一个项

    // 检索数据
    CFTypeRef result = NULL;
    OSStatus status = SecItemCopyMatching((__bridge CFDictionaryRef)keychainQuery, &result);
    
    if (status == errSecSuccess) {
        NSData *retrievedData = (__bridge NSData *)result;
        if (!retrievedData) {
            NSLog(@"Keychain result is nil for key: %@", key);
            return nil;
        }
        NSError *error;
        // 将 NSData 反序列化为字典
        NSDictionary *retrievedDictionary = [NSPropertyListSerialization propertyListWithData:retrievedData options:0 format:NULL error:&error];

        if (!retrievedDictionary) {
            NSLog(@"Failed to deserialize data: %@", error);
            return nil;
        } else {
            return retrievedDictionary;
        }
    } else {
        NSLog(@"Failed to retrieve data: %d", (int)status);
        return nil;
    }
}


@end
