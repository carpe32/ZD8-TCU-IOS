//
//  TCUAPIService.h
//  ZD8-TCU
//
//  iOS API服务 - 支持SSL双向认证
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/// API日志宏
#define TCUAPILog(fmt, ...) NSLog(@"[TCU-API] " fmt, ##__VA_ARGS__)
#define TCUAPILogError(fmt, ...) NSLog(@"[TCU-API ERROR] " fmt, ##__VA_ARGS__)

/**
 * TCU API服务
 * 功能：
 * - 支持SSL双向认证（客户端证书 + 服务器证书）
 * - 提供GET/POST/PUT/DELETE方法
 * - 自动处理JSON序列化/反序列化
 * - 完整的错误处理和日志记录
 */
@interface TCUAPIService : NSObject

#pragma mark - Singleton

/**
 * 获取单例实例
 */
+ (instancetype)sharedService;

#pragma mark - SSL Configuration

/**
 * 配置SSL客户端证书
 * @param certName 证书文件名（不含.p12后缀）
 * @param password 证书密码
 * @return YES表示配置成功，NO表示失败
 */
- (BOOL)setupSSLWithCertName:(NSString *)certName password:(NSString *)password;

/**
 * 检查SSL是否已配置
 * @return YES表示已配置客户端证书
 */
- (BOOL)isSSLConfigured;

#pragma mark - HTTP Methods

/**
 * GET请求
 * @param url 请求URL
 * @param parameters URL参数（可选）
 * @param completion 完成回调，responseObject为解析后的JSON对象
 */
- (void)GET:(NSURL *)url
 parameters:(nullable NSDictionary *)parameters
 completion:(void(^)(id _Nullable responseObject, NSError * _Nullable error))completion;

/**
 * POST请求
 * @param url 请求URL
 * @param parameters 请求体参数（会被序列化为JSON）
 * @param completion 完成回调
 */
- (void)POST:(NSURL *)url
  parameters:(nullable NSDictionary *)parameters
  completion:(void(^)(id _Nullable responseObject, NSError * _Nullable error))completion;

/**
 * PUT请求
 * @param url 请求URL
 * @param parameters 请求体参数（会被序列化为JSON）
 * @param completion 完成回调
 */
- (void)PUT:(NSURL *)url
 parameters:(nullable NSDictionary *)parameters
 completion:(void(^)(id _Nullable responseObject, NSError * _Nullable error))completion;

/**
 * DELETE请求
 * @param url 请求URL
 * @param completion 完成回调
 */
- (void)DELETE:(NSURL *)url
    completion:(void(^)(id _Nullable responseObject, NSError * _Nullable error))completion;

#pragma mark - Testing

/**
 * 测试服务器连接
 */
- (void)testConnection;

@end

NS_ASSUME_NONNULL_END
