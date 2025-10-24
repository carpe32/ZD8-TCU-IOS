//
//  TcpParserHandler.h
//  CarLinkChannel
//
//  Created by job on 2023/3/23.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface TcpParserHandler : NSObject

- (NSString *) tceReceiveData:(NSData *)data;
@end

NS_ASSUME_NONNULL_END
