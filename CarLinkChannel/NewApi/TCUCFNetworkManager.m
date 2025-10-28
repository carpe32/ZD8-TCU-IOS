//
//  TCUCFNetworkManager.m
//  ZD8-TCU
//

#import "TCUCFNetworkManager.h"

@interface TCUCFNetworkManager ()

@property (nonatomic, assign) SecIdentityRef clientIdentity;
@property (nonatomic, assign) SecCertificateRef clientCertificate;

@end

@implementation TCUCFNetworkManager

+ (instancetype)sharedManager {
    static TCUCFNetworkManager *instance = nil;
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
    }
    return self;
}

- (BOOL)setupSSLWithCertName:(NSString *)certName password:(NSString *)password {
    
    NSLog(@"[CFNetwork] 🔐 配置SSL证书: %@", certName);
    
    NSString *certPath = [[NSBundle mainBundle] pathForResource:certName ofType:@"p12"];
    if (!certPath) {
        NSLog(@"[CFNetwork] ❌ 证书文件未找到");
        return NO;
    }
    
    NSData *certData = [NSData dataWithContentsOfFile:certPath];
    if (!certData) {
        NSLog(@"[CFNetwork] ❌ 无法读取证书文件");
        return NO;
    }
    
    NSDictionary *options = @{(__bridge id)kSecImportExportPassphrase: password};
    CFArrayRef items = NULL;
    OSStatus status = SecPKCS12Import((__bridge CFDataRef)certData,
                                     (__bridge CFDictionaryRef)options,
                                     &items);
    
    if (status != errSecSuccess || !items) {
        NSLog(@"[CFNetwork] ❌ 证书导入失败: %d", (int)status);
        return NO;
    }
    
    NSDictionary *firstItem = (__bridge NSDictionary *)CFArrayGetValueAtIndex(items, 0);
    SecIdentityRef identity = (__bridge SecIdentityRef)firstItem[(NSString *)kSecImportItemIdentity];
    
    if (identity) {
        CFRetain(identity);
        if (_clientIdentity) CFRelease(_clientIdentity);
        _clientIdentity = identity;
    }
    
    SecCertificateRef cert = NULL;
    if (identity) {
        OSStatus certStatus = SecIdentityCopyCertificate(identity, &cert);
        if (certStatus == errSecSuccess && cert) {
            if (_clientCertificate) CFRelease(_clientCertificate);
            _clientCertificate = cert;
        }
    }
    
    CFRelease(items);
    
    if (!_clientIdentity || !_clientCertificate) {
        NSLog(@"[CFNetwork] ❌ 无法提取证书数据");
        return NO;
    }
    
    CFStringRef summary = SecCertificateCopySubjectSummary(_clientCertificate);
    NSLog(@"[CFNetwork] ✅ 证书加载成功: %@", (__bridge NSString *)summary);
    if (summary) CFRelease(summary);
    
    return YES;
}

- (void)POST:(NSString *)url
  parameters:(NSDictionary *)parameters
  completion:(void(^)(id _Nullable, NSError * _Nullable))completion {
    
    NSLog(@"[CFNetwork] 📤 POST: %@", url);
    
    // 在后台线程执行网络请求
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        
        // 序列化JSON
        NSError *jsonError = nil;
        NSData *jsonData = [NSJSONSerialization dataWithJSONObject:parameters
                                                           options:NSJSONWritingPrettyPrinted
                                                             error:&jsonError];
        if (jsonError) {
            dispatch_async(dispatch_get_main_queue(), ^{
                if (completion) completion(nil, jsonError);
            });
            return;
        }
        
        NSString *jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
        NSLog(@"[CFNetwork] 📄 请求体:\n%@", jsonString);
        
        // 创建HTTP请求
        NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:url]];
        request.HTTPMethod = @"POST";
        request.HTTPBody = jsonData;
        [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
        [request setValue:@"application/json" forHTTPHeaderField:@"Accept"];
        request.timeoutInterval = 30.0;
        
        // ✅ 创建自定义URLSession配置
        NSURLSessionConfiguration *config = [NSURLSessionConfiguration ephemeralSessionConfiguration];
        config.timeoutIntervalForRequest = 30.0;
        config.timeoutIntervalForResource = 60.0;
        
        // ✅ 关键：配置底层连接属性，强制使用客户端证书
        config.connectionProxyDictionary = @{
            (__bridge NSString *)kCFStreamPropertySSLSettings: @{
                (__bridge NSString *)kCFStreamSSLCertificates: @[(__bridge id)self.clientIdentity],
                (__bridge NSString *)kCFStreamSSLIsServer: @NO,
                (__bridge NSString *)kCFStreamSSLValidatesCertificateChain: @NO
            }
        };
        
        // 创建临时Session用于这次请求
        __block NSURLSession *session = [NSURLSession sessionWithConfiguration:config
                                                                       delegate:nil
                                                                  delegateQueue:nil];
        
        NSLog(@"[CFNetwork] 🚀 开始请求（使用底层证书配置）");
        
        // 发送同步请求
        dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
        __block id resultObject = nil;
        __block NSError *resultError = nil;
        
        NSURLSessionDataTask *task = [session dataTaskWithRequest:request
                                                 completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
            
            if (error) {
                NSLog(@"[CFNetwork] ❌ 请求失败: %@", error);
                resultError = error;
            } else {
                NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
                NSLog(@"[CFNetwork] ✅ HTTP %ld", (long)httpResponse.statusCode);
                NSLog(@"[CFNetwork] 📥 响应头: %@", httpResponse.allHeaderFields);
                
                if (data && data.length > 0) {
                    NSError *parseError = nil;
                    id json = [NSJSONSerialization JSONObjectWithData:data options:0 error:&parseError];
                    
                    if (parseError) {
                        NSString *rawResponse = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
                        NSLog(@"[CFNetwork] ⚠️ JSON解析失败，原始响应:\n%@", rawResponse);
                        resultObject = rawResponse;
                    } else {
                        NSLog(@"[CFNetwork] 📥 响应内容: %@", json);
                        resultObject = json;
                    }
                } else {
                    NSLog(@"[CFNetwork] ℹ️ 响应无内容");
                    resultObject = @{@"status": @"success"};
                }
            }
            
            dispatch_semaphore_signal(semaphore);
        }];
        
        [task resume];
        
        // 等待请求完成
        dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
        
        // 清理
        [session finishTasksAndInvalidate];
        
        // 回调主线程
        dispatch_async(dispatch_get_main_queue(), ^{
            if (completion) {
                completion(resultObject, resultError);
            }
        });
    });
}

- (void)dealloc {
    if (_clientIdentity) CFRelease(_clientIdentity);
    if (_clientCertificate) CFRelease(_clientCertificate);
}

@end
