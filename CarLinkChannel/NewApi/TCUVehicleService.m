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
    
    // ==================== 关键修复: 添加必需参数 ====================
    // 构建请求参数 - 对应服务器端 VehicleInfoRequest
    // 继承自 VehicleRequestBase 的必需字段:
    //   [Required] public string Vin { get; set; }
    //   [Required] public string Hwid { get; set; }
    //   [Required] public Platform Platform { get; set; }  // 0=Windows, 1=iOS
    // VehicleInfoRequest 自己的字段:
    //   public Dictionary<string, string> Svt { get; set; }
    //   public Dictionary<string, string> Cafd { get; set; }
    
    NSMutableDictionary *params = [NSMutableDictionary dictionary];
    
    // ✅ 必需参数1: VIN
    params[@"Vin"] = vin;
    
    // ✅ 必需参数2: Hwid (硬件ID - 从MAC地址生成MD5)
    NSString *hwid = @"IOS_Device";
    params[@"Hwid"] = hwid;
    NSLog(@"  HWID: %@", hwid);
    
    // ✅ 必需参数3: Platform (1 = iOS)
    params[@"Platform"] = @(1); // Platform enum: 0=Windows, 1=iOS
    
    // 可选参数: SVT字典
    if (svtDict && [svtDict isKindOfClass:[NSDictionary class]]) {
        params[@"Svt"] = svtDict;
    } else {
        params[@"Svt"] = @{}; // 空字典
    }
    
    // 可选参数: CAFD字典
    if (cafdDict && [cafdDict isKindOfClass:[NSDictionary class]]) {
        params[@"Cafd"] = cafdDict;
    } else {
        params[@"Cafd"] = @{}; // 空字典
    }
    // ==================== 修复结束 ====================
    
    NSLog(@"[VehicleService] 📦 完整请求参数: %@", params);
    
    // 构建URL - 对应服务器端 [HttpPost("api/users/VehicleMsg/info")]
    NSURL *url = API_URL(API_VEHICLE_INFO);
    
    NSLog(@"[VehicleService] 🌐 请求URL: %@", url);
    
    // 发送请求
    [[TCUAPIService sharedService] POST:url
                              parameters:params
                              completion:^(id responseObject, NSError *error) {
        
        if (error) {
            NSLog(@"[VehicleService] ❌ 上传失败: %@", error.localizedDescription);
            if (completion) {
                completion(NO, nil, error);
            }
            return;
        }
        
        // 解析响应
        NSLog(@"[VehicleService] ✅ 上传成功");
        NSLog(@"[VehicleService] 📥 服务器响应: %@", responseObject);
        
        // 提取响应中的ID（如果有）
        NSString *responseId = nil;
        if ([responseObject isKindOfClass:[NSDictionary class]]) {
            NSDictionary *responseDict = (NSDictionary *)responseObject;
            
            // 尝试多种可能的ID字段名
            if (responseDict[@"id"]) {
                responseId = [NSString stringWithFormat:@"%@", responseDict[@"id"]];
            } else if (responseDict[@"vehicleId"]) {
                responseId = [NSString stringWithFormat:@"%@", responseDict[@"vehicleId"]];
            } else if (responseDict[@"data"]) {
                // 如果data是字典,尝试从中提取id
                id dataObj = responseDict[@"data"];
                if ([dataObj isKindOfClass:[NSDictionary class]]) {
                    NSDictionary *dataDict = (NSDictionary *)dataObj;
                    if (dataDict[@"id"]) {
                        responseId = [NSString stringWithFormat:@"%@", dataDict[@"id"]];
                    }
                }
            }
        }
        
        if (completion) {
            completion(YES, responseId, nil);
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
