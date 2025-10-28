//
//  TCUAlamofireManager.h
//  ZD8-TCU
//
//  Alamofire管理器 - 纯Objective-C版本
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface TCUAlamofireManager : NSObject

+ (instancetype)sharedManager;

/**
 * 配置SSL证书
 */
- (BOOL)setupSSLWithCertName:(NSString *)certName password:(NSString *)password;

/**
 * POST请求
 */
- (void)POST:(NSString *)url
  parameters:(NSDictionary *)parameters
  completion:(void(^)(id _Nullable responseObject, NSError * _Nullable error))completion;

/**
 * GET请求
 */
- (void)GET:(NSString *)url
 parameters:(NSDictionary * _Nullable)parameters
 completion:(void(^)(id _Nullable responseObject, NSError * _Nullable error))completion;

@end

NS_ASSUME_NONNULL_END
