//
//  TCUVehicleService.h
//  ZD8-TCU
//
//  车辆业务服务层
//  封装车辆相关的API调用
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * 车辆信息上传结果回调
 * @param success 是否成功
 * @param responseId 服务器返回的ID（如果有）
 * @param error 错误信息
 */
typedef void(^TCUVehicleUploadCompletion)(BOOL success, NSString * _Nullable responseId, NSError * _Nullable error);

/**
 * 车辆服务
 * 提供车辆信息相关的业务方法
 */
@interface TCUVehicleService : NSObject

#pragma mark - Singleton

/**
 * 获取单例实例
 */
+ (instancetype)sharedService;

#pragma mark - Vehicle Information Upload

/**
 * 上传车辆信息（完整参数）
 * @param vin 车辆识别号
 * @param svt SVT数据
 * @param cafd CAFD数据
 * @param completion 完成回调
 */
- (void)uploadVehicleInfoWithVIN:(NSString *)vin
                             svt:(NSString *)svt
                            cafd:(NSString *)cafd
                      completion:(TCUVehicleUploadCompletion)completion;

/**
 * 上传车辆信息（使用字典参数）
 * @param vehicleInfo 车辆信息字典，包含 vin, svt, cafd 等字段
 * @param completion 完成回调
 */
- (void)uploadVehicleInfo:(NSDictionary *)vehicleInfo
               completion:(TCUVehicleUploadCompletion)completion;

#pragma mark - Vehicle Data Query

/**
 * 查询车辆信息
 * @param vin 车辆识别号
 * @param completion 完成回调
 */
- (void)getVehicleInfoWithVIN:(NSString *)vin
                    completion:(void(^)(NSDictionary * _Nullable vehicleInfo, NSError * _Nullable error))completion;

/**
 * 获取车辆文件列表
 * @param vin 车辆识别号
 * @param fileType 文件类型（可选）
 * @param completion 完成回调
 */
- (void)getVehicleFilesWithVIN:(NSString *)vin
                      fileType:(NSString * _Nullable)fileType
                    completion:(void(^)(NSArray * _Nullable files, NSError * _Nullable error))completion;

@end

NS_ASSUME_NONNULL_END
