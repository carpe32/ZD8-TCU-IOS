//
//  TCUVehicleService.m
//  ZD8-TCU
//
//  车辆服务实现 - 方案3
//

#import "TCUVehicleService.h"
#import "TCUAPIService.h"
#import "TCUAPIConfig.h"
#import "TCUSSLManager.h"
#import "TCUStreamBasedRequest.h"

// ✅ 私有分类：访问 TCUAPIService 的内部属性
@interface TCUAPIService ()
@property (nonatomic, strong) TCUSSLManager *sslManager;
@end

// 日志宏
#define VehicleLog(fmt, ...) NSLog(@"[TCU-Vehicle] " fmt, ##__VA_ARGS__)
#define VehicleLogError(fmt, ...) NSLog(@"[TCU-Vehicle ERROR] " fmt, ##__VA_ARGS__)

@interface TCUVehicleService ()

@property (nonatomic, strong) TCUAPIService *apiService;

// 私有辅助方法
- (SecIdentityRef)getClientIdentity;
- (BOOL)validateSSLConfiguration;
- (NSError *)validateVIN:(NSString *)vin;
- (NSError *)validateHWID:(NSString *)hwid;
- (NSDictionary *)validateDictionary:(id)dict;

@end

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

- (instancetype)init {
    self = [super init];
    if (self) {
        _apiService = [TCUAPIService sharedService];
    }
    return self;
}

#pragma mark - Configuration

- (BOOL)setupSSLWithCertName:(NSString *)certName password:(NSString *)password {
    VehicleLog(@"========== 配置SSL证书 ==========");
    VehicleLog(@"证书名称: %@", certName);
    
    BOOL success = [self.apiService setupSSLWithCertName:certName password:password];
    
    if (success) {
        VehicleLog(@"✅ SSL基础配置成功");
        
        // ✅ 详细验证配置
        if (![self validateSSLConfiguration]) {
            VehicleLogError(@"❌ SSL配置验证失败");
            VehicleLog(@"====================================");
            return NO;
        }
        
        VehicleLog(@"✅ SSL配置验证通过");
        VehicleLog(@"====================================");
        
    } else {
        VehicleLogError(@"❌ SSL基础配置失败");
        VehicleLog(@"====================================");
    }
    
    return success;
}

- (BOOL)isSSLConfigured {
    return [self validateSSLConfiguration];
}

#pragma mark - Private Helper Methods

/**
 * 获取客户端身份（用于底层Stream请求）
 */
- (SecIdentityRef)getClientIdentity {
    if (!self.apiService) {
        VehicleLogError(@"❌ API Service 为 nil");
        return NULL;
    }
    
    TCUSSLManager *sslManager = self.apiService.sslManager;
    if (!sslManager) {
        VehicleLogError(@"❌ SSL Manager 为 nil");
        return NULL;
    }
    
    SecIdentityRef identity = sslManager.identity;
    if (!identity) {
        VehicleLogError(@"❌ Identity 为 nil");
        return NULL;
    }
    
    return identity;
}

/**
 * 验证SSL配置是否完整有效
 */
- (BOOL)validateSSLConfiguration {
    VehicleLog(@"🔍 验证SSL配置...");
    
    // 1. 检查 API Service
    if (!self.apiService) {
        VehicleLogError(@"  ❌ API Service 为 nil");
        return NO;
    }
    VehicleLog(@"  ✓ API Service: %p", self.apiService);
    
    // 2. 检查基本配置状态
    if (![self.apiService isSSLConfigured]) {
        VehicleLogError(@"  ❌ isSSLConfigured 返回 NO");
        return NO;
    }
    VehicleLog(@"  ✓ isSSLConfigured: YES");
    
    // 3. 检查 SSL Manager
    TCUSSLManager *sslManager = self.apiService.sslManager;
    if (!sslManager) {
        VehicleLogError(@"  ❌ SSL Manager 为 nil");
        return NO;
    }
    VehicleLog(@"  ✓ SSL Manager: %p", sslManager);
    
    // 4. 检查 Identity
    SecIdentityRef identity = sslManager.identity;
    if (!identity) {
        VehicleLogError(@"  ❌ Identity 为 nil");
        return NO;
    }
    VehicleLog(@"  ✓ Identity: %p", identity);
    
    // 5. 检查 Certificate
    SecCertificateRef certificate = sslManager.certificate;
    if (!certificate) {
        VehicleLogError(@"  ❌ Certificate 为 nil");
        return NO;
    }
    VehicleLog(@"  ✓ Certificate: %p", certificate);
    
    VehicleLog(@"✅ SSL配置完整且有效");
    return YES;
}

