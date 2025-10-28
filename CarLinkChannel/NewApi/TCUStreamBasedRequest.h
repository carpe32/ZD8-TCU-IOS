//
//  TCUStreamBasedRequest.h
//  ZD8-TCU
//
//  使用 CFNetwork Stream API 强制发送客户端证书
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface TCUStreamBasedRequest : NSObject

/**
 * 使用底层 Stream API 执行 HTTPS 请求
 * 等效于 C# 的 ClientCertificateOption.Manual
 */
+ (void)performRequest:(NSURLRequest *)request
        withIdentity:(SecIdentityRef)identity
          completion:(void(^)(NSData * _Nullable data,
                              NSHTTPURLResponse * _Nullable response,
                              NSError * _Nullable error))completion;

@end

NS_ASSUME_NONNULL_END
