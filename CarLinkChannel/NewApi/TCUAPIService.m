//
//  TCUAPIService.m
//  ZD8-TCU
//
//  iOS API服务 - 支持SSL双向认证
//

#import "TCUAPIService.h"
#import "TCUSSLManager.h"
#import "TCUAPIConfig.h"

@interface TCUAPIService () <NSURLSessionDelegate, NSURLSessionTaskDelegate>

@property (nonatomic, strong) NSURLSession *urlSession;
@property (nonatomic, strong) TCUSSLManager *sslManager;

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
        [self setupURLSession];
    }
    return self;
}

#pragma mark - SSL Configuration

- (BOOL)setupSSLWithCertName:(NSString *)certName password:(NSString *)password {
    
    TCUAPILog(@"🔐 配置SSL证书");
    TCUAPILog(@"   证书名称: %@", certName);
    TCUAPILog(@"   密码长度: %lu", (unsigned long)password.length);
    
    BOOL success = [self.sslManager loadCertificateFromP12:certName password:password];
    
    if (success) {
        TCUAPILog(@"✅ SSL证书配置成功");
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
    
    NSURLSessionConfiguration *config = [NSURLSessionConfiguration defaultSessionConfiguration];
    
    // 超时设置
    config.timeoutIntervalForRequest = 30.0;
    config.timeoutIntervalForResource = 60.0;
    
    // ✅ 关键：禁用HTTP/2（某些服务器的客户端证书认证在HTTP/2下有问题）
    config.HTTPShouldUsePipelining = NO;
    
    // 禁用缓存（确保每次都进行证书认证）
    config.URLCache = nil;
    config.requestCachePolicy = NSURLRequestReloadIgnoringLocalCacheData;
    
    // 请求头
    config.HTTPAdditionalHeaders = @{
        @"Content-Type": @"application/json",
        @"Accept": @"application/json",
        @"Connection": @"keep-alive"
    };
    
    // ✅ 创建 URLSession，设置 delegate（关键）
    self.urlSession = [NSURLSession sessionWithConfiguration:config
                                                    delegate:self
                                               delegateQueue:nil]; // 使用默认队列
    
    TCUAPILog(@"✅ URLSession已配置（SSL双向认证模式）");
}

#pragma mark - API Methods

- (void)GET:(NSURL *)url
 parameters:(NSDictionary *)parameters
 completion:(void(^)(id _Nullable responseObject, NSError * _Nullable error))completion {
    
    // 构建URL参数
    NSMutableString *urlString = [url.absoluteString mutableCopy];
    if (parameters && parameters.count > 0) {
        [urlString appendString:@"?"];
        
        NSMutableArray *paramPairs = [NSMutableArray array];
        for (NSString *key in parameters) {
            NSString *value = [NSString stringWithFormat:@"%@", parameters[key]];
            NSString *escapedValue = [value stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];
            [paramPairs addObject:[NSString stringWithFormat:@"%@=%@", key, escapedValue]];
        }
        [urlString appendString:[paramPairs componentsJoinedByString:@"&"]];
    }
    
    NSURL *requestURL = [NSURL URLWithString:urlString];
    
    TCUAPILog(@"📤 发送GET请求: %@", requestURL.absoluteString);
    if (parameters) {
        TCUAPILog(@"📦 请求参数: %@", parameters);
    }
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:requestURL];
    request.HTTPMethod = @"GET";
    [request setValue:@"application/json" forHTTPHeaderField:@"Accept"];
    
    [self executeRequest:request completion:completion];
}

- (void)POST:(NSURL *)url
  parameters:(NSDictionary *)parameters
  completion:(void(^)(id _Nullable responseObject, NSError * _Nullable error))completion {
    
    TCUAPILog(@"📤 发送POST请求: %@", url.absoluteString);
    TCUAPILog(@"📦 请求参数: %@", parameters);
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    request.HTTPMethod = @"POST";
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [request setValue:@"application/json" forHTTPHeaderField:@"Accept"];
    
    // 序列化JSON
    if (parameters) {
        NSError *jsonError = nil;
        NSData *jsonData = [NSJSONSerialization dataWithJSONObject:parameters
                                                          options:NSJSONWritingPrettyPrinted
                                                            error:&jsonError];
        if (jsonError) {
            TCUAPILogError(@"❌ JSON序列化失败: %@", jsonError);
            if (completion) {
                completion(nil, jsonError);
            }
            return;
        }
        
        // 打印请求体（调试用）
        NSString *jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
        TCUAPILog(@"📄 请求体:\n%@", jsonString);
        
        request.HTTPBody = jsonData;
    }
    
    [self executeRequest:request completion:completion];
}

