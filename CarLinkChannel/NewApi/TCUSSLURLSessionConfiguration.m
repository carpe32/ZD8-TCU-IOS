//
//  TCUSSLURLSessionConfiguration.m
//  ZD8-TCU
//

#import "TCUSSLURLSessionConfiguration.h"

@implementation TCUSSLURLSessionConfiguration

+ (NSURLSession *)createSessionWithIdentity:(SecIdentityRef)identity
                               certificate:(SecCertificateRef)certificate
                                  delegate:(id<NSURLSessionDelegate>)delegate {
    
    NSURLSessionConfiguration *config = [NSURLSessionConfiguration ephemeralSessionConfiguration];
    
    // 基本配置
    config.timeoutIntervalForRequest = 30.0;
    config.timeoutIntervalForResource = 60.0;
    config.URLCache = nil;
    config.requestCachePolicy = NSURLRequestReloadIgnoringLocalCacheData;
    config.HTTPShouldUsePipelining = NO;
    
    config.HTTPAdditionalHeaders = @{
        @"Content-Type": @"application/json",
        @"Accept": @"application/json"
    };
    
    // ✅ TLS配置
    if (@available(iOS 13.0, *)) {
        config.TLSMinimumSupportedProtocolVersion = tls_protocol_version_TLSv12;
        config.TLSMaximumSupportedProtocolVersion = tls_protocol_version_TLSv13;
    }
    
    // ✅ 关键：配置连接代理以在底层设置客户端证书
    // 这会让证书在TCP连接建立时就被包含，而不是等待挑战
    NSDictionary *connectionProxyDict = @{
        (NSString *)kCFStreamPropertySSLSettings: @{
            // 客户端证书
            (NSString *)kCFStreamSSLCertificates: @[
                (__bridge id)identity,
                (__bridge id)certificate
            ],
            // 对等名称
            (NSString *)kCFStreamSSLPeerName: (id)kCFNull,
            // 验证级别
            (NSString *)kCFStreamSSLLevel: (NSString *)kCFStreamSocketSecurityLevelNegotiatedSSL,
            // 允许过期证书（仅用于自签名）
            (NSString *)kCFStreamSSLValidatesCertificateChain: @NO
        }
    };
    
    config.connectionProxyDictionary = connectionProxyDict;
    
    // 创建URLSession
    NSURLSession *session = [NSURLSession sessionWithConfiguration:config
                                                          delegate:delegate
                                                     delegateQueue:nil];
    
    return session;
}

@end
