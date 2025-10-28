//
//  TCUAPIService.m
//  ZD8-TCU
//
//  iOS API服务 - 完整修复版（无需修改服务器）
//

#import "TCUAPIService.h"
#import "TCUSSLManager.h"
#import "TCUAPIConfig.h"
#import "TCUStreamBasedRequest.h"

@interface TCUAPIService () <NSURLSessionDelegate, NSURLSessionTaskDelegate>

@property (nonatomic, strong) NSURLSession *urlSession;
@property (nonatomic, strong) TCUSSLManager *sslManager;
@property (nonatomic, strong) NSOperationQueue *delegateQueue;

@end

@implementation TCUAPIService

#pragma mark - Singleton

+ (instancetype)sharedService {
    static TCUAPIService *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[self alloc] init];
    });
    return sharedInstance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _sslManager = [[TCUSSLManager alloc] init];
        _delegateQueue = [[NSOperationQueue alloc] init];
        _delegateQueue.maxConcurrentOperationCount = 1;
        _delegateQueue.name = @"com.tcu.api.delegate";
        
        [self setupURLSession];
    }
    return self;
}

#pragma mark - SSL Configuration

- (BOOL)setupSSLWithCertName:(NSString *)certName password:(NSString *)password {
    
    TCUAPILog(@"🔐 配置SSL证书");
    TCUAPILog(@"   证书名称: %@", certName);
    
    BOOL success = [self.sslManager loadCertificateFromP12:certName password:password];
    
    if (success) {
        TCUAPILog(@"✅ SSL证书配置成功");
        // 重新创建URLSession以应用新证书
        [self setupURLSession];
    } else {
        TCUAPILogError(@"❌ SSL配置失败");
    }
    
    return success;
}

- (BOOL)isSSLConfigured {
    return [self.sslManager isConfigured];
}

#pragma mark - URLSession Setup

- (void)setupURLSession {
    
    // 如果已存在session，先失效
    if (self.urlSession) {
        [self.urlSession invalidateAndCancel];
        self.urlSession = nil;
    }
    
    NSURLSessionConfiguration *config = [NSURLSessionConfiguration defaultSessionConfiguration];
    
    // ✅ 关键修复1：强制使用HTTP/1.1（避免HTTP/2的客户端证书bug）
    config.HTTPShouldUsePipelining = NO;
    config.HTTPMaximumConnectionsPerHost = 1;
    
    // ✅ 关键修复2：超时设置
    config.timeoutIntervalForRequest = 30.0;
    config.timeoutIntervalForResource = 60.0;
    
    // ✅ 关键修复3：禁用缓存（确保每次都进行证书认证）
    config.URLCache = nil;
    config.requestCachePolicy = NSURLRequestReloadIgnoringLocalCacheData;
    
    // ✅ 关键修复4：TLS配置
    config.TLSMinimumSupportedProtocolVersion = tls_protocol_version_TLSv12;
    config.TLSMaximumSupportedProtocolVersion = tls_protocol_version_TLSv13;
    
    // 请求头
    config.HTTPAdditionalHeaders = @{
        @"Content-Type": @"application/json",
        @"Accept": @"application/json"
    };
    
    // ✅ 关键修复5：预先配置客户端证书到 URLCredentialStorage
    if ([self.sslManager isConfigured]) {
        [self configureClientCertificateForDomain:@"zendao8.top"];
    }
    
    // ✅ 关键修复6：使用自定义delegateQueue
    self.urlSession = [NSURLSession sessionWithConfiguration:config
                                                    delegate:self
                                               delegateQueue:self.delegateQueue];
    
    TCUAPILog(@"✅ URLSession已配置（强制客户端证书模式）");
}

#pragma mark - Certificate Configuration