/**
 * 验证VIN格式
 */
- (NSError *)validateVIN:(NSString *)vin {
    if (!vin || vin.length == 0) {
        return [NSError errorWithDomain:@"TCUVehicleService"
                                  code:-100
                              userInfo:@{NSLocalizedDescriptionKey: @"VIN不能为空"}];
    }
    
    if (vin.length != 17) {
        return [NSError errorWithDomain:@"TCUVehicleService"
                                  code:-101
                              userInfo:@{NSLocalizedDescriptionKey:
                                        [NSString stringWithFormat:@"VIN必须为17位（当前%lu位）", (unsigned long)vin.length]}];
    }
    
    // 验证VIN格式（只包含大写字母和数字，不包含I、O、Q）
    NSCharacterSet *allowedChars = [NSCharacterSet characterSetWithCharactersInString:
                                   @"ABCDEFGHJKLMNPRSTUVWXYZ0123456789"];
    NSCharacterSet *vinChars = [NSCharacterSet characterSetWithCharactersInString:vin.uppercaseString];
    
    if (![allowedChars isSupersetOfSet:vinChars]) {
        return [NSError errorWithDomain:@"TCUVehicleService"
                                  code:-102
                              userInfo:@{NSLocalizedDescriptionKey: @"VIN格式不正确（不能包含I、O、Q）"}];
    }
    
    return nil;
}

/**
 * 验证HWID格式
 */
- (NSError *)validateHWID:(NSString *)hwid {
    if (!hwid || hwid.length == 0) {
        return [NSError errorWithDomain:@"TCUVehicleService"
                                  code:-110
                              userInfo:@{NSLocalizedDescriptionKey: @"HWID不能为空"}];
    }
    
    return nil;
}

/**
 * 验证并转换字典
 */
- (NSDictionary *)validateDictionary:(id)dict {
    // 如果已经是字典，直接返回
    if ([dict isKindOfClass:[NSDictionary class]]) {
        return (NSDictionary *)dict;
    }
    
    // 如果是字符串，尝试解析JSON
    if ([dict isKindOfClass:[NSString class]]) {
        NSString *jsonString = (NSString *)dict;
        NSData *jsonData = [jsonString dataUsingEncoding:NSUTF8StringEncoding];
        
        NSError *error = nil;
        id jsonObject = [NSJSONSerialization JSONObjectWithData:jsonData
                                                       options:0
                                                         error:&error];
        
        if (!error && [jsonObject isKindOfClass:[NSDictionary class]]) {
            VehicleLog(@"✓ JSON字符串解析成功");
            return (NSDictionary *)jsonObject;
        } else {
            VehicleLogError(@"⚠️ JSON解析失败: %@", error.localizedDescription);
        }
    }
    
    // 其他情况返回空字典
    VehicleLog(@"⚠️ 无法转换为字典，返回空字典");
    return @{};
}

#pragma mark - Vehicle Info Upload

