//
//  TCUVehicleService.h
//  ZD8-TCU
//
//  车辆服务 - 封装所有与车辆相关的API调用
//  使用方案3：通过私有方法访问SSL配置
//

#import <Foundation/Foundation.h>
#import "TCUAPIResponse.h"
NS_ASSUME_NONNULL_BEGIN

/**
 * 文件下载完成回调
 * @param success 是否成功
 * @param fileData 文件数据
 * @param error 错误信息
 */
typedef void(^TCUFileDownloadCompletion)(BOOL success, NSData * _Nullable fileData, NSError * _Nullable error);

/**
 * 通用完成回调
 */
typedef void(^TCUServiceCompletion)(BOOL success, id _Nullable data, NSError * _Nullable error);

/**
 * 车辆信息上传结果回调
 * @param success 是否成功
 * @param binFileName 服务器返回的BinFileName（可能为空）
 * @param error 错误信息
 */
typedef void(^TCUVehicleUploadCompletion)(BOOL success, NSString * _Nullable binFileName, NSError * _Nullable error);
#pragma mark - TCUVehicleService

/**
 * 车辆服务
 * 统一管理所有车辆相关的API调用
 */
@interface TCUVehicleService : NSObject

#pragma mark - Singleton

/**
 * 获取单例
 */
+ (instancetype)sharedService;

#pragma mark - Configuration

/**
 * 配置SSL证书（必须在使用API前调用）
 * @param certName 证书文件名（不含.p12后缀）
 * @param password 证书密码
 * @return 是否配置成功
 */
- (BOOL)setupSSLWithCertName:(NSString *)certName password:(NSString *)password;

/**
 * 检查SSL是否已配置
 */
- (BOOL)isSSLConfigured;

#pragma mark - Vehicle Info Upload

/**
 * 上传车辆信息
 * @param vin 车架号（17位）

 * @param svtData SVT数据字典
 * @param cafdData CAFD数据字典（可选）
 * @param completion 完成回调
 */
- (void)uploadVehicleInfoWithVIN:(NSString *)vin
                         svtData:(NSDictionary *)svtData
                        cafdData:(nullable NSDictionary *)cafdData
                      completion:(TCUVehicleUploadCompletion)completion;

/**
 * 上传车辆信息（便捷方法）
 * @param vehicleInfo 车辆信息字典，必须包含: vin, svt; 可选: cafd, hwid, platform
 * @param completion 完成回调
 */
- (void)uploadVehicleInfo:(NSDictionary *)vehicleInfo
               completion:(TCUVehicleUploadCompletion)completion;


/**
 * 获取文件状态
 * @param vin 车架号
 * @param license 激活码
 * @param completion 回调 (binFileName: 文件名, error: 错误)
 */
- (void)getFileStateWithVIN:(NSString *)vin
                    license:(NSString *)license
                 completion:(void(^)(NSString *binFileName, NSError *error))completion;

#pragma mark - File Management

/**
 * 获取车辆文件列表
 * @param vin VIN码
 * @param license 激活码
 * @param completion 回调 (folders: 文件夹列表, error: 错误)
 */
- (void)getFileListWithVIN:(NSString *)vin
                   license:(NSString *)license
                completion:(void(^)(NSArray<TCUFolderInfo *> *folders, NSError *error))completion;

/**
 * 下载文件
 * @param vin 车架号
 * @param hwid 硬件ID
 * @param license 激活码
 * @param selectedFile 选择的文件名
 * @param programSha256 程序SHA256
 * @param completion 完成回调
 */
- (void)downloadFileWithVIN:(NSString *)vin
                       hwid:(NSString *)hwid
                    license:(NSString *)license
               selectedFile:(NSString *)selectedFile
              programSha256:(NSString *)programSha256
                 completion:(TCUFileDownloadCompletion)completion;

#pragma mark - License Management

/**
 * 检查激活码状态
 * @param vin 车架号
 * @param license 激活码
 * @param completion 完成回调
 */
- (void)checkLicenseValidityWithVIN:(NSString *)vin
                            license:(NSString *)license
                         completion:(void(^)(BOOL isValid, NSError *error))completion;

/**
 * 注册激活码
 * @param vin VIN码
 * @param license 激活码
 * @param completion 回调 (success: 是否成功, isNewActivation: 是否首次激活, message: 消息, error: 错误)
 */
- (void)registerLicenseWithVIN:(NSString *)vin
                       license:(NSString *)license
                    completion:(void(^)(BOOL success, BOOL isNewActivation, NSString *message, NSError *error))completion;

#pragma mark - Flash Management

/**
 * 开始刷写记录
 * @param vin 车架号
 * @param hwid 硬件ID
 * @param license 激活码
 * @param selectedFileName 选择的文件名
 * @param completion 完成回调
 */
- (void)startFlashWithVIN:(NSString *)vin
                     hwid:(NSString *)hwid
                  license:(NSString *)license
         selectedFileName:(NSString *)selectedFileName
               completion:(TCUServiceCompletion)completion;

/**
 * 结束刷写记录
 * @param vin 车架号
 * @param hwid 硬件ID
 * @param license 激活码
 * @param recordId 刷写记录ID
 * @param isSuccess 是否成功
 * @param failureReason 失败原因（可选）
 * @param completion 完成回调
 */
- (void)endFlashWithVIN:(NSString *)vin
                   hwid:(NSString *)hwid
                license:(NSString *)license
               recordId:(NSInteger)recordId
              isSuccess:(BOOL)isSuccess
          failureReason:(nullable NSString *)failureReason
             completion:(TCUServiceCompletion)completion;

#pragma mark - Testing

/**
 * 测试连接
 * @param completion 完成回调
 */
- (void)testConnection:(TCUServiceCompletion)completion;

@end

NS_ASSUME_NONNULL_END