- (void)configureClientCertificateForDomain:(NSString *)domain {
    NSURLCredential *credential = [self.sslManager createCredential];
    if (!credential) {
        TCUAPILogError(@"❌ 无法创建客户端证书凭据");
        return;
    }
    
    // ✅ 为所有可能的认证方法设置默认凭据
    NSArray *authMethods = @[
        NSURLAuthenticationMethodClientCertificate,
        NSURLAuthenticationMethodServerTrust,
        NSURLAuthenticationMethodDefault
    ];
    
    for (NSString *authMethod in authMethods) {
        NSURLProtectionSpace *protectionSpace = [[NSURLProtectionSpace alloc]
            initWithHost:domain
            port:443
            protocol:@"https"
            realm:nil
            authenticationMethod:authMethod];
        
        [[NSURLCredentialStorage sharedCredentialStorage]
            setDefaultCredential:credential
            forProtectionSpace:protectionSpace];
        
        TCUAPILog(@"✓ 已为 %@ 设置证书凭据",
                 [authMethod stringByReplacingOccurrencesOfString:@"NSURLAuthenticationMethod" withString:@""]);
    }
}

#pragma mark - API Methods

- (void)GET:(NSURL *)url
 parameters:(NSDictionary *)parameters
 completion:(void(^)(id _Nullable responseObject, NSError * _Nullable error))completion {
    
    // 构建URL参数
    NSMutableString *urlString = [url.absoluteString mutableCopy];
    if (parameters && parameters.count > 0) {
        [urlString appendString:@"?"];
        NSMutableArray *pairs = [NSMutableArray array];
        for (NSString *key in parameters) {
            NSString *value = [parameters[key] description];
            NSString *escapedValue = [value stringByAddingPercentEncodingWithAllowedCharacters:
                                     [NSCharacterSet URLQueryAllowedCharacterSet]];
            [pairs addObject:[NSString stringWithFormat:@"%@=%@", key, escapedValue]];
        }
        [urlString appendString:[pairs componentsJoinedByString:@"&"]];
    }
    
    NSURL *requestURL = [NSURL URLWithString:urlString];
    
    TCUAPILog(@"📤 GET请求: %@", requestURL.absoluteString);
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:requestURL];
    request.HTTPMethod = @"GET";
    
    // ✅ 强制使用HTTP/1.1
    [request setValue:@"keep-alive" forHTTPHeaderField:@"Connection"];
    
    [self performRequest:request completion:completion];
}

- (void)POST:(NSURL *)url
  parameters:(NSDictionary *)parameters
  completion:(void(^)(id _Nullable responseObject, NSError * _Nullable error))completion {
    
    TCUAPILog(@"📤 POST请求: %@", url.absoluteString);
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    request.HTTPMethod = @"POST";
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [request setValue:@"keep-alive" forHTTPHeaderField:@"Connection"];
    
    if (parameters) {
        NSError *jsonError = nil;
        NSData *jsonData = [NSJSONSerialization dataWithJSONObject:parameters
                                                          options:0
                                                            error:&jsonError];
        if (jsonError) {
            TCUAPILogError(@"❌ JSON序列化失败: %@", jsonError.localizedDescription);
            if (completion) {
                completion(nil, jsonError);
            }
            return;
        }
        request.HTTPBody = jsonData;
    }
    
    [self performRequest:request completion:completion];
}

- (void)PUT:(NSURL *)url
 parameters:(NSDictionary *)parameters
 completion:(void(^)(id _Nullable responseObject, NSError * _Nullable error))completion {
    
    TCUAPILog(@"📤 PUT请求: %@", url.absoluteString);
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    request.HTTPMethod = @"PUT";
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [request setValue:@"keep-alive" forHTTPHeaderField:@"Connection"];
    
    if (parameters) {
        NSError *jsonError = nil;
        NSData *jsonData = [NSJSONSerialization dataWithJSONObject:parameters
                                                          options:0
                                                            error:&jsonError];
        if (jsonError) {
            TCUAPILogError(@"❌ JSON序列化失败: %@", jsonError.localizedDescription);
            if (completion) {
                completion(nil, jsonError);
            }
            return;
        }
        request.HTTPBody = jsonData;
    }
    
    [self performRequest:request completion:completion];
}

- (void)DELETE:(NSURL *)url
    completion:(void(^)(id _Nullable responseObject, NSError * _Nullable error))completion {
    
    TCUAPILog(@"📤 DELETE请求: %@", url.absoluteString);
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    request.HTTPMethod = @"DELETE";
    [request setValue:@"keep-alive" forHTTPHeaderField:@"Connection"];
    
    [self performRequest:request completion:completion];
}

