//
//  LuaInvoke.h
//  CarLinkChannel
//
//  Created by job on 2023/3/24.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface LuaInvoke : NSObject


-(NSString *)parseEcuWithHexString:(NSString *)hexString;
@end

NS_ASSUME_NONNULL_END
