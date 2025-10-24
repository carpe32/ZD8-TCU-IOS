//
//  TcpInstallHandler.h
//  CarLinkChannel
//
//  Created by job on 2023/4/7.
//

#import <Foundation/Foundation.h>
#import "TcpInstallHandleDelegate.h"


//@protocol TcpInstallHandleDelegate <NSObject>
//
//-(BOOL)sendInstallControllerPacket:(NSString *)packet;
//-(BOOL)sendInstallBinaryPacket:(NSString *)packet;
//@end

@interface TcpInstallSero1Handler : NSObject

@property (nonatomic,weak) id<TcpInstallHandleDelegate> delegate;
@property (nonatomic,strong) NSString * btldValue;
@property (nonatomic,strong) NSString * vinString;

-(void)testLoadFile;
-(void)receiveanquanvalue:(NSString *)anquan;

-(void)RecoveryCAFD:(NSString *)parmars cafdPath:(NSString *)cafdPath;
-(void)LoadFileWithPath:(NSString *) path cafdPath:(NSString *)cafdPath;
@end

