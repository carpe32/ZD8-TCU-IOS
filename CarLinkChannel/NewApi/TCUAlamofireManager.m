//
//  TCUAlamofireManager.m
//  ZD8-TCU
//

#import "TCUAlamofireManager.h"

@interface TCUAlamofireManager () <NSURLSessionDelegate>

@property (nonatomic, strong) NSURLSession *session;
@property (nonatomic, assign) SecIdentityRef clientIdentity;
@property (nonatomic, assign) SecCertificateRef clientCertificate;

@end

@implementation TCUAlamofireManager

+ (instancetype)sharedManager {
    static TCUAlamofireManager *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[self alloc] init];
    });
    return instance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _clientIdentity = NULL;
        _clientCertificate = NULL;
        [self setupSession];
    }
    return self;
}

- (BOOL)setupSSLWithCertName:(NSString *)certName password:(NSString *)password {
    
    NSLog(@"[Alamofire-OC] 🔐 配置SSL证书: %@", certName);
    
    // 加载证书文件
    NSString *certPath = [[NSBundle mainBundle] pathForResource:certName ofType:@"p12"];
    if (!certPath) {
        NSLog(@"[Alamofire-OC] ❌ 证书文件未找到");
        return NO;
    }
    
    NSData *certData = [NSData dataWithContentsOfFile:certPath];
    if (!certData) {
        NSLog(@"[Alamofire-OC] ❌ 无法读取证书文件");
        return NO;
    }
    
    // 导入证书
    NSDictionary *options = @{(__bridge id)kSecImportExportPassphrase: password};
    CFArrayRef items = NULL;
    OSStatus status = SecPKCS12Import((__bridge CFDataRef)certData,
                                     (__bridge CFDictionaryRef)options,
                                     &items);
    
    if (status != errSecSuccess || !items) {
        NSLog(@"[Alamofire-OC] ❌ 证书导入失败: %d", (int)status);
        return NO;
    }
    
    // ✅ 修复：提取identity和证书
    NSDictionary *firstItem = (__bridge NSDictionary *)CFArrayGetValueAtIndex(items, 0);
    
    // 提取identity
    SecIdentityRef identity = (__bridge SecIdentityRef)firstItem[(NSString *)kSecImportItemIdentity];
    if (identity) {
        CFRetain(identity);
        if (_clientIdentity) CFRelease(_clientIdentity);
        _clientIdentity = identity;
    }
    
    // ✅ 从identity提取证书（而不是从字典）
    SecCertificateRef cert = NULL;
    if (identity) {
        OSStatus certStatus = SecIdentityCopyCertificate(identity, &cert);
        if (certStatus == errSecSuccess && cert) {
            if (_clientCertificate) CFRelease(_clientCertificate);
            _clientCertificate = cert; // 已经被retain了
        }
    }
    
    CFRelease(items);
    
    if (!_clientIdentity || !_clientCertificate) {
        NSLog(@"[Alamofire-OC] ❌ 无法提取证书数据");
        return NO;
    }
    
    // 打印证书信息
    CFStringRef summary = SecCertificateCopySubjectSummary(_clientCertificate);
    NSLog(@"[Alamofire-OC] ✅ 证书加载成功: %@", (__bridge NSString *)summary);
    if (summary) CFRelease(summary);
    
    // 重新创建Session
    [self setupSession];
    
    return YES;
}

- (void)setupSession {
    
    NSURLSessionConfiguration *config = [NSURLSessionConfiguration defaultSessionConfiguration];
    config.timeoutIntervalForRequest = 30.0;
    config.timeoutIntervalForResource = 60.0;
    
    // 禁用缓存
    config.URLCache = nil;
    config.requestCachePolicy = NSURLRequestReloadIgnoringLocalCacheData;
    
    // TLS配置
    if (@available(iOS 13.0, *)) {
        config.TLSMinimumSupportedProtocolVersion = tls_protocol_version_TLSv12;
        config.TLSMaximumSupportedProtocolVersion = tls_protocol_version_TLSv13;
    }
    
    _session = [NSURLSession sessionWithConfiguration:config
                                              delegate:self
                                         delegateQueue:nil];
    
    NSLog(@"[Alamofire-OC] ✅ URLSession已配置");
}