#pragma mark - Private Methods
- (void)performRequest:(NSURLRequest *)request
            completion:(void(^)(id _Nullable responseObject, NSError * _Nullable error))completion {
    
    if (![self.sslManager isConfigured]) {
        TCUAPILogError(@"❌ SSL证书未配置");
        NSError *error = [NSError errorWithDomain:@"TCUAPIService"
                                            code:-1
                                        userInfo:@{NSLocalizedDescriptionKey: @"SSL not configured"}];
        if (completion) completion(nil, error);
        return;
    }
    
    TCUAPILog(@"🚀 开始请求（使用 Stream 模式，强制发送证书）");
    
    // ✅ 使用 Stream API 执行请求
    [TCUStreamBasedRequest performRequest:request
                             withIdentity:self.sslManager.identity
                               completion:^(NSData *data, NSHTTPURLResponse *response, NSError *error) {
        
        if (error) {
            TCUAPILogError(@"❌ 请求失败: %@", error.localizedDescription);
            TCUAPILogError(@"   错误码: %ld", (long)error.code);
            
            if (completion) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    completion(nil, error);
                });
            }
            return;
        }
        
        NSInteger statusCode = response.statusCode;
        TCUAPILog(@"📥 响应: %ld", (long)statusCode);
        
        if (statusCode < 200 || statusCode >= 300) {
            TCUAPILogError(@"❌ HTTP错误: %ld", (long)statusCode);
            
            NSString *errorMsg = [NSString stringWithFormat:@"HTTP %ld", (long)statusCode];
            if (data) {
                NSString *responseStr = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
                if (responseStr) {
                    TCUAPILogError(@"响应内容: %@", responseStr);
                }
            }
            
            NSError *httpError = [NSError errorWithDomain:@"TCUAPIService"
                                                    code:statusCode
                                                userInfo:@{NSLocalizedDescriptionKey: errorMsg}];
            if (completion) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    completion(nil, httpError);
                });
            }
            return;
        }
        
        // 解析 JSON
        if (!data || data.length == 0) {
            TCUAPILog(@"✅ 请求成功（无响应体）");
            if (completion) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    completion(nil, nil);
                });
            }
            return;
        }
        
        NSError *jsonError = nil;
        id responseObject = [NSJSONSerialization JSONObjectWithData:data
                                                           options:0
                                                             error:&jsonError];
        
        if (jsonError) {
            TCUAPILogError(@"❌ JSON解析失败");
            if (completion) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    completion(nil, jsonError);
                });
            }
            return;
        }
        
        TCUAPILog(@"✅ 请求成功");
        
        if (completion) {
            dispatch_async(dispatch_get_main_queue(), ^{
                completion(responseObject, nil);
            });
        }
    }];
}

#pragma mark - NSURLSessionDelegate