- (void)uploadVehicleInfoWithVIN:(NSString *)vin
                         svtData:(NSDictionary *)svtData
                        cafdData:(NSDictionary *)cafdData
                      completion:(TCUVehicleUploadCompletion)completion {
    
    VehicleLog(@"========== 开始上传车辆信息 ==========");
    
    // 1. 验证SSL配置
    if (![self validateSSLConfiguration]) {
        VehicleLogError(@"❌ SSL配置验证失败");
        VehicleLogError(@"💡 请先调用: [service setupSSLWithCertName:password:]");
        
        NSError *error = [NSError errorWithDomain:@"TCUVehicleService"
                                            code:-1
                                        userInfo:@{NSLocalizedDescriptionKey: @"SSL配置不完整，请先配置SSL证书"}];
        if (completion) {
            dispatch_async(dispatch_get_main_queue(), ^{
                completion(NO, nil, error);
            });
        }
        return;
    }
    
    // 2. 验证VIN
    NSError *vinError = [self validateVIN:vin];
    if (vinError) {
        VehicleLogError(@"❌ VIN验证失败: %@", vinError.localizedDescription);
        if (completion) {
            dispatch_async(dispatch_get_main_queue(), ^{
                completion(NO, nil, vinError);
            });
        }
        return;
    }
    
    // 3. 设置HWID
    NSString *hwid = @"IOS_Device";
    
    // 4. 处理SVT和CAFD数据
    NSDictionary *finalSvtData = [self validateDictionary:svtData];
    NSDictionary *finalCafdData = cafdData ? [self validateDictionary:cafdData] : @{};
    
    if (!finalSvtData || finalSvtData.count == 0) {
        VehicleLogError(@"⚠️ 警告: SVT数据为空");
    }
    
    VehicleLog(@"📋 车辆信息:");
    VehicleLog(@"   VIN: %@", vin);
    VehicleLog(@"   HWID: %@", hwid);
    VehicleLog(@"   Platform: iOS (1)");
    VehicleLog(@"   SVT 数据条数: %lu", (unsigned long)finalSvtData.count);
    VehicleLog(@"   CAFD 数据条数: %lu", (unsigned long)finalCafdData.count);
    
    // 5. 构建请求参数
    NSDictionary *params = @{
        @"Vin": vin,
        @"Hwid": hwid,
        @"Platform": @(1),
        @"Svt": finalSvtData,
        @"Cafd": finalCafdData
    };
    
    VehicleLog(@"📦 请求参数: %@", params);
    
    // 6. 发送请求
    NSURL *url = API_URL(API_VEHICLE_INFO);
    VehicleLog(@"🚀 发送POST请求: %@", url.absoluteString);
    
    [self.apiService POST:url parameters:params completion:^(id response, NSError *error) {
        if (error) {
            VehicleLogError(@"❌ 上传失败");
            VehicleLogError(@"   错误: %@", error.localizedDescription);
            VehicleLogError(@"   错误码: %ld", (long)error.code);
            VehicleLogError(@"   错误域: %@", error.domain);
            VehicleLog(@"========================================");
            
            if (completion) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    completion(NO, nil, error);
                });
            }
            return;
        }
        
        // ========== 解析响应JSON ==========
        VehicleLog(@"✅ 上传成功");
        VehicleLog(@"📥 原始响应: %@", response);
        
        // 验证响应格式
        if (![response isKindOfClass:[NSDictionary class]]) {
            VehicleLogError(@"❌ 响应格式错误: 不是字典类型");
            VehicleLog(@"========================================");
            
            NSError *parseError = [NSError errorWithDomain:@"TCUVehicleService"
                                                      code:500
                                                  userInfo:@{NSLocalizedDescriptionKey: @"服务器响应格式错误"}];
            if (completion) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    completion(NO, nil, parseError);
                });
            }
            return;
        }
        
        NSDictionary *responseDict = (NSDictionary *)response;
        
        // 提取BinFileName
        // 服务器返回格式: { "success": true, "data": { "binFileName": "xxx", ... } }
        NSString *binFileName = nil;
        
        // 尝试从 data 字段提取
        id dataField = responseDict[@"data"];
        if (dataField && [dataField isKindOfClass:[NSDictionary class]]) {
            NSDictionary *dataDict = (NSDictionary *)dataField;
            
            // 尝试多种可能的字段名（兼容大小写）
            binFileName = dataDict[@"binFileName"] ?:
                         dataDict[@"BinFileName"] ?:
                         dataDict[@"binfilename"] ?:
                         dataDict[@"BINFILENAME"];
            
            VehicleLog(@"📄 从 data 字段提取:");
            VehicleLog(@"   BinFileName: %@", binFileName ?: @"(空)");
        }
        
        // 如果 data 中没有，尝试从根级别提取
        if (!binFileName) {
            binFileName = responseDict[@"binFileName"] ?:
                         responseDict[@"BinFileName"] ?:
                         responseDict[@"binfilename"];
            
            if (binFileName) {
                VehicleLog(@"📄 从根级别提取:");
                VehicleLog(@"   BinFileName: %@", binFileName);
            }
        }
        
        // 验证 binFileName 是否为字符串类型
        if (binFileName && ![binFileName isKindOfClass:[NSString class]]) {
            VehicleLogError(@"⚠️ BinFileName 类型错误，转换为字符串");
            binFileName = [NSString stringWithFormat:@"%@", binFileName];
        }
        
        // 最终结果
        if (!binFileName || binFileName.length == 0) {
            VehicleLog(@"⚠️ BinFileName 为空 - 车型可能不支持");
        } else {
            VehicleLog(@"✅ 成功提取 BinFileName: %@", binFileName);
        }
        
        VehicleLog(@"========================================");
        
        // 回调
        if (completion) {
            dispatch_async(dispatch_get_main_queue(), ^{
                completion(YES, binFileName, nil);
            });
        }
    }];
}

