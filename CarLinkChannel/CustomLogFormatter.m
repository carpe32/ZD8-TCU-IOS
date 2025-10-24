//
//  CustomLogFormatter.m
//  CarLinkChannel
//
//  Created by 刘润泽 on 2025/4/16.
//

#import "CustomLogFormatter.h"

@interface CustomLogFormatter ()
@property (nonatomic, strong) NSDateFormatter *dateFormatter;
@end

@implementation CustomLogFormatter

- (instancetype)init {
    if (self = [super init]) {
        _dateFormatter = [[NSDateFormatter alloc] init];
        _dateFormatter.dateFormat = @"yyyy-MM-dd HH:mm:ss";
        _dateFormatter.timeZone = [NSTimeZone localTimeZone]; // 自动使用设备所在的时区
    }
    return self;
}

- (NSString *)formatLogMessage:(DDLogMessage *)logMessage {
    NSString *timestamp = [self.dateFormatter stringFromDate:logMessage.timestamp];
    NSString *logLevel;

    switch (logMessage.flag) {
        case DDLogFlagError:   logLevel = @"ERROR"; break;
        case DDLogFlagWarning: logLevel = @"WARN"; break;
        case DDLogFlagInfo:    logLevel = @"INFO"; break;
        case DDLogFlagDebug:   logLevel = @"DEBUG"; break;
        case DDLogFlagVerbose: logLevel = @"VERBOSE"; break;
        default:               logLevel = @"LOG"; break;
    }

    return [NSString stringWithFormat:@"%@ [%@] %@",
            timestamp, logLevel, logMessage.message];
}

@end
