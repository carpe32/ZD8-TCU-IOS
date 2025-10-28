//
//  TCUSSLURLSessionConfiguration.h
//  ZD8-TCU
//
//  底层SSL配置 - 强制在TLS握手时发送客户端证书
//

#import <Foundation/Foundation.h>
#import <Security/Security.h>

NS_ASSUME_NONNULL_BEGIN

@interface TCUSSLURLSessionConfiguration : NSObject

/**
 * 创建配置了客户端证书的URLSession
 * @param identity 客户端身份
 * @param certificate 客户端证书
 * @return 配置好的URLSession
 */
+ (NSURLSession *)createSessionWithIdentity:(SecIdentityRef)identity
                               certificate:(SecCertificateRef)certificate
                                  delegate:(id<NSURLSessionDelegate>)delegate;

@end

NS_ASSUME_NONNULL_END