- (void)uploadVehicleInfo:(NSDictionary *)vehicleInfo
               completion:(TCUVehicleUploadCompletion)completion {
    
    VehicleLog(@"📦 便捷上传方法");
    
    // 1. 提取必需参数
    NSString *vin = vehicleInfo[@"vin"];
    id svtData = vehicleInfo[@"svt"];
    
    if (!vin) {
        VehicleLogError(@"❌ vehicleInfo 缺少 'vin' 字段");
        NSError *error = [NSError errorWithDomain:@"TCUVehicleService"
                                            code:-200
                                        userInfo:@{NSLocalizedDescriptionKey: @"缺少必需参数: vin"}];
        if (completion) {
            dispatch_async(dispatch_get_main_queue(), ^{
                completion(NO, nil, error);
            });
        }
        return;
    }
    
    if (!svtData) {
        VehicleLogError(@"❌ vehicleInfo 缺少 'svt' 字段");
        NSError *error = [NSError errorWithDomain:@"TCUVehicleService"
                                            code:-201
                                        userInfo:@{NSLocalizedDescriptionKey: @"缺少必需参数: svt"}];
        if (completion) {
            dispatch_async(dispatch_get_main_queue(), ^{
                completion(NO, nil, error);
            });
        }
        return;
    }
    
    // 2. 提取可选参数
    NSString *hwid = @"IOS_Device";
    
    NSNumber *platformNum = vehicleInfo[@"platform"];
    NSInteger platform = platformNum ? platformNum.integerValue : 1; // 默认iOS平台
    
    id cafdData = vehicleInfo[@"cafd"];
    
    // 3. 调用完整方法
    [self uploadVehicleInfoWithVIN:vin
                           svtData:[self validateDictionary:svtData]
                          cafdData:[self validateDictionary:cafdData]
                        completion:completion];
}

#pragma mark - File State

- (void)getFileStateWithVIN:(NSString *)vin
                    license:(NSString *)license
                 completion:(void(^)(NSString *binFileName, NSError *error))completion {
    
    NSLog(@"[VehicleService] 📄 获取文件状态");
    NSLog(@"  VIN: %@", vin);
    
    // 参数验证
    if (!vin || vin.length == 0) {
        NSError *error = [NSError errorWithDomain:@"TCUVehicleService"
                                             code:400
                                         userInfo:@{NSLocalizedDescriptionKey: @"VIN不能为空"}];
        if (completion) {
            completion(nil, error);
        }
        return;
    }
    
    if (!license || license.length == 0) {
        NSError *error = [NSError errorWithDomain:@"TCUVehicleService"
                                             code:400
                                         userInfo:@{NSLocalizedDescriptionKey: @"激活码不能为空"}];
        if (completion) {
            completion(nil, error);
        }
        return;
    }
    
    // 构建URL参数
    NSDictionary *params = @{
        @"Vin": vin,
        @"Hwid": @"IOS_Device",
        @"Platform": @(1),
        @"License": license
    };
    
    NSLog(@"[VehicleService] 📦 请求参数: %@", params);
    
    // 构建URL
    NSURL *url = API_URL(API_FILE_STATE);
    NSLog(@"[VehicleService] 🚀 发送GET请求: %@", url.absoluteString);
    
    // 发送请求
    [[TCUAPIService sharedService] GET:url parameters:params completion:^(id response, NSError *error) {
        
        if (error) {
            NSLog(@"[VehicleService] ❌ 获取文件状态失败: %@", error.localizedDescription);
            if (completion) {
                completion(nil, error);
            }
            return;
        }
        
        NSLog(@"[VehicleService] 📥 原始响应: %@", response);
        
        // 验证响应格式
        if (![response isKindOfClass:[NSDictionary class]]) {
            NSLog(@"[VehicleService] ❌ 响应格式错误");
            NSError *parseError = [NSError errorWithDomain:@"TCUVehicleService"
                                                      code:500
                                                  userInfo:@{NSLocalizedDescriptionKey: @"服务器响应格式错误"}];
            if (completion) {
                completion(nil, parseError);
            }
            return;
        }
        
        NSDictionary *responseDict = (NSDictionary *)response;
        
        // ✅ 修改：检查 status 字段而不是 success 字段
        NSString *status = responseDict[@"status"];
        BOOL isSuccess = [status isEqualToString:@"success"];
        
        // 也可以检查 code 字段
        NSInteger code = [responseDict[@"code"] integerValue];
        
        NSDictionary *dataDict = responseDict[@"data"];
        
        if (!isSuccess || code != 0 || !dataDict) {
            NSString *message = responseDict[@"message"] ?: @"获取文件状态失败";
            NSLog(@"[VehicleService] ❌ %@", message);
            NSError *apiError = [NSError errorWithDomain:@"TCUVehicleService"
                                                    code:code
                                                userInfo:@{NSLocalizedDescriptionKey: message}];
            if (completion) {
                completion(nil, apiError);
            }
            return;
        }
        
        // 获取 BinFileName
        NSString *binFileName = dataDict[@"binFileName"];
        
        if (!binFileName || binFileName.length == 0) {
            NSLog(@"[VehicleService] ⚠️ BinFileName 为空");
        } else {
            NSLog(@"[VehicleService] ✅ BinFileName: %@", binFileName);
        }
        
        if (completion) {
            completion(binFileName, nil);
        }
    }];
}

