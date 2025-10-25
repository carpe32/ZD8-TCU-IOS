//
//  TCUVehicleService.m
//  ZD8-TCU
//
//  车辆业务服务层实现
//

#import "TCUVehicleService.h"
#import "TCUAPIService.h"
#import "TCUAPIConfig.h"

@implementation TCUVehicleService

#pragma mark - Singleton

+ (instancetype)sharedService {
    static TCUVehicleService *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[self alloc] init];
    });
    return sharedInstance;
}

#pragma mark - Vehicle Information Upload

- (void)uploadVehicleInfoWithVIN:(NSString *)vin
                             svt:(NSDictionary *)svtDict
                            cafd:(NSDictionary *)cafdDict
                      completion:(TCUVehicleUploadCompletion)completion {
    
    NSLog(@"[VehicleService] 📤 上传车辆信息");
    NSLog(@"  VIN: %@", vin);
    NSLog(@"  SVT Dictionary: %@", svtDict);
    NSLog(@"  CAFD Dictionary: %@", cafdDict);
    
    // 参数验证 - 与服务器端验证规则一致
    if (!vin || vin.length == 0) {
        NSLog(@"[VehicleService] ❌ VIN不能为空");
        NSError *error = [NSError errorWithDomain:@"TCUVehicleService"
                                             code:400
                                         userInfo:@{NSLocalizedDescriptionKey: @"VIN不能为空"}];
        if (completion) {
            completion(NO, nil, error);
        }
        return;
    }
    
    // VIN长度验证(通常BMW VIN为17位)
    if (vin.length != 17) {
        NSLog(@"[VehicleService] ⚠️ VIN长度异常: %lu", (unsigned long)vin.length);
    }
    
    // 构建请求参数 - svt和cafd是字典对象
    // 服务器端: public Dictionary<string, string> Svt { get; set; }
    // 服务器端: public Dictionary<string, string> Cafd { get; set; }
    NSMutableDictionary *params = [NSMutableDictionary dictionary];
    params[@"vin"] = vin;
    
    // 添加SVT字典（如果存在）
    if (svtDict && [svtDict isKindOfClass:[NSDictionary class]]) {
        params[@"svt"] = svtDict;
    } else {
        params[@"svt"] = @{}; // 空字典
    }
    
    // 添加CAFD字典（如果存在）
    if (cafdDict && [cafdDict isKindOfClass:[NSDictionary class]]) {
        params[@"cafd"] = cafdDict;
    } else {
        params[@"cafd"] = @{}; // 空字典
    }
    
    NSLog(@"[VehicleService] 📦 请求参数: %@", params);
    
    // 构建URL - 对应服务器端 [HttpPost("api/vehicle/info")]
    NSURL *url = API_URL(API_VEHICLE_INFO);
    
    NSLog(@"[VehicleService] 🌐 请求URL: %@", url);
    
    // 发送POST请求
    [[TCUAPIService sharedService] POST:url
                              parameters:params
                              completion:^(id responseObject, NSError *error) {
        
        if (error) {
            NSLog(@"[VehicleService] ❌ 上传失败: %@", error.localizedDescription);
            NSLog(@"[VehicleService] 错误详情: %@", error);
            
            if (completion) {
                completion(NO, nil, error);
            }
            return;
        }
        
        NSLog(@"[VehicleService] ✅ 请求成功");
        NSLog(@"[VehicleService] 📥 服务器响应: %@", responseObject);
        
        // 解析响应 - 服务器返回格式: { success: bool, message: string, id: string }
        if ([responseObject isKindOfClass:[NSDictionary class]]) {
            NSDictionary *response = (NSDictionary *)responseObject;
            
            // 获取响应字段
            BOOL success = [response[@"success"] boolValue];
            NSString *message = response[@"message"];
            NSString *responseId = response[@"id"]; // 车辆数据库ID
            
            NSLog(@"[VehicleService] Success: %@", success ? @"YES" : @"NO");
            NSLog(@"[VehicleService] Message: %@", message ?: @"(无消息)");
            NSLog(@"[VehicleService] ID: %@", responseId ?: @"(无ID)");
            
            if (completion) {
                if (success) {
                    // 成功时返回车辆ID
                    completion(YES, responseId, nil);
                } else {
                    // 服务器返回业务错误
                    NSError *apiError = [NSError errorWithDomain:@"TCUVehicleService"
                                                            code:500
                                                        userInfo:@{
                                                            NSLocalizedDescriptionKey: message ?: @"上传失败",
                                                            @"serverResponse": response
                                                        }];
                    completion(NO, nil, apiError);
                }
            }
        } else {
            // 响应格式不符合预期
            NSLog(@"[VehicleService] ⚠️ 响应格式异常: %@", [responseObject class]);
            
            if (completion) {
                NSError *formatError = [NSError errorWithDomain:@"TCUVehicleService"
                                                           code:501
                                                       userInfo:@{
                                                           NSLocalizedDescriptionKey: @"服务器响应格式错误",
                                                           @"response": responseObject ?: @"null"
                                                       }];
                completion(NO, nil, formatError);
            }
        }
    }];
}

