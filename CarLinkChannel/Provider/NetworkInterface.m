//
//  NetworkInterface.m
//  CarLinkChannel
//
//  Created by job on 2023/3/29.
//

#import "NetworkInterface.h"


HttpClient * client;
NetworkInterface * interface;

@interface NetworkInterface()

@end

@implementation NetworkInterface

+(NetworkInterface*)getInterface {
    if(client == nil){
        client = [[HttpClient alloc] init];
    }
    if(interface == nil){
        interface = [[NetworkInterface alloc] init];
    }
    return interface;
}
-(void)checkVin:(NSString *)vin isValid:(void(^)(Boolean result))resultBlock withError:(void(^)(NSError* error))errorBlock {
    
    NSString * url = [NSString stringWithFormat:@"%@%@",Content_Vin,vin];
    NSLog(@"检查激活的url: %@",url);
    [client sendGetWithUrl:url doneBlock:^(NSData * data){
        // 1.首先拿到cons
        NSString * dataString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        
        NSLog(@"检查激活码接口得到的字符串: %@",dataString);
        dataString =[dataString stringByReplacingOccurrencesOfString:@" " withString:@""];
        dataString = [dataString stringByReplacingOccurrencesOfString:@"\r" withString:@""];
        dataString = [dataString stringByReplacingOccurrencesOfString:@"\n" withString:@""];
        NSString * startStr = @"<Content>";
        NSString * endStr = @"</Content>";
        NSRange startRange = [dataString rangeOfString:startStr];
        NSRange endRange = [dataString rangeOfString:endStr];
        if(startRange.location == -1 || endRange.location == -1){
            resultBlock(NO);
            return;
        }
        if(startRange.length == 0 || endRange.length == 0){
            resultBlock(NO);
            return;
        }
        
        NSString * consString = [dataString substringWithRange:NSMakeRange(startRange.location + startRange.length, endRange.location - startRange.location - startRange.length)];
        if(consString.length <= 0){
            resultBlock(NO);
            return;
        }
        // 2.再用cons 去接口查询是否已经激活
        NSLog(@"检查激活码: %@",consString);
        
        NSString * validurl = [NSString stringWithFormat:@"%@%@&vin=%@",Valid_Vin,consString,vin];
        [client sendGetWithUrl:validurl doneBlock:^(NSData * data){
            NSString * statusstr = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
            NSLog(@"用激活码检查是否激活得到的字符串: %@",statusstr);
            statusstr =[statusstr stringByReplacingOccurrencesOfString:@" " withString:@""];
            statusstr = [statusstr stringByReplacingOccurrencesOfString:@"\r" withString:@""];
            statusstr = [statusstr stringByReplacingOccurrencesOfString:@"\n" withString:@""];
            NSString * ssStr = @"<Content>";
            NSString * stStr = @"</Content>";
            NSRange ssRange = [statusstr rangeOfString:ssStr];
            NSRange stRange = [statusstr rangeOfString:stStr];
            if(startRange.location == -1 || endRange.location == -1){
                resultBlock(NO);
                return;
            }
            
            if(ssRange.length == 0 || stRange.length == 0){
                resultBlock(NO);
                return;
            }
            NSString * consString = [statusstr substringWithRange:NSMakeRange(ssRange.location + ssRange.length, stRange.location - ssRange.location - ssRange.length)];
            if([consString isEqualToString:@"success"]){
                resultBlock(YES);
            }else{
                resultBlock(NO);
            }
        } errBlock:^(NSError * error){
            errorBlock(error);
        }];
        
        
    } errBlock:^(NSError * error){
        errorBlock(error);
        
    }];
    
}

-(void)ValidWithVin:(NSString *)vin Code:(NSString *)code returnBlock:(void(^)(Boolean result))resultBlock withError:(void(^)(NSError* error))errorBlock {
    
    NSString * url = [NSString stringWithFormat:@"%@%@&vin=%@",ValidWithCode,code,vin];
    [client sendGetWithUrl:url doneBlock:^(NSData * data){
        NSString * dataString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        dataString =[dataString stringByReplacingOccurrencesOfString:@" " withString:@""];
        dataString = [dataString stringByReplacingOccurrencesOfString:@"\r" withString:@""];
        dataString = [dataString stringByReplacingOccurrencesOfString:@"\n" withString:@""];
        NSString * startStr = @"<Content>";
        NSString * endStr = @"</Content>";
        NSLog(@"收到的激活字符串: %@",dataString);
        NSRange startRange = [dataString rangeOfString:startStr];
        NSRange endRange = [dataString rangeOfString:endStr];
        if(startRange.location == -1 || endRange.location == -1){
            resultBlock(NO);
            return;
        }
        if(startRange.length == 0 || endRange.length == 0){
            resultBlock(NO);
            return;
        }
        NSString * consString = [dataString substringWithRange:NSMakeRange(startRange.location + startRange.length, endRange.location - startRange.location - startRange.length)];
        
        if([consString isEqualToString:@"success"]){
            resultBlock(YES);
        }else{
            resultBlock(NO);
        }
        
    } errBlock:^(NSError * error){
        
        errorBlock(error);
    }];
    
}


-(void)getanquansuanfabtld:(NSString *)btldValue parmarsvar3:(NSString *)var3 doneBlock:(void(^)(NSString *anquan))resultBlock withError:(void(^)(NSError *error))errorBlock{
    
    NSString * anquanUrl = [NSString stringWithFormat:@"%@&var2=%@&var3=%@",anquan_suanfa_url,btldValue,var3];
    NSLog(@"安全算法url: %@",anquanUrl);
    [client sendGetWithUrl:anquanUrl doneBlock:^(NSData * data){
        NSString * dataString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        dataString = [dataString stringByReplacingOccurrencesOfString:@"," withString:@""];
        dataString = [dataString stringByReplacingOccurrencesOfString:@"\r" withString:@""];
        dataString = [dataString stringByReplacingOccurrencesOfString:@"\n" withString:@""];
        resultBlock(dataString);
    } errBlock:^(NSError * error){
        errorBlock(error);
    }];
    
}


