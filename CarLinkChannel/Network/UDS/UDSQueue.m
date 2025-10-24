//
//  UDSQueue.m
//  CarLinkChannel
//
//  Created by 刘润泽 on 2024/9/23.
//

#import "UDSQueue.h"

@implementation UDSQueue

+ (instancetype)sharedInstance {
    static UDSQueue *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[self alloc] init];
    });
    return sharedInstance;
}
- (instancetype)init {
    self = [super init];
    if (self) {
        _queue = [NSMutableArray array];
    }
    return self;
}

- (void)enqueue:(UdsStructured *)element {
    @synchronized (self) {
           [self.queue addObject:element];
       }
}

- (UdsStructured *)dequeue {
    @synchronized (self) {
         if ([self isEmpty]) {
             return nil; // 或者返回一个默认的空对象
         }
         UdsStructured *element = [self.queue firstObject];
         [self.queue removeObjectAtIndex:0];
         return element;
     }
}

- (BOOL)isEmpty {
    @synchronized (self) {
        return self.queue.count == 0;
    }
}

@end
