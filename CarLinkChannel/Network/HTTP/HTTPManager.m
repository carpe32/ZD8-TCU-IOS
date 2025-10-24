//
//  HTTPManager.m
//  TTS Tuning
//
//  Created by 刘润泽 on 2024/8/13.
//

#import "HTTPManager.h"
void(^result)(BOOL isAuth);
@implementation HTTPManager
-(void)sendGetWithUrl:(NSString *)url doneBlock:(datablock)completionHandler errBlock:(errblock)errorBlock{
    
    NSLog(@"发送请求的url: %@",url);
    NSURLRequest * req = [NSURLRequest requestWithURL:[NSURL URLWithString:url]];
    NSURLSession * session = [NSURLSession sharedSession];
    NSURLSessionDataTask *task = [session dataTaskWithRequest:req completionHandler:^(NSData * data,NSURLResponse * _Nullable response, NSError * _Nullable error){
        
        if(error){
            NSLog(@"请求接口url: %@ 报错: %@",url,error);
            //dispatch_async(dispatch_get_main_queue(), ^{
                errorBlock(error);
            //});
      
        }else
        {
            //dispatch_async(dispatch_get_main_queue(), ^{
                completionHandler(data);
            //});
        }
    }];
    [task resume];
}
- (void)sendJSONRequestWithURL:(NSString *)urlString
                          json:(NSDictionary *)jsonDict
                    completion:(void (^)(NSData *data, NSURLResponse *response, NSError *error))completion {

    NSURL *url = [NSURL URLWithString:urlString];
    if (!url) {
        NSLog(@"无效的 URL: %@", urlString);
        if (completion) {
            NSError *urlError = [NSError errorWithDomain:@"InvalidURL" code:-1 userInfo:@{NSLocalizedDescriptionKey: @"URL 无效"}];
            completion(nil, nil, urlError);
        }
        return;
    }

    NSError *jsonError;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:jsonDict options:0 error:&jsonError];

    if (jsonError) {
        NSLog(@"JSON 序列化失败: %@", jsonError.localizedDescription);
        if (completion) {
            completion(nil, nil, jsonError);
        }
        return;
    }

    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    request.HTTPMethod = @"POST";
    request.HTTPBody = jsonData;
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];

    NSURLSessionDataTask *task = [[NSURLSession sharedSession]
                                  dataTaskWithRequest:request
                                  completionHandler:^(NSData * _Nullable data,
                                                      NSURLResponse * _Nullable response,
                                                      NSError * _Nullable error) {
        if (completion) {
            completion(data, response, error);
        }
    }];

    [task resume];
}


+ (void) requestLocalNetworkAuthorization:(void(^)(BOOL isAuth)) complete {
    result = complete;
    if(@available(iOS 14, *)) {
        
        //IOS14需要进行本地网络授权
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            
            const char* strc = "_TTSLinkChannel";
            DNSServiceRef serviceRef = nil;
            DNSServiceBrowse( &serviceRef, 0, 0, strc, nil, browseReply, nil);
            // serviceRef 为 nil 时，是允许访问出现的
            if(serviceRef == nil){
                result(YES);
            }else{
                DNSServiceProcessResult(serviceRef);
                DNSServiceRefDeallocate(serviceRef);
            }
        });
    }
    else {
        //IOS14以下默认返回yes,因为IOS14以下设备默认开启本地网络权限
        complete(YES);
    }
    
}
#pragma mark 判断本地网络权限
static void browseReply( DNSServiceRef sdRef, DNSServiceFlags flags, uint32_t interfaceIndex, DNSServiceErrorType errorCode, const char *serviceName, const char *regtype, const char *replyDomain, void *context )

{
    
    if (errorCode == kDNSServiceErr_PolicyDenied) {
        //本地网络权限未开启
        result(NO);
    }
    else {
        
        //本地网络权限已开启
        result(YES);
    }
    
}

@end