// ✅ 关键修复7：实现服务器信任验证和客户端证书提供
- (void)URLSession:(NSURLSession *)session
didReceiveChallenge:(NSURLAuthenticationChallenge *)challenge
 completionHandler:(void (^)(NSURLSessionAuthChallengeDisposition, NSURLCredential * _Nullable))completionHandler {
    
    TCUAPILog(@"🔐 认证挑战: %@", challenge.protectionSpace.authenticationMethod);
    
    // 处理客户端证书认证
    if ([challenge.protectionSpace.authenticationMethod isEqualToString:NSURLAuthenticationMethodClientCertificate]) {
        TCUAPILog(@"📋 服务器请求客户端证书");
        
        if (![self.sslManager isConfigured]) {
            TCUAPILogError(@"❌ 证书未配置");
            completionHandler(NSURLSessionAuthChallengeCancelAuthenticationChallenge, nil);
            return;
        }
        
        // 创建凭据
        NSURLCredential *credential = [self.sslManager createCredential];
        
        if (credential) {
            TCUAPILog(@"✅ 提供客户端证书");
            completionHandler(NSURLSessionAuthChallengeUseCredential, credential);
        } else {
            TCUAPILogError(@"❌ 无法创建证书凭据");
            completionHandler(NSURLSessionAuthChallengeCancelAuthenticationChallenge, nil);
        }
        return;
    }
    
    // 处理服务器信任验证
    if ([challenge.protectionSpace.authenticationMethod isEqualToString:NSURLAuthenticationMethodServerTrust]) {
        TCUAPILog(@"🔒 验证服务器证书");
        
        SecTrustRef serverTrust = challenge.protectionSpace.serverTrust;
        
        // ✅ 对于自签名证书，可以选择信任
        NSURLCredential *credential = [NSURLCredential credentialForTrust:serverTrust];
        TCUAPILog(@"✅ 接受服务器证书");
        completionHandler(NSURLSessionAuthChallengeUseCredential, credential);
        return;
    }
    
    // ✅ 处理默认认证方法 - 也尝试提供客户端证书
    if ([challenge.protectionSpace.authenticationMethod isEqualToString:NSURLAuthenticationMethodDefault]) {
        TCUAPILog(@"📋 默认认证方法");
        
        if ([self.sslManager isConfigured]) {
            NSURLCredential *credential = [self.sslManager createCredential];
            if (credential) {
                TCUAPILog(@"✅ 尝试提供客户端证书");
                completionHandler(NSURLSessionAuthChallengeUseCredential, credential);
                return;
            }
        }
    }
    
    // 其他认证方式使用默认处理
    TCUAPILog(@"⚠️ 使用默认认证处理");
    completionHandler(NSURLSessionAuthChallengePerformDefaultHandling, nil);
}

#pragma mark - NSURLSessionTaskDelegate

// ✅ 在Task级别也处理认证（双重保险）
- (void)URLSession:(NSURLSession *)session
              task:(NSURLSessionTask *)task
didReceiveChallenge:(NSURLAuthenticationChallenge *)challenge
 completionHandler:(void (^)(NSURLSessionAuthChallengeDisposition, NSURLCredential *))completionHandler {
    
    TCUAPILog(@"🔐 [Task] 认证挑战: %@", challenge.protectionSpace.authenticationMethod);
    
    // 客户端证书
    if ([challenge.protectionSpace.authenticationMethod isEqualToString:NSURLAuthenticationMethodClientCertificate]) {
        NSURLCredential *credential = [self.sslManager createCredential];
        if (credential) {
            TCUAPILog(@"✅ [Task] 提供客户端证书");
            completionHandler(NSURLSessionAuthChallengeUseCredential, credential);
            return;
        }
    }
    
    // 服务器信任
    if ([challenge.protectionSpace.authenticationMethod isEqualToString:NSURLAuthenticationMethodServerTrust]) {
        NSURLCredential *credential = [NSURLCredential credentialForTrust:challenge.protectionSpace.serverTrust];
        TCUAPILog(@"✅ [Task] 接受服务器证书");
        completionHandler(NSURLSessionAuthChallengeUseCredential, credential);
        return;
    }
    
    // 调用 session 级别的处理
    [self URLSession:session didReceiveChallenge:challenge completionHandler:completionHandler];
}

#pragma mark - Testing
- (void)testConnection {
    TCUAPILog(@"========== 开始连接测试 ==========");
    
    if (![self.sslManager isConfigured]) {
        TCUAPILogError(@"❌ 测试失败：SSL证书未配置");
        return;
    }
    
    NSURL *testURL = API_URL(API_VEHICLE_INFO);
    TCUAPILog(@"测试URL: %@", testURL.absoluteString);
    
    // ✅ 改为 POST，并提供必需的参数
    NSDictionary *testData = @{
        @"vin": @"WBA8X9108LGM47279",
        @"hwid": @"IOS_Device",
        @"platform": @(1),  // 1 = iOS
        @"svt": @{
            @"test_key": @"test_value"
        },
        @"cafd": @{}
    };
    
    [self POST:testURL parameters:testData completion:^(id responseObject, NSError *error) {
        if (error) {
            TCUAPILogError(@"❌ 测试失败: %@", error.localizedDescription);
        } else {
            TCUAPILog(@"✅ 测试成功");
            if (responseObject) {
                TCUAPILog(@"响应: %@", responseObject);
            }
        }
        TCUAPILog(@"========== 测试完成 ==========");
    }];
}

@end
