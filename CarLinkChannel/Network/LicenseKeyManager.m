//
//  HTTPManager.m
//  TTS Tuning
//
//  Created by 刘润泽 on 2024/8/13.
//

#import "LicenseKeyManager.h"
@interface LicenseKeyManager()

@property(nonatomic, strong) HTTPManager *httpManager;


@end
@implementation LicenseKeyManager

- (instancetype)init {
    self = [super init];
    if (self) {
        self.httpManager = [[HTTPManager alloc] init];
    }
    return self;
}

-(int)checkVehicleActivationStatusWithVIN:(NSString *)Vin{
    __block int ResultState;
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
    [self checkVin:Vin isValid:^(int result){
        ResultState = result;
        dispatch_semaphore_signal(semaphore); // 发送信号量，解除阻塞
    } withError:^(NSError * error){

        dispatch_semaphore_signal(semaphore); // 发送信号量，解除阻塞
    }];
    dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
    
    return ResultState;
}

-(BOOL)RegisterBinName:(NSString *)Vin FileName:(NSString *)BinName error:(NSError **)outError timeout:(NSTimeInterval)timeoutSeconds{

    __block BOOL success = NO;
    __block NSError *resultError = nil;
    __block NSString *resultStr = nil;

    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
    NSDictionary *Registerjson = @{
        @"Vin": Vin,
        @"DownloadName": BinName
    };
    
    [self.httpManager sendJSONRequestWithURL:RegisterVinBin json:Registerjson completion:^(NSData *data, NSURLResponse *response, NSError *error) {
        if (error) {
            resultError = error;
        } else {
            NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
            if (httpResponse.statusCode == 200) {
                resultStr = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
                success = YES;
            } else {
                resultError = [NSError errorWithDomain:@"HTTPError"
                                                  code:httpResponse.statusCode
                                              userInfo:@{NSLocalizedDescriptionKey: [NSString stringWithFormat:@"HTTP 状态码: %ld", (long)httpResponse.statusCode]}];
            }
        }
        dispatch_semaphore_signal(semaphore);
    }];
    
    // 等待带超时控制
    dispatch_time_t timeout = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(timeoutSeconds * NSEC_PER_SEC));
    long waitResult = dispatch_semaphore_wait(semaphore, timeout);

    if (waitResult != 0) {
        // 超时
        if (outError) {
            *outError = [NSError errorWithDomain:@"RequestTimeout" code:-1001 userInfo:@{NSLocalizedDescriptionKey: @"请求超时"}];
        }
        return NO;
    }

    if (outError && resultError) {
        *outError = resultError;
    }

    return success;
}

//-(void)checkVin:(NSString *)vin isValid:(void(^)(Boolean result))resultBlock withError:(void(^)(NSError* error))errorBlock {
//    
//    NSString * url = [NSString stringWithFormat:@"%@%@",Content_Vin,vin];
//    NSLog(@"检查激活的url: %@",url);
//    [self.httpManager sendGetWithUrl:url doneBlock:^(NSData * data){
//        NSString *ServerResult = [XmlProcess deserializeIsValidDataFromXML:data];
//        
//        NSError *error = nil;
//
//        // 创建正则表达式对象，模式匹配数字字符串
//        NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"\\d+" options:0 error:&error];
//
//        if (error) {
//            NSLog(@"Error creating regular expression: %@", error.localizedDescription);
//        } else {
//            // 执行匹配操作
//            NSArray<NSTextCheckingResult *> *matches = [regex matchesInString:ServerResult options:0 range:NSMakeRange(0, ServerResult.length)];
//            
//            if(matches.count == 0)
//                resultBlock(NO);
//            else
//                resultBlock(YES);
//            
//        }
//        
//        } errBlock:^(NSError * error){
//                errorBlock(error);
//        
//        }];
//    
//}