- (void)PUT:(NSURL *)url
 parameters:(NSDictionary *)parameters
 completion:(void(^)(id _Nullable responseObject, NSError * _Nullable error))completion {
    
    TCUAPILog(@"📤 发送PUT请求: %@", url.absoluteString);
    TCUAPILog(@"📦 请求参数: %@", parameters);
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    request.HTTPMethod = @"PUT";
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [request setValue:@"application/json" forHTTPHeaderField:@"Accept"];
    
    if (parameters) {
        NSError *jsonError = nil;
        NSData *jsonData = [NSJSONSerialization dataWithJSONObject:parameters
                                                          options:0
                                                            error:&jsonError];
        if (jsonError) {
            TCUAPILogError(@"❌ JSON序列化失败: %@", jsonError);
            if (completion) {
                completion(nil, jsonError);
            }
            return;
        }
        
        request.HTTPBody = jsonData;
    }
    
    [self executeRequest:request completion:completion];
}

- (void)DELETE:(NSURL *)url
    completion:(void(^)(id _Nullable responseObject, NSError * _Nullable error))completion {
    
    TCUAPILog(@"📤 发送DELETE请求: %@", url.absoluteString);
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    request.HTTPMethod = @"DELETE";
    [request setValue:@"application/json" forHTTPHeaderField:@"Accept"];
    
    [self executeRequest:request completion:completion];
}

#pragma mark - Request Execution

- (void)executeRequest:(NSURLRequest *)request
            completion:(void(^)(id _Nullable responseObject, NSError * _Nullable error))completion {
    
    NSURLSessionDataTask *task = [self.urlSession dataTaskWithRequest:request
                                                     completionHandler:^(NSData *data,
                                                                       NSURLResponse *response,
                                                                       NSError *error) {
        
        // 切换到主线程处理回调
        dispatch_async(dispatch_get_main_queue(), ^{
            
            if (error) {
                TCUAPILogError(@"❌ 网络请求失败");
                TCUAPILogError(@"   错误代码: %ld", (long)error.code);
                TCUAPILogError(@"   错误描述: %@", error.localizedDescription);
                
                if (error.userInfo[NSUnderlyingErrorKey]) {
                    TCUAPILogError(@"   底层错误: %@", error.userInfo[NSUnderlyingErrorKey]);
                }
                
                // ⚠️ -1005 错误特殊处理
                if (error.code == NSURLErrorNetworkConnectionLost) {
                    TCUAPILogError(@"💡 提示: 这通常是SSL证书问题或网络不稳定");
                    TCUAPILogError(@"   请检查:");
                    TCUAPILogError(@"   1. SSL证书是否正确配置？");
                    TCUAPILogError(@"   2. 服务器是否要求客户端证书？");
                    TCUAPILogError(@"   3. 网络连接是否稳定？");
                }
                
                if (completion) {
                    completion(nil, error);
                }
                return;
            }
            
            // 打印响应
            NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
            TCUAPILog(@"✅ 收到响应: HTTP %ld", (long)httpResponse.statusCode);
            
            // 解析JSON响应
            if (data && data.length > 0) {
                NSError *parseError = nil;
                id jsonObject = [NSJSONSerialization JSONObjectWithData:data
                                                               options:0
                                                                 error:&parseError];
                
                if (parseError) {
                    TCUAPILogError(@"❌ JSON解析失败: %@", parseError);
                    NSString *rawResponse = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
                    TCUAPILogError(@"   原始响应: %@", rawResponse);
                    
                    if (completion) {
                        completion(nil, parseError);
                    }
                    return;
                }
                
                TCUAPILog(@"📥 响应内容: %@", jsonObject);
                
                // 检查HTTP状态码
                NSInteger statusCode = httpResponse.statusCode;
                if (statusCode >= 400) {
                    NSDictionary *errorDict = (NSDictionary *)jsonObject;
                    NSString *message = errorDict[@"message"] ?: @"服务器错误";
                    NSError *apiError = [self errorWithCode:statusCode message:message];
                    
                    if (completion) {
                        completion(nil, apiError);
                    }
                    return;
                }
                
                if (completion) {
                    completion(jsonObject, nil);
                }
                
            } else {
                // 没有响应体
                TCUAPILog(@"ℹ️ 响应无内容");
                
                if (completion) {
                    completion(@{@"status": @"success"}, nil);
                }
            }
        });
    }];
    
    [task resume];
    TCUAPILog(@"🚀 请求已发送");
}

#pragma mark - NSURLSessionDelegate - SSL认证

