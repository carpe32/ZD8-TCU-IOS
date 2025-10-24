//
//  HttpClient.h
//  CarLinkChannel
//
//  Created by job on 2023/3/28.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef  void(^datablock)(id data);
typedef  void(^errblock)(NSError * error);

@interface HttpClient : NSObject

-(void)sendGetWithUrl:(NSString *)url doneBlock:(datablock)completionHandler errBlock:(errblock)errorBlock;

@end

NS_ASSUME_NONNULL_END
