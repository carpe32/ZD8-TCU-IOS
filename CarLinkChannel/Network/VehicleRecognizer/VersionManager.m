//
//  VersionManager.m
//  CarLinkChannel
//
//  Created by 刘润泽 on 2025/4/22.
//

#import "VersionManager.h"

@implementation VersionManager
+ (instancetype)sharedInstance {
    static VersionManager *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[VersionManager alloc] init];
    });
    return sharedInstance;
}

-(bool)isNeedFlashBase:(NSArray *)svt{

    bool BaseState = false;
    for(NSString *single in svt)
    {
        if([single containsString:@"UNKW"])
            BaseState = true;
    }
    return  BaseState;

}

@end
