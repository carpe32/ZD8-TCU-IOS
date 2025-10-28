//
//  TCUAPIResponse.h
//  ZD8-TCU API响应模型
//
//  Created on 2025/10/24.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * 统一API响应基类
 * 对应服务器端的 ApiResponse<T> 结构
 */
@interface TCUAPIResponse : NSObject

@property (nonatomic, assign) BOOL success;
@property (nonatomic, copy) NSString *message;
@property (nonatomic, strong, nullable) id data;
@property (nonatomic, assign) NSInteger errorCode;
@property (nonatomic, copy, nullable) NSString *timestamp;

/**
 * 从JSON字典创建响应对象
 */
+ (instancetype)responseWithDictionary:(NSDictionary *)dict;

/**
 * 是否是成功的响应
 */
- (BOOL)isSuccess;

@end

// ==================== 具体响应模型 ====================

/**
 * 文件夹信息
 */
@interface TCUFolderInfo : NSObject

@property (nonatomic, copy) NSString *folderName;      // 文件夹名称（如 "Stage 1"）
@property (nonatomic, copy) NSString *displayContent;  // 显示内容（从show.txt读取）

// ✅ 添加这个方法声明（之前缺少）
/**
 * 从字典创建文件夹信息
 */
+ (instancetype)folderWithDictionary:(NSDictionary *)dict;

@end

/**
 * 文件列表响应
 */
@interface TCUFileListResponse : TCUAPIResponse
@property (nonatomic, strong) NSArray<TCUFolderInfo *> *folders;
@property (nonatomic, assign) NSInteger totalCount;
@end

/**
 * 激活验证响应
 */
@interface TCULicenseValidateResponse : TCUAPIResponse
@property (nonatomic, assign) BOOL isActivated;
@property (nonatomic, copy, nullable) NSString *activatedAt;
@property (nonatomic, copy, nullable) NSString *expiresAt;
@property (nonatomic, assign) NSInteger remainingActivations;
@property (nonatomic, copy, nullable) NSString *boundHwid;
@end

NS_ASSUME_NONNULL_END
