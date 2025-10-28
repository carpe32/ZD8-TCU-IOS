//
//  TCUStreamBasedRequest.m
//  ZD8-TCU
//

#import "TCUStreamBasedRequest.h"
#import <CFNetwork/CFNetwork.h>

@implementation TCUStreamBasedRequest

+ (void)performRequest:(NSURLRequest *)request
          withIdentity:(SecIdentityRef)identity
            completion:(void(^)(NSData * _Nullable, NSHTTPURLResponse * _Nullable, NSError * _Nullable))completion {
    
    NSLog(@"[Stream-SSL] 🚀 开始请求（Stream模式）");
    NSLog(@"[Stream-SSL] URL: %@", request.URL.absoluteString);
    NSLog(@"[Stream-SSL] Method: %@", request.HTTPMethod ?: @"GET");
    
    // 1. 创建 HTTP 消息
    CFHTTPMessageRef httpMessage = CFHTTPMessageCreateRequest(
        kCFAllocatorDefault,
        (__bridge CFStringRef)(request.HTTPMethod ?: @"GET"),
        (__bridge CFURLRef)request.URL,
        kCFHTTPVersion1_1
    );
    
    // 2. 添加 Headers
    NSDictionary *headers = request.allHTTPHeaderFields;
    if (!headers) {
        headers = @{};
    }
    
    // 确保有这些基本 Header
    NSMutableDictionary *finalHeaders = [headers mutableCopy];
    if (!finalHeaders[@"User-Agent"]) {
        finalHeaders[@"User-Agent"] = @"TCU-iOS/1.0";
    }
    if (!finalHeaders[@"Accept"]) {
        finalHeaders[@"Accept"] = @"application/json";
    }
    if (!finalHeaders[@"Content-Type"] && request.HTTPBody) {
        finalHeaders[@"Content-Type"] = @"application/json";
    }
    
    for (NSString *key in finalHeaders) {
        CFHTTPMessageSetHeaderFieldValue(
            httpMessage,
            (__bridge CFStringRef)key,
            (__bridge CFStringRef)finalHeaders[key]
        );
    }
    
    // 3. 设置 Body（如果有）
    if (request.HTTPBody) {
        CFHTTPMessageSetBody(httpMessage, (__bridge CFDataRef)request.HTTPBody);
        NSLog(@"[Stream-SSL] Body 大小: %lu bytes", (unsigned long)request.HTTPBody.length);
    }
    
    // 4. 创建 ReadStream
    CFReadStreamRef readStream = CFReadStreamCreateForHTTPRequest(
        kCFAllocatorDefault,
        httpMessage
    );
    CFRelease(httpMessage);
    
    if (!readStream) {
        NSLog(@"[Stream-SSL] ❌ 创建 ReadStream 失败");
        if (completion) {
            NSError *error = [NSError errorWithDomain:@"TCUStreamSSL"
                                                code:-1
                                            userInfo:@{NSLocalizedDescriptionKey: @"Failed to create stream"}];
            completion(nil, nil, error);
        }
        return;
    }
    
    // 5. ✅ 关键：配置 SSL 属性，强制发送客户端证书
    NSMutableDictionary *sslSettings = [NSMutableDictionary dictionary];
    
    // ✅ 最关键：添加客户端证书（等效于 C# 的 Manual 模式）
    if (identity) {
        NSArray *certificates = @[(__bridge id)identity];
        [sslSettings setObject:certificates
                        forKey:(NSString *)kCFStreamSSLCertificates];
        NSLog(@"[Stream-SSL] ✅ 已添加客户端证书到 SSL 设置");
    } else {
        NSLog(@"[Stream-SSL] ⚠️ 警告：未提供客户端证书");
    }
    
    // SSL 协议版本
    [sslSettings setObject:(NSString *)kCFStreamSocketSecurityLevelNegotiatedSSL
                    forKey:(NSString *)kCFStreamSSLLevel];
    
    // ✅ 关键：对于自签名证书，禁用证书链验证
    [sslSettings setObject:@NO
                    forKey:(NSString *)kCFStreamSSLValidatesCertificateChain];
    
    // 允许过期证书（可选）
    [sslSettings setObject:@YES
                    forKey:(NSString *)kCFStreamSSLAllowsExpiredCertificates];
    
    // 允许根证书过期（可选）
    [sslSettings setObject:@YES
                    forKey:(NSString *)kCFStreamSSLAllowsExpiredRoots];
    
    // 允许任何根证书（可选）
    [sslSettings setObject:@YES
                    forKey:(NSString *)kCFStreamSSLAllowsAnyRoot];
    
    // 应用 SSL 设置
    CFReadStreamSetProperty(
        readStream,
        kCFStreamPropertySSLSettings,
        (__bridge CFDictionaryRef)sslSettings
    );
    
    NSLog(@"[Stream-SSL] ✅ SSL 设置已配置");
    
    // 6. 启用自动重定向
    CFReadStreamSetProperty(
        readStream,
        kCFStreamPropertyHTTPShouldAutoredirect,
        kCFBooleanTrue
    );
    
    // 7. 在后台线程打开流并读取数据
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        
        // 打开流
        if (!CFReadStreamOpen(readStream)) {
            NSLog(@"[Stream-SSL] ❌ 打开 ReadStream 失败");
            
            CFErrorRef error = CFReadStreamCopyError(readStream);
            NSError *nsError = error ? (__bridge_transfer NSError *)error :
                [NSError errorWithDomain:@"TCUStreamSSL"
                                   code:-2
                               userInfo:@{NSLocalizedDescriptionKey: @"Failed to open stream"}];
            
            dispatch_async(dispatch_get_main_queue(), ^{
                if (completion) {
                    completion(nil, nil, nsError);
                }
            });
            
            CFRelease(readStream);
            return;
        }
        
        NSLog(@"[Stream-SSL] ✓ ReadStream 已打开");
        NSLog(@"[Stream-SSL] ✓ 正在建立 TLS 连接...");
        
        // 读取数据
        NSMutableData *responseData = [NSMutableData data];
        UInt8 buffer[4096];
        CFIndex bytesRead;
        
        while ((bytesRead = CFReadStreamRead(readStream, buffer, sizeof(buffer))) > 0) {
            [responseData appendBytes:buffer length:bytesRead];
        }
        
        // 检查错误
        NSError *streamError = nil;
        NSHTTPURLResponse *httpResponse = nil;
        
        if (bytesRead < 0) {
            CFErrorRef error = CFReadStreamCopyError(readStream);
            if (error) {
                streamError = (__bridge_transfer NSError *)error;
                NSLog(@"[Stream-SSL] ❌ 读取失败: %@", streamError.localizedDescription);
                NSLog(@"[Stream-SSL] 错误码: %ld", (long)streamError.code);
                NSLog(@"[Stream-SSL] 错误域: %@", streamError.domain);
            }
        } else {
            NSLog(@"[Stream-SSL] ✅ 读取成功，数据大小: %lu bytes", (unsigned long)responseData.length);
            
            // 获取 HTTP 响应信息
            CFHTTPMessageRef responseMessage = (CFHTTPMessageRef)CFReadStreamCopyProperty(
                readStream,
                kCFStreamPropertyHTTPResponseHeader
            );
            
            if (responseMessage) {
                CFIndex statusCode = CFHTTPMessageGetResponseStatusCode(responseMessage);
                NSLog(@"[Stream-SSL] HTTP 状态码: %ld", (long)statusCode);
                
                // 获取响应头
                NSDictionary *responseHeaders = (__bridge_transfer NSDictionary *)
                    CFHTTPMessageCopyAllHeaderFields(responseMessage);
                
                httpResponse = [[NSHTTPURLResponse alloc]
                    initWithURL:request.URL
                    statusCode:statusCode
                    HTTPVersion:@"HTTP/1.1"
                    headerFields:responseHeaders];
                
                CFRelease(responseMessage);
            }
        }
        
        // 关闭并释放流
        CFReadStreamClose(readStream);
        CFRelease(readStream);
        
        // 回调到主线程
        dispatch_async(dispatch_get_main_queue(), ^{
            if (completion) {
                completion(responseData, httpResponse, streamError);
            }
        });
    });
}

@end