#pragma mark - File List

- (void)getFileListWithVIN:(NSString *)vin
                   license:(NSString *)license
                completion:(void(^)(NSArray<TCUFolderInfo *> *folders, NSError *error))completion {
    
    NSLog(@"[VehicleService] 📂 获取文件列表");
    NSLog(@"  VIN: %@", vin);
    NSLog(@"  License: %@", license);
    
    // 参数验证
    if (!vin || vin.length == 0) {
        NSError *error = [NSError errorWithDomain:@"TCUVehicleService"
                                             code:400
                                         userInfo:@{NSLocalizedDescriptionKey: @"VIN不能为空"}];
        if (completion) {
            completion(nil, error);
        }
        return;
    }
    
    if (!license || license.length == 0) {
        NSError *error = [NSError errorWithDomain:@"TCUVehicleService"
                                             code:400
                                         userInfo:@{NSLocalizedDescriptionKey: @"激活码不能为空"}];
        if (completion) {
            completion(nil, error);
        }
        return;
    }
    
    // 构建URL参数
    NSDictionary *params = @{
        @"Vin": vin,
        @"Hwid": @"IOS_Device",
        @"Platform": @(1),
        @"License": license
    };
    
    NSLog(@"[VehicleService] 📦 请求参数: %@", params);
    
    // 构建URL
    NSURL *url = API_URL(API_FILE_LIST);
    NSLog(@"[VehicleService] 🚀 发送GET请求: %@", url.absoluteString);
    
    // 发送请求
    [[TCUAPIService sharedService] GET:url parameters:params completion:^(id response, NSError *error) {
        
        if (error) {
            NSLog(@"[VehicleService] ❌ 获取文件列表失败: %@", error.localizedDescription);
            if (completion) {
                completion(nil, error);
            }
            return;
        }
        
        NSLog(@"[VehicleService] 📥 原始响应: %@", response);
        
        // 验证响应格式
        if (![response isKindOfClass:[NSDictionary class]]) {
            NSLog(@"[VehicleService] ❌ 响应格式错误");
            NSError *parseError = [NSError errorWithDomain:@"TCUVehicleService"
                                                      code:500
                                                  userInfo:@{NSLocalizedDescriptionKey: @"服务器响应格式错误"}];
            if (completion) {
                completion(nil, parseError);
            }
            return;
        }
        
        NSDictionary *responseDict = (NSDictionary *)response;
        
        // 解析响应
        // 服务器返回格式: { "success": true, "data": { "folders": [...], "totalCount": 3 } }
        NSDictionary *dataDict = responseDict[@"data"];
        if (!dataDict || ![dataDict isKindOfClass:[NSDictionary class]]) {
            NSLog(@"[VehicleService] ❌ data字段格式错误");
            NSError *parseError = [NSError errorWithDomain:@"TCUVehicleService"
                                                      code:500
                                                  userInfo:@{NSLocalizedDescriptionKey: @"响应数据格式错误"}];
            if (completion) {
                completion(nil, parseError);
            }
            return;
        }
        
        // 解析folders数组
        NSArray *foldersArray = dataDict[@"folders"];
        if (!foldersArray || ![foldersArray isKindOfClass:[NSArray class]]) {
            NSLog(@"[VehicleService] ⚠️ folders字段为空或格式错误");
            if (completion) {
                completion(@[], nil);
            }
            return;
        }
        
        // 转换为TCUFolderInfo对象
        NSMutableArray<TCUFolderInfo *> *folders = [NSMutableArray array];
        for (NSDictionary *folderDict in foldersArray) {
            if ([folderDict isKindOfClass:[NSDictionary class]]) {
                TCUFolderInfo *folder = [TCUFolderInfo folderWithDictionary:folderDict];
                [folders addObject:folder];
            }
        }
        
        NSLog(@"[VehicleService] ✅ 成功解析 %lu 个文件夹", (unsigned long)folders.count);
        for (TCUFolderInfo *folder in folders) {
            NSLog(@"  📁 %@ - %@", folder.folderName, folder.displayContent);
        }
        
        if (completion) {
            completion([folders copy], nil);
        }
    }];
}

