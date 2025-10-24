//
//  UDSQueue.h
//  CarLinkChannel
//
//  Created by 刘润泽 on 2024/9/23.
//

#import <Foundation/Foundation.h>
#import "UDSPackageHandle.h"

NS_ASSUME_NONNULL_BEGIN

@interface UDSQueue : NSObject
@property (nonatomic, strong) NSMutableArray<UdsStructured *> *queue;

+ (instancetype)sharedInstance;

- (void)enqueue:(UdsStructured *)element;
- (UdsStructured *)dequeue;
- (BOOL)isEmpty;
@end

NS_ASSUME_NONNULL_END
