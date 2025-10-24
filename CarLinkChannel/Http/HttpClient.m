//
//  HttpClient.m
//  CarLinkChannel
//
//  Created by job on 2023/3/28.
//

#import "HttpClient.h"

@implementation HttpClient


-(void)sendGetWithUrl:(NSString *)url doneBlock:(datablock)completionHandler errBlock:(errblock)errorBlock{
    
    NSLog(@"发送请求的url: %@",url);
    NSURLRequest * req = [NSURLRequest requestWithURL:[NSURL URLWithString:url]];
    NSURLSession * session = [NSURLSession sharedSession];
    NSURLSessionDataTask *task = [session dataTaskWithRequest:req completionHandler:^(NSData * data,NSURLResponse * _Nullable response, NSError * _Nullable error){
        
        if(error){
            NSLog(@"请求接口url: %@ 报错: %@",url,error);
            dispatch_async(dispatch_get_main_queue(), ^{
                errorBlock(error);
            });
      
        }else
        {
            dispatch_async(dispatch_get_main_queue(), ^{
//                id jsonData = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error:nil];
                completionHandler(data);
            });
        }
        
    }];
    [task resume];
    
}
@end