#pragma mark - File Download

- (void)downloadFileWithVIN:(NSString *)vin
                       hwid:(NSString *)hwid
                    license:(NSString *)license
               selectedFile:(NSString *)selectedFile
              programSha256:(NSString *)programSha256
                 completion:(TCUFileDownloadCompletion)completion {
    
    NSLog(@"[VehicleService] 📥 下载文件");
    NSLog(@"  VIN: %@", vin);
    NSLog(@"  Selected: %@", selectedFile);
    
    // 构建URL参数
    NSDictionary *params = @{
        @"Vin": vin,
        @"Hwid": hwid,
        @"Platform": @(1),
        @"License": license,
        @"UserSelected": selectedFile,
        @"ProgramSha256": programSha256 ?: @""
    };
    
    NSLog(@"[VehicleService] 📦 请求参数: %@", params);
    
    // 构建URL
    NSURL *url = API_URL(API_FILE_DOWNLOAD);
    NSLog(@"[VehicleService] 🚀 发送GET请求: %@", url.absoluteString);
    
    // 发送请求（下载会返回二进制数据）
    [[TCUAPIService sharedService] GET:url parameters:params completion:^(id response, NSError *error) {
        
        if (error) {
            NSLog(@"[VehicleService] ❌ 下载失败: %@", error.localizedDescription);
            if (completion) {
                completion(NO, nil, error);
            }
            return;
        }
        
        // 响应应该是NSData
        if ([response isKindOfClass:[NSData class]]) {
            NSData *fileData = (NSData *)response;
            NSLog(@"[VehicleService] ✅ 下载成功: %lu bytes", (unsigned long)fileData.length);
            
            if (completion) {
                completion(YES, fileData, nil);
            }
        } else {
            NSLog(@"[VehicleService] ❌ 响应格式错误: %@", [response class]);
            NSError *parseError = [NSError errorWithDomain:@"TCUVehicleService"
                                                      code:500
                                                  userInfo:@{NSLocalizedDescriptionKey: @"响应不是文件数据"}];
            if (completion) {
                completion(NO, nil, parseError);
            }
        }
    }];
}

#pragma mark - License Management


- (void)checkLicenseValidityWithVIN:(NSString *)vin
                            license:(NSString *)license
                         completion:(void(^)(BOOL isValid, NSError *error))completion {
    
    NSLog(@"[VehicleService] 🔍 检查激活码");
    NSLog(@"  VIN: %@", vin);
    NSLog(@"  License: %@", license);
    
    // 参数验证
    if (!vin || vin.length == 0 || !license || license.length == 0) {
        NSError *error = [NSError errorWithDomain:@"TCUVehicleService"
                                             code:400
                                         userInfo:@{NSLocalizedDescriptionKey: @"VIN或激活码不能为空"}];
        if (completion) {
            completion(NO, error);
        }
        return;
    }
    
    // 构建URL - 使用宏定义
    NSURL *url = API_URL(API_LICENSE_CHECK);
    
    // 构建URL参数
    NSDictionary *params = @{
        @"vin": vin,
        @"Hwid": @"IOS_Device",
        @"Platform": @(1),
        @"license": license
    };
    
    NSLog(@"[VehicleService] 🌐 请求URL: %@", url);
    NSLog(@"[VehicleService] 📦 请求参数: %@", params);
    
    // 调用底层API服务的GET方法
    [[TCUAPIService sharedService] GET:url
                             parameters:params
                             completion:^(id responseObject, NSError *error) {
        
        if (error) {
            NSLog(@"[VehicleService] ❌ 激活码检查失败: %@", error.localizedDescription);
            if (completion) {
                completion(NO, error);
            }
            return;
        }
        
        NSLog(@"[VehicleService] 📥 服务器响应: %@", responseObject);
        
        // 解析响应
        // 服务器返回格式: { success: true, data: { isActivated: true/false, status: "...", message: "..." } }
        if (![responseObject isKindOfClass:[NSDictionary class]]) {
            NSError *parseError = [NSError errorWithDomain:@"TCUVehicleService"
                                                      code:500
                                                  userInfo:@{NSLocalizedDescriptionKey: @"响应格式错误"}];
            if (completion) {
                completion(NO, parseError);
            }
            return;
        }
        
        NSDictionary *responseDict = (NSDictionary *)responseObject;
        
        // 提取data字段
        NSDictionary *dataDict = responseDict[@"data"];
        if (!dataDict || ![dataDict isKindOfClass:[NSDictionary class]]) {
            NSError *parseError = [NSError errorWithDomain:@"TCUVehicleService"
                                                      code:500
                                                  userInfo:@{NSLocalizedDescriptionKey: @"响应数据格式错误"}];
            if (completion) {
                completion(NO, parseError);
            }
            return;
        }
        
        // 获取激活状态
        BOOL isActivated = [dataDict[@"isActivated"] boolValue];
        NSString *status = dataDict[@"status"];
        NSString *message = dataDict[@"message"];
        
        NSLog(@"[VehicleService] ✅ 激活码检查完成");
        NSLog(@"  状态: %@", status);
        NSLog(@"  消息: %@", message);
        NSLog(@"  结果: %@", isActivated ? @"合法" : @"不合法");
        
        if (completion) {
            completion(isActivated, nil);
        }
    }];
}