-(void)getListFileDoneBlock:(void(^)(NSString *liststring))resultBlock withError:(void(^)(NSError *error))errorBlock{
    
    
    NSString * listUrl = GetList;
    [client sendGetWithUrl:listUrl doneBlock:^(NSData * data){
        NSString * listString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        listString = [listString stringByReplacingOccurrencesOfString:@"," withString:@""];
        listString = [listString stringByReplacingOccurrencesOfString:@"\r" withString:@""];
        listString = [listString stringByReplacingOccurrencesOfString:@"\n" withString:@""];
        listString = [listString stringByReplacingOccurrencesOfString:@"amp;" withString:@""];
        listString = [listString stringByReplacingOccurrencesOfString:@" " withString:@""];
        NSLog(@"原始的listString: %@",listString);
        NSString * startStr = @"<Content>";
        NSString * endStr = @"</Content>";
        NSRange startRange = [listString rangeOfString:startStr];
        NSRange endRange = [listString rangeOfString:endStr];
        if(startRange.location == -1 || endRange.location == -1){
            errorBlock([[NSError alloc] init]);
            return;
        }
        if(startRange.length == 0 || endRange.length == 0){
            errorBlock([[NSError alloc] init]);
            return;
        }
        NSString * consString = [listString substringWithRange:NSMakeRange(startRange.location + startRange.length, endRange.location - startRange.location - startRange.length)];
        if(consString.length == 0){
            errorBlock([[NSError alloc] init]);
            return;
        }
        resultBlock(consString);
    } errBlock:^(NSError * error){
        errorBlock(error);
    }];
    
    
}

-(void)getUpdateBinFile:(NSString *)vin requestBlock:(void(^)(NSString * result))resultBlock withError:(void(^)(NSError * error))errorBlock{
    
    NSString * updateBinFile = [NSString stringWithFormat:@"%@%@",GetBinNew,vin];
    [client sendGetWithUrl:updateBinFile doneBlock:^(NSData * data){
        NSString * listString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        listString = [listString stringByReplacingOccurrencesOfString:@"," withString:@""];
        listString = [listString stringByReplacingOccurrencesOfString:@"\r" withString:@""];
        listString = [listString stringByReplacingOccurrencesOfString:@"\n" withString:@""];
        listString = [listString stringByReplacingOccurrencesOfString:@"amp;" withString:@""];
        listString = [listString stringByReplacingOccurrencesOfString:@"#" withString:@""];
        NSString * startStr = @"<Content>";
        NSString * endStr = @"</Content>";
        NSRange startRange = [listString rangeOfString:startStr];
        NSRange endRange = [listString rangeOfString:endStr];
        if(startRange.location == -1 || endRange.location == -1){
            errorBlock([[NSError alloc] init]);
            return;
        }
        if(startRange.length == 0 || endRange.length == 0){
            errorBlock([[NSError alloc] init]);
            return;
        }
        NSString * consString = [listString substringWithRange:NSMakeRange(startRange.location + startRange.length, endRange.location - startRange.location - startRange.length)];
        if([consString isEqualToString:UPDATE_FILE_NO_FILE]){
            resultBlock(@"");
        }else{
            resultBlock(consString);
        }
        
    } errBlock:^(NSError * error){
        errorBlock(error);
    }];
}

-(void)RegisterFileNameFormVin:(NSString *)Vin DownloadFileName:(NSString *)FileName {
        // 请求的 URL
        NSString *urlString = @"http://82.157.7.102:8004/api/Register";
 //       NSString *urlString = @"http://43.135.148.212:8004/api/Register";
        NSURL *url = [NSURL URLWithString:urlString];
        
        // 创建请求对象
        NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
        [request setHTTPMethod:@"POST"]; // 设置为 POST 请求
        
        // 设置请求体
        NSDictionary *parameters = @{
            @"vin": Vin,
            @"DownloadName": FileName
        };
        NSError *jsonError;
        NSData *bodyData = [NSJSONSerialization dataWithJSONObject:parameters options:0 error:&jsonError];
        
        if (jsonError) {
            NSLog(@"JSON序列化失败: %@", jsonError);
            return ;
        }
        
        [request setHTTPBody:bodyData];
        
        // 设置请求头
        [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
        
        // 创建信号量
        dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
        
        __block NSData *responseData = nil;
        __block NSError *responseError = nil;
        __block NSURLResponse *urlResponse = nil;
        
        // 使用 NSURLSessionDataTask 发起请求
        NSURLSessionDataTask *task = [[NSURLSession sharedSession] dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
            responseData = data;
            urlResponse = response;
            responseError = error;
            
            // 请求完成后释放信号量
            dispatch_semaphore_signal(semaphore);
        }];
        
        [task resume];
        
        // 等待请求完成
        dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
        
        // 处理响应
        if (responseError) {
            NSLog(@"请求失败: %@", responseError);
        } else {
            NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)urlResponse;
            if (httpResponse.statusCode == 200) {
                NSDictionary *responseDict = [NSJSONSerialization JSONObjectWithData:responseData options:0 error:nil];
                NSLog(@"请求成功，响应数据: %@", responseDict);
            } else {
                NSLog(@"请求失败，状态码: %ld", (long)httpResponse.statusCode);
            }
        }

}

@end
