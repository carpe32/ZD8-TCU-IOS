//
//  TCUAPIConfig.h
//  ZD8-TCU
//
//  API配置文件
//

#ifndef TCUAPIConfig_h
#define TCUAPIConfig_h

#pragma mark - Server Configuration

/**
 * 服务器基础URL
 */
#define TCU_API_BASE_URL        @"https://zendao8.top"

#pragma mark - SSL Certificate Configuration

/**
 * 客户端证书文件名（不含.p12后缀）
 */
#define CLIENT_CERT_FILENAME    @"CLIENT-IOS-001"

/**
 * 客户端证书密码
 */
#define CLIENT_CERT_PASSWORD    @"Q1w2e3r4@#$"

#pragma mark - API Endpoints

/**
 * 车辆信息上传
 */
#define API_VEHICLE_INFO        @"/api/users/VehicleMsg/info"

/**
 * 硬件注册检查
 */
#define API_HARDWARE_CHECK      @"/api/hardware/check"

/**
 * 许可证验证
 */
#define API_LICENSE_VERIFY      @"/api/license/verify"

/**
 * 文件下载
 */
#define API_FILE_DOWNLOAD       @"/api/files/download"

/**
 * 健康检查
 */
#define API_HEALTH_CHECK        @"/health"

#pragma mark - Timeout Configuration

/**
 * 请求超时时间（秒）
 */
#define API_REQUEST_TIMEOUT     30.0

/**
 * 资源下载超时时间（秒）
 */
#define API_DOWNLOAD_TIMEOUT    300.0

#pragma mark - Helper Macros

/**
 * 构建完整的API URL
 * 用法: API_URL(API_VEHICLE_INFO)
 */
#define API_URL(endpoint) \
    [NSURL URLWithString:[TCU_API_BASE_URL stringByAppendingString:endpoint]]

#pragma mark - Debug Configuration

/**
 * 是否启用API日志
 */
#define API_LOG_ENABLED         1

/**
 * 是否打印请求体
 */
#define API_LOG_REQUEST_BODY    1

/**
 * 是否打印响应体
 */
#define API_LOG_RESPONSE_BODY   1

#endif /* TCUAPIConfig_h */