- (void)uploadVehicleInfo:(NSDictionary *)vehicleInfo
               completion:(TCUVehicleUploadCompletion)completion {
    
    NSString *vin = vehicleInfo[@"vin"];
    NSString *svt = vehicleInfo[@"svt"];
    NSString *cafd = vehicleInfo[@"cafd"];
    
    [self uploadVehicleInfoWithVIN:vin
                               svt:svt
                              cafd:cafd
                        completion:completion];
}

#pragma mark - Vehicle Data Query

- (void)getVehicleInfoWithVIN:(NSString *)vin
                    completion:(void(^)(NSDictionary * _Nullable vehicleInfo, NSError * _Nullable error))completion {
    
    NSLog(@"[VehicleService] 📥 查询车辆信息: %@", vin);
    
    // 参数验证
    if (!vin || vin.length == 0) {
        NSLog(@"[VehicleService] ❌ VIN不能为空");
        NSError *error = [NSError errorWithDomain:@"TCUVehicleService"
                                             code:400
                                         userInfo:@{NSLocalizedDescriptionKey: @"VIN不能为空"}];
        if (completion) {
            completion(nil, error);
        }
        return;
    }
    
    // 构建URL
    NSString *endpoint = [NSString stringWithFormat:@"%@/%@", API_VEHICLE_INFO, vin];
    NSURL *url = [NSURL URLWithString:[TCU_API_BASE_URL stringByAppendingString:endpoint]];
    
    // 发送请求
    [[TCUAPIService sharedService] GET:url
                             parameters:nil
                             completion:^(id responseObject, NSError *error) {
        
        if (error) {
            NSLog(@"[VehicleService] ❌ 查询失败: %@", error.localizedDescription);
            
            if (completion) {
                completion(nil, error);
            }
            return;
        }
        
        NSLog(@"[VehicleService] ✅ 查询成功");
        
        if ([responseObject isKindOfClass:[NSDictionary class]]) {
            if (completion) {
                completion((NSDictionary *)responseObject, nil);
            }
        } else {
            NSError *parseError = [NSError errorWithDomain:@"TCUVehicleService"
                                                      code:500
                                                  userInfo:@{NSLocalizedDescriptionKey: @"响应格式错误"}];
            if (completion) {
                completion(nil, parseError);
            }
        }
    }];
}

- (void)getVehicleFilesWithVIN:(NSString *)vin
                      fileType:(NSString *)fileType
                    completion:(void(^)(NSArray * _Nullable files, NSError * _Nullable error))completion {
    
    NSLog(@"[VehicleService] 📥 查询车辆文件列表: %@", vin);
    
    // 参数验证
    if (!vin || vin.length == 0) {
        NSLog(@"[VehicleService] ❌ VIN不能为空");
        NSError *error = [NSError errorWithDomain:@"TCUVehicleService"
                                             code:400
                                         userInfo:@{NSLocalizedDescriptionKey: @"VIN不能为空"}];
        if (completion) {
            completion(nil, error);
        }
        return;
    }
    
    // 构建参数
    NSMutableDictionary *params = [NSMutableDictionary dictionaryWithObject:vin forKey:@"vin"];
    if (fileType) {
        params[@"type"] = fileType;
    }
    
    // 构建URL
    NSURL *url = [NSURL URLWithString:[TCU_API_BASE_URL stringByAppendingString:@"/api/files/list"]];
    
    // 发送请求
    [[TCUAPIService sharedService] GET:url
                             parameters:params
                             completion:^(id responseObject, NSError *error) {
        
        if (error) {
            NSLog(@"[VehicleService] ❌ 查询文件列表失败: %@", error.localizedDescription);
            
            if (completion) {
                completion(nil, error);
            }
            return;
        }
        
        NSLog(@"[VehicleService] ✅ 查询文件列表成功");
        
        if ([responseObject isKindOfClass:[NSDictionary class]]) {
            NSDictionary *response = (NSDictionary *)responseObject;
            NSArray *files = response[@"files"];
            
            if ([files isKindOfClass:[NSArray class]]) {
                if (completion) {
                    completion(files, nil);
                }
            } else {
                if (completion) {
                    completion(@[], nil);
                }
            }
        } else if ([responseObject isKindOfClass:[NSArray class]]) {
            if (completion) {
                completion((NSArray *)responseObject, nil);
            }
        } else {
            NSError *parseError = [NSError errorWithDomain:@"TCUVehicleService"
                                                      code:500
                                                  userInfo:@{NSLocalizedDescriptionKey: @"响应格式错误"}];
            if (completion) {
                completion(nil, parseError);
            }
        }
    }];
}

@end
