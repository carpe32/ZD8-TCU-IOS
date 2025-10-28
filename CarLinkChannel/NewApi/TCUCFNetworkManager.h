//
//  TCUCFNetworkManager.h
//  ZD8-TCU
//
//  使用CFNetwork底层API实现SSL双向认证
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface TCUCFNetworkManager : NSObject

+ (instancetype)sharedManager;

/**
 * 配置SSL证书
 */
- (BOOL)setupSSLWithCertName:(NSString *)certName password:(NSString *)password;

/**
 * POST请求（使用CFNetwork）
 */
- (void)POST:(NSString *)url
  parameters:(NSDictionary *)parameters
  completion:(void(^)(id _Nullable responseObject, NSError * _Nullable error))completion;

@end

NS_ASSUME_NONNULL_END