- (void)POST:(NSString *)url
  parameters:(NSDictionary *)parameters
  completion:(void(^)(id _Nullable responseObject, NSError * _Nullable error))completion {
    
    NSLog(@"[Alamofire-OC] 📤 POST: %@", url);
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:url]];
    request.HTTPMethod = @"POST";
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [request setValue:@"application/json" forHTTPHeaderField:@"Accept"];
    
    if (parameters) {
        NSError *jsonError = nil;
        NSData *jsonData = [NSJSONSerialization dataWithJSONObject:parameters
                                                           options:NSJSONWritingPrettyPrinted
                                                             error:&jsonError];
        if (jsonError) {
            NSLog(@"[Alamofire-OC] ❌ JSON序列化失败: %@", jsonError);
            if (completion) completion(nil, jsonError);
            return;
        }
        
        request.HTTPBody = jsonData;
        
        // 打印请求体（调试用）
        NSString *jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
        NSLog(@"[Alamofire-OC] 📄 请求体:\n%@", jsonString);
    }
    
    NSURLSessionDataTask *task = [_session dataTaskWithRequest:request
                                             completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        
        dispatch_async(dispatch_get_main_queue(), ^{
            if (error) {
                NSLog(@"[Alamofire-OC] ❌ 请求失败: %@", error);
                if (completion) completion(nil, error);
                return;
            }
            
            NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
            NSLog(@"[Alamofire-OC] ✅ HTTP %ld", (long)httpResponse.statusCode);
            NSLog(@"[Alamofire-OC] 📥 响应头: %@", httpResponse.allHeaderFields);
            
            if (data && data.length > 0) {
                NSError *parseError = nil;
                id json = [NSJSONSerialization JSONObjectWithData:data options:0 error:&parseError];
                
                if (parseError) {
                    NSString *rawResponse = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
                    NSLog(@"[Alamofire-OC] ❌ JSON解析失败: %@", parseError);
                    NSLog(@"[Alamofire-OC] 原始响应: %@", rawResponse);
                    if (completion) completion(nil, parseError);
                    return;
                }
                
                NSLog(@"[Alamofire-OC] 📥 响应内容: %@", json);
                if (completion) completion(json, nil);
            } else {
                NSLog(@"[Alamofire-OC] ℹ️ 响应无内容");
                if (completion) completion(@{@"status": @"success"}, nil);
            }
        });
    }];
    
    [task resume];
    NSLog(@"[Alamofire-OC] 🚀 请求已发送");
}

- (void)GET:(NSString *)url
 parameters:(NSDictionary *)parameters
 completion:(void(^)(id _Nullable responseObject, NSError * _Nullable error))completion {
    
    // 构建URL参数
    NSMutableString *urlString = [url mutableCopy];
    if (parameters && parameters.count > 0) {
        [urlString appendString:@"?"];
        NSMutableArray *pairs = [NSMutableArray array];
        for (NSString *key in parameters) {
            NSString *value = [NSString stringWithFormat:@"%@", parameters[key]];
            NSString *encodedValue = [value stringByAddingPercentEncodingWithAllowedCharacters:
                                     [NSCharacterSet URLQueryAllowedCharacterSet]];
            [pairs addObject:[NSString stringWithFormat:@"%@=%@", key, encodedValue]];
        }
        [urlString appendString:[pairs componentsJoinedByString:@"&"]];
    }
    
    NSLog(@"[Alamofire-OC] 📤 GET: %@", urlString);
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:urlString]];
    request.HTTPMethod = @"GET";
    [request setValue:@"application/json" forHTTPHeaderField:@"Accept"];
    
    NSURLSessionDataTask *task = [_session dataTaskWithRequest:request
                                             completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        
        dispatch_async(dispatch_get_main_queue(), ^{
            if (error) {
                NSLog(@"[Alamofire-OC] ❌ 请求失败: %@", error);
                if (completion) completion(nil, error);
                return;
            }
            
            NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
            NSLog(@"[Alamofire-OC] ✅ HTTP %ld", (long)httpResponse.statusCode);
            
            if (data && data.length > 0) {
                NSError *parseError = nil;
                id json = [NSJSONSerialization JSONObjectWithData:data options:0 error:&parseError];
                if (completion) completion(json, parseError);
            } else {
                if (completion) completion(nil, nil);
            }
        });
    }];
    
    [task resume];
    NSLog(@"[Alamofire-OC] 🚀 请求已发送");
}

#pragma mark - NSURLSessionDelegate