-(void)checkVin:(NSString *)vin isValid:(void(^)(int result))resultBlock withError:(void(^)(NSError* error))errorBlock {
    
    NSString * url = [NSString stringWithFormat:@"%@%@",Content_Vin,vin];
    NSLog(@"检查激活的url: %@",url);
    [self.httpManager sendGetWithUrl:url doneBlock:^(NSData * data){
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
            resultBlock(0);
            return;
        }
        if(startRange.length == 0 || endRange.length == 0){
            resultBlock(0);
            return;
        }
        
        NSString * consString = [dataString substringWithRange:NSMakeRange(startRange.location + startRange.length, endRange.location - startRange.location - startRange.length)];
        if(consString.length <= 0){
            resultBlock(0);
            return;
        }
        // 2.再用cons 去接口查询是否已经激活
        NSLog(@"检查激活码: %@",consString);
        
        NSString * validurl = [NSString stringWithFormat:@"%@%@&vin=%@",Valid_Vin,consString,vin];
        [self.httpManager sendGetWithUrl:validurl doneBlock:^(NSData * data){
            
            NSString *SureFlag = [XmlProcess valueForElement:@"Content" inNewsFromXMLData:data];
            if([SureFlag isEqual:@"success"])
                resultBlock(1);
            else
                resultBlock(2);


        } errBlock:^(NSError * error){
            errorBlock(error);
        }];
        
        
    } errBlock:^(NSError * error){
        errorBlock(error);
        
    }];
    
}


-(void)ValidWithVin:(NSString *)vin Code:(NSString *)code returnBlock:(void(^)(NSString *result))resultBlock withError:(void(^)(NSError* error))errorBlock {
    
    NSString * url = [NSString stringWithFormat:@"%@%@&vin=%@",ValidWithCode,code,vin];
    [self.httpManager sendGetWithUrl:url doneBlock:^(NSData * data){
        resultBlock([XmlProcess deserializeIsValidDataFromXML:data]);
         } errBlock:^(NSError * error){
             errorBlock(error);
        }];
    
}
-(void)getListFileDoneBlock:(void(^)(NSString *liststring))resultBlock withError:(void(^)(NSError *error))errorBlock{
    
    NSString * listUrl = GetList;
    [self.httpManager sendGetWithUrl:listUrl doneBlock:^(NSData * data){
        NSString * listString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        listString = [listString stringByReplacingOccurrencesOfString:@"," withString:@""];
        listString = [listString stringByReplacingOccurrencesOfString:@"\r" withString:@""];
        listString = [listString stringByReplacingOccurrencesOfString:@"\n" withString:@""];
        listString = [listString stringByReplacingOccurrencesOfString:@"amp;" withString:@""];
        listString = [listString stringByReplacingOccurrencesOfString:@" " withString:@""];
        //NSLog(@"原始的listString: %@",listString);
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

-(void)getanquansuanfabtld:(NSString *)btldValue parmarsvar3:(NSString *)var3 doneBlock:(void(^)(NSData *anquan))resultBlock withError:(void(^)(NSError *error))errorBlock{
    
    NSString * anquanUrl = [NSString stringWithFormat:@"%@&var2=%@&var3=%@",anquan_suanfa_url,btldValue,var3];
    NSLog(@"安全算法url: %@",anquanUrl);
    [self.httpManager sendGetWithUrl:anquanUrl doneBlock:^(NSData * data){
        NSString * dataString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        
        NSLog(@"%@",dataString);
        
        dataString = [dataString stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        NSArray *hexComponents = [dataString componentsSeparatedByString:@","];
        
        NSMutableData *Hexdata = [NSMutableData dataWithCapacity:hexComponents.count];
        for (NSString *hexComponent in hexComponents) {
            unsigned int byteValue;
            [[NSScanner scannerWithString:hexComponent] scanHexInt:&byteValue];
            uint8_t byte = (uint8_t)byteValue;
            [Hexdata appendBytes:&byte length:sizeof(uint8_t)];
        }
        resultBlock(Hexdata);
        } errBlock:^(NSError * error){
            errorBlock(error);
    }];
    
}
@end
