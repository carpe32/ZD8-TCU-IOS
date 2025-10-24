//
//  TcpInstallHandleDelegate.h
//  CarLinkChannel
//
//  Created by job on 2023/4/21.
//

#ifndef TcpInstallHandleDelegate_h
#define TcpInstallHandleDelegate_h
@protocol TcpInstallHandleDelegate <NSObject>

// 第1.2.3.5分支使用这个方法
-(BOOL)sendInstallControllerPacket:(NSString *)packet;
-(BOOL)sendInstallBinaryPacket:(NSString *)packet;
// 第4分支使用这个方法发送tcp控制指令
-(BOOL)Sero4sendInstallControllerPacket:(NSString *)packet;
@end

#endif /* TcpInstallHandleDelegate_h */