- (void)URLSession:(NSURLSession *)session
didReceiveChallenge:(NSURLAuthenticationChallenge *)challenge
 completionHandler:(void (^)(NSURLSessionAuthChallengeDisposition, NSURLCredential * _Nullable))completionHandler {
    
    NSString *authMethod = challenge.protectionSpace.authenticationMethod;
    NSLog(@"[Alamofire-OC] 🔐 收到认证挑战: %@", authMethod);
    NSLog(@"[Alamofire-OC]    Previous Failure Count: %ld", (long)challenge.previousFailureCount);
    
    // 服务器证书验证
    if ([authMethod isEqualToString:NSURLAuthenticationMethodServerTrust]) {
        NSLog(@"[Alamofire-OC] 🔐 ServerTrust阶段");
        
        SecTrustRef serverTrust = challenge.protectionSpace.serverTrust;
        if (!serverTrust) {
            NSLog(@"[Alamofire-OC] ❌ 无法获取服务器信任");
            completionHandler(NSURLSessionAuthChallengeCancelAuthenticationChallenge, nil);
            return;
        }
        
        // 验证服务器证书
        SecTrustResultType trustResult;
        OSStatus status = SecTrustEvaluate(serverTrust, &trustResult);
        
        BOOL serverTrusted = (status == errSecSuccess) &&
                            (trustResult == kSecTrustResultUnspecified ||
                             trustResult == kSecTrustResultProceed ||
                             trustResult == kSecTrustResultRecoverableTrustFailure);
        
        if (!serverTrusted) {
            NSLog(@"[Alamofire-OC] ❌ 服务器证书验证失败");
            completionHandler(NSURLSessionAuthChallengeCancelAuthenticationChallenge, nil);
            return;
        }
        
        NSLog(@"[Alamofire-OC] ✅ 服务器证书验证通过");
        
        NSURLCredential *credential = [NSURLCredential credentialForTrust:serverTrust];
        completionHandler(NSURLSessionAuthChallengeUseCredential, credential);
        return;
    }
    
    // 客户端证书验证
    if ([authMethod isEqualToString:NSURLAuthenticationMethodClientCertificate]) {
        NSLog(@"[Alamofire-OC] 🔐 [关键] ClientCertificate阶段，提供客户端证书");
        
        if (!_clientIdentity || !_clientCertificate) {
            NSLog(@"[Alamofire-OC] ❌ 证书未配置");
            completionHandler(NSURLSessionAuthChallengeCancelAuthenticationChallenge, nil);
            return;
        }
        
        // 验证私钥
        SecKeyRef privateKey = NULL;
        OSStatus keyStatus = SecIdentityCopyPrivateKey(_clientIdentity, &privateKey);
        if (keyStatus != errSecSuccess || !privateKey) {
            NSLog(@"[Alamofire-OC] ❌ 私钥不可用");
            completionHandler(NSURLSessionAuthChallengeCancelAuthenticationChallenge, nil);
            return;
        }
        NSLog(@"[Alamofire-OC] ✅ 私钥验证成功");
        CFRelease(privateKey);
        
        // 创建凭证
        NSArray *certs = @[(__bridge id)_clientCertificate];
        NSURLCredential *credential = [NSURLCredential credentialWithIdentity:_clientIdentity
                                                                 certificates:certs
                                                                  persistence:NSURLCredentialPersistenceForSession];
        
        if (credential) {
            CFStringRef cn = SecCertificateCopySubjectSummary(_clientCertificate);
            NSLog(@"[Alamofire-OC] ✅ 提供客户端证书: %@", (__bridge NSString *)cn);
            if (cn) CFRelease(cn);
            
            completionHandler(NSURLSessionAuthChallengeUseCredential, credential);
            return;
        }
        
        NSLog(@"[Alamofire-OC] ❌ 凭证创建失败");
        completionHandler(NSURLSessionAuthChallengeCancelAuthenticationChallenge, nil);
        return;
    }
    
    // 其他认证类型
    NSLog(@"[Alamofire-OC] ℹ️ 其他认证类型: %@", authMethod);
    completionHandler(NSURLSessionAuthChallengePerformDefaultHandling, nil);
}

- (void)dealloc {
    if (_clientIdentity) CFRelease(_clientIdentity);
    if (_clientCertificate) CFRelease(_clientCertificate);
}

@end
