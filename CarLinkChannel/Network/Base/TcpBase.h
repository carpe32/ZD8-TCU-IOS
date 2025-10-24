//
//  TcpBase.h
//  CarLinkChannel
//
//  Created by 刘润泽 on 2024/9/23.
//

#import <Foundation/Foundation.h>
#import "GCDAsyncSocket.h"

NS_ASSUME_NONNULL_BEGIN

@protocol TcpHandleNotification <NSObject>

@optional
-(void)ConnectSuccess;
-(void)RecDataListen:(NSData*)data;

@end


@interface TcpBase : NSObject
-(void)Connect:(NSString*)ip Port:(NSString*)port delegateQue:(const char*)dQue socketQue:(const char*)sQue;
-(void)SendData:(NSData *)data;
@property (weak, nonatomic) id<TcpHandleNotification> delegate;
@end

NS_ASSUME_NONNULL_END