#pragma mark - License Registration

- (void)registerLicenseWithVIN:(NSString *)vin
                       license:(NSString *)license
                    completion:(void(^)(BOOL success, BOOL isNewActivation, NSString *message, NSError *error))completion {
    
    NSLog(@"[VehicleService] 📝 注册激活码");
    NSLog(@"  VIN: %@", vin);
    NSLog(@"  License: %@", license);
    
    // 参数验证
    if (!vin || vin.length == 0) {
        NSError *error = [NSError errorWithDomain:@"TCUVehicleService"
                                             code:400
                                         userInfo:@{NSLocalizedDescriptionKey: @"VIN不能为空"}];
        if (completion) {
            completion(NO, NO, @"VIN不能为空", error);
        }
        return;
    }
    
    if (!license || license.length == 0) {
        NSError *error = [NSError errorWithDomain:@"TCUVehicleService"
                                             code:400
                                         userInfo:@{NSLocalizedDescriptionKey: @"激活码不能为空"}];
        if (completion) {
            completion(NO, NO, @"激活码不能为空", error);
        }
        return;
    }
    
    // 构建请求参数
    // 服务器端期望的格式: { "Vin": "xxx", "Hwid": "xxx", "Platform": 1, "License": "xxx" }
    NSString *hwid = @"IOS_Device";
    
    NSDictionary *params = @{
        @"Vin": vin,
        @"Hwid": hwid,
        @"Platform": @(1),  // 1 = iOS
        @"License": license
    };
    
    NSLog(@"[VehicleService] 📦 请求参数: %@", params);
    
    // 构建URL
    NSURL *url = API_URL(API_LICENSE_REGISTER);
    NSLog(@"[VehicleService] 🚀 发送POST请求: %@", url.absoluteString);
    
    // 发送请求
    [[TCUAPIService sharedService] POST:url parameters:params completion:^(id response, NSError *error) {
        
        if (error) {
            NSLog(@"[VehicleService] ❌ 注册失败: %@", error.localizedDescription);
            if (completion) {
                completion(NO, NO, @"网络请求失败", error);
            }
            return;
        }
        
        NSLog(@"[VehicleService] 📥 原始响应: %@", response);
        
        // 验证响应格式
        if (![response isKindOfClass:[NSDictionary class]]) {
            NSLog(@"[VehicleService] ❌ 响应格式错误");
            NSError *parseError = [NSError errorWithDomain:@"TCUVehicleService"
                                                      code:500
                                                  userInfo:@{NSLocalizedDescriptionKey: @"服务器响应格式错误"}];
            if (completion) {
                completion(NO, NO, @"响应格式错误", parseError);
            }
            return;
        }
        
        NSDictionary *responseDict = (NSDictionary *)response;
        
        // 解析响应
        // 服务器返回格式: { "success": true, "data": { "success": true, "isNewActivation": true }, "message": "xxx" }
        BOOL apiSuccess = [responseDict[@"success"] boolValue];
        NSString *message = responseDict[@"message"] ?: @"";
        
        NSDictionary *dataDict = responseDict[@"data"];
        BOOL registerSuccess = NO;
        BOOL isNewActivation = NO;
        
        if (dataDict && [dataDict isKindOfClass:[NSDictionary class]]) {
            registerSuccess = [dataDict[@"success"] boolValue];
            isNewActivation = [dataDict[@"isNewActivation"] boolValue];
        }
        
        NSLog(@"[VehicleService] ✅ 注册完成");
        NSLog(@"  API成功: %@", apiSuccess ? @"是" : @"否");
        NSLog(@"  注册成功: %@", registerSuccess ? @"是" : @"否");
        NSLog(@"  首次激活: %@", isNewActivation ? @"是" : @"否");
        NSLog(@"  消息: %@", message);
        
        if (completion) {
            completion(registerSuccess, isNewActivation, message, nil);
        }
    }];
}