- (void)URLSession:(NSURLSession *)session
didReceiveChallenge:(NSURLAuthenticationChallenge *)challenge
 completionHandler:(void (^)(NSURLSessionAuthChallengeDisposition,
                            NSURLCredential * _Nullable))completionHandler {
    
    NSString *authMethod = challenge.protectionSpace.authenticationMethod;
    NSString *host = challenge.protectionSpace.host;
    
    TCUAPILog(@"🔐 [Session] 收到认证挑战: %@, Host: %@", authMethod, host);
    
    // 1. 服务器证书验证
    if ([authMethod isEqualToString:NSURLAuthenticationMethodServerTrust]) {
        
        SecTrustRef serverTrust = challenge.protectionSpace.serverTrust;
        
        // ✅ 关键：同时提供客户端证书
        if ([self.sslManager isConfigured]) {
            
            TCUAPILog(@"✅ 创建包含客户端证书的凭证");
            
            // 创建包含客户端身份的凭证
            NSArray *certificates = @[(__bridge id)self.sslManager.certificate];
            NSURLCredential *credential = [NSURLCredential credentialWithIdentity:self.sslManager.identity
                                                                     certificates:certificates
                                                                      persistence:NSURLCredentialPersistenceForSession];
            
            TCUAPILog(@"✅ 提供服务器信任 + 客户端证书");
            completionHandler(NSURLSessionAuthChallengeUseCredential, credential);
            
        } else {
            // 没有客户端证书，只信任服务器证书
            NSURLCredential *credential = [NSURLCredential credentialForTrust:serverTrust];
            TCUAPILog(@"⚠️ 仅提供服务器信任（无客户端证书）");
            completionHandler(NSURLSessionAuthChallengeUseCredential, credential);
        }
        
        return;
    }
    
    // 2. 客户端证书认证（如果服务器明确要求）
    if ([authMethod isEqualToString:NSURLAuthenticationMethodClientCertificate]) {
        
        TCUAPILog(@"🔐 收到客户端证书认证挑战");
        
        if ([self.sslManager isConfigured]) {
            
            NSArray *certificates = @[(__bridge id)self.sslManager.certificate];
            NSURLCredential *credential = [NSURLCredential credentialWithIdentity:self.sslManager.identity
                                                                     certificates:certificates
                                                                      persistence:NSURLCredentialPersistenceForSession];
            
            TCUAPILog(@"✅ 提供客户端证书");
            completionHandler(NSURLSessionAuthChallengeUseCredential, credential);
            
        } else {
            TCUAPILogError(@"❌ 客户端证书未配置");
            completionHandler(NSURLSessionAuthChallengeCancelAuthenticationChallenge, nil);
        }
        
        return;
    }
    
    // 3. 默认处理
    TCUAPILog(@"使用默认认证处理");
    completionHandler(NSURLSessionAuthChallengePerformDefaultHandling, nil);
}

#pragma mark - NSURLSessionTaskDelegate - Task级别SSL认证

- (void)URLSession:(NSURLSession *)session
              task:(NSURLSessionTask *)task
didReceiveChallenge:(NSURLAuthenticationChallenge *)challenge
 completionHandler:(void (^)(NSURLSessionAuthChallengeDisposition,
                            NSURLCredential * _Nullable))completionHandler {
    
    NSString *authMethod = challenge.protectionSpace.authenticationMethod;
    
    TCUAPILog(@"🔐 [Task] 收到认证挑战: %@", authMethod);
    
    // 客户端证书认证（Task级别优先处理）
    if ([authMethod isEqualToString:NSURLAuthenticationMethodClientCertificate]) {
        
        if ([self.sslManager isConfigured]) {
            
            NSArray *certificates = @[(__bridge id)self.sslManager.certificate];
            NSURLCredential *credential = [NSURLCredential credentialWithIdentity:self.sslManager.identity
                                                                     certificates:certificates
                                                                      persistence:NSURLCredentialPersistenceForSession];
            
            TCUAPILog(@"✅ [Task] 提供客户端证书");
            completionHandler(NSURLSessionAuthChallengeUseCredential, credential);
            return;
            
        } else {
            TCUAPILogError(@"❌ [Task] 客户端证书未配置");
            completionHandler(NSURLSessionAuthChallengeCancelAuthenticationChallenge, nil);
            return;
        }
    }
    
    // 其他认证挑战委托给 Session 级别处理
    [self URLSession:session didReceiveChallenge:challenge completionHandler:completionHandler];
}

#pragma mark - Helper Methods

- (NSError *)errorWithCode:(NSInteger)code message:(NSString *)message {
    return [NSError errorWithDomain:@"TCUAPIError"
                               code:code
                           userInfo:@{NSLocalizedDescriptionKey: message}];
}

#pragma mark - Testing

- (void)testConnection {
    TCUAPILog(@"🧪 测试服务器连接...");
    
    NSURL *url = [NSURL URLWithString:[TCU_API_BASE_URL stringByAppendingString:@"/health"]];
    
    [self GET:url parameters:nil completion:^(id responseObject, NSError *error) {
        if (error) {
            TCUAPILogError(@"❌ 连接测试失败: %@", error);
        } else {
            TCUAPILog(@"✅ 连接测试成功: %@", responseObject);
        }
    }];
}

#pragma mark - Dealloc

- (void)dealloc {
    [self.urlSession invalidateAndCancel];
}

@end
