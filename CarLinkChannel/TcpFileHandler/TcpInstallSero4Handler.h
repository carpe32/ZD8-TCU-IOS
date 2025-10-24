//
//  TcpInstallSero4handler.h
//  CarLinkChannel
//
//  Created by job on 2023/4/21.
//

#import <Foundation/Foundation.h>
#import "TcpInstallHandleDelegate.h"
NS_ASSUME_NONNULL_BEGIN

@interface TcpInstallSero4Handler : NSObject
@property (nonatomic,weak) id<TcpInstallHandleDelegate> delegate;
@property (nonatomic,strong) NSString * btldValue;
@property (nonatomic,strong) NSString * vinString;

-(void)receiveanquanvalue:(NSString *)anquan;
-(void)LoadFileWithPath:(NSString *) path cafdPath:(NSString *)cafdPath;
@end

NS_ASSUME_NONNULL_END