#pragma mark - Flash Management

- (void)startFlashWithVIN:(NSString *)vin
                     hwid:(NSString *)hwid
                  license:(NSString *)license
         selectedFileName:(NSString *)selectedFileName
               completion:(TCUServiceCompletion)completion {
    
    VehicleLog(@"⚡️ 开始刷写记录: %@", selectedFileName);
    
    NSDictionary *params = @{
        @"vin": vin,
        @"hwid": hwid,
        @"platform": @(1),
        @"license": license,
        @"selectedFileName": selectedFileName,
        @"startTime": [NSDate date]
    };
    
    NSURL *url = [NSURL URLWithString:@"https://zendao8.top/api/users/Flash/start"];
    
    [self.apiService POST:url parameters:params completion:^(id response, NSError *error) {
        if (error) {
            VehicleLogError(@"❌ 刷写记录启动失败: %@", error);
        } else {
            VehicleLog(@"✅ 刷写记录启动成功: %@", response);
        }
        
        if (completion) {
            dispatch_async(dispatch_get_main_queue(), ^{
                completion(error == nil, response, error);
            });
        }
    }];
}

- (void)endFlashWithVIN:(NSString *)vin
                   hwid:(NSString *)hwid
                license:(NSString *)license
               recordId:(NSInteger)recordId
              isSuccess:(BOOL)isSuccess
          failureReason:(NSString *)failureReason
             completion:(TCUServiceCompletion)completion {
    
    VehicleLog(@"⚡️ 结束刷写记录 #%ld (%@)",
              (long)recordId,
              isSuccess ? @"成功" : @"失败");
    
    NSMutableDictionary *params = [@{
        @"vin": vin,
        @"hwid": hwid,
        @"platform": @(1),
        @"license": license,
        @"recordId": @(recordId),
        @"isSuccess": @(isSuccess),
        @"endTime": [NSDate date]
    } mutableCopy];
    
    if (failureReason && !isSuccess) {
        params[@"failureReason"] = failureReason;
        VehicleLog(@"   失败原因: %@", failureReason);
    }
    
    NSURL *url = [NSURL URLWithString:@"https://zendao8.top/api/users/Flash/end"];
    
    [self.apiService POST:url parameters:params completion:^(id response, NSError *error) {
        if (error) {
            VehicleLogError(@"❌ 刷写记录结束失败: %@", error);
        } else {
            VehicleLog(@"✅ 刷写记录结束成功: %@", response);
        }
        
        if (completion) {
            dispatch_async(dispatch_get_main_queue(), ^{
                completion(error == nil, response, error);
            });
        }
    }];
}

#pragma mark - Testing

- (void)testConnection:(TCUServiceCompletion)completion {
    VehicleLog(@"========== 开始连接测试 ==========");
    
    // 检查SSL配置
    if (![self validateSSLConfiguration]) {
        VehicleLogError(@"❌ 测试失败：SSL未配置");
        VehicleLog(@"====================================");
        
        NSError *error = [NSError errorWithDomain:@"TCUVehicleService"
                                            code:-1
                                        userInfo:@{NSLocalizedDescriptionKey: @"SSL未配置"}];
        if (completion) {
            completion(NO, nil, error);
        }
        return;
    }
    
    // 使用测试数据
    NSDictionary *testData = @{
        @"vin": @"WBA8X9108LGM47279",
        @"hwid": @"TEST_HWID_iOS",
        @"platform": @(1),
        @"svt": @{
            @"TEST_KEY": @"TEST_VALUE",
            @"TIMESTAMP": @([[NSDate date] timeIntervalSince1970])
        },
        @"cafd": @{}
    };
    
    VehicleLog(@"🧪 发送测试请求...");
    
    [self uploadVehicleInfo:testData completion:^(BOOL success, id responseData, NSError *error) {
        if (success) {
            VehicleLog(@"========== 测试成功 ✅ ==========");
        } else {
            VehicleLog(@"========== 测试失败 ❌ ==========");
        }
        
        if (completion) {
            completion(success, responseData, error);
        }
    }];
}

@end
