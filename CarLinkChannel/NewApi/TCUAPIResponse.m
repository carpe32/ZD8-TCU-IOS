//
//  TCUAPIResponse.m
//  ZD8-TCU API响应模型实现
//
//  Created on 2025/10/24.
//

#import "TCUAPIResponse.h"

@implementation TCUAPIResponse

+ (instancetype)responseWithDictionary:(NSDictionary *)dict {
    TCUAPIResponse *response = [[self alloc] init];
    response.success = [dict[@"success"] boolValue];
    response.message = dict[@"message"] ?: @"";
    response.data = dict[@"data"];
    response.errorCode = [dict[@"errorCode"] integerValue];
    response.timestamp = dict[@"timestamp"];
    return response;
}

- (BOOL)isSuccess {
    return self.success;
}

- (NSString *)description {
    return [NSString stringWithFormat:@"<TCUAPIResponse success=%@ errorCode=%ld message=%@>",
            self.success ? @"YES" : @"NO",
            (long)self.errorCode,
            self.message];
}

@end

// ==================== TCUFolderInfo ====================

@implementation TCUFolderInfo

+ (instancetype)folderWithDictionary:(NSDictionary *)dict {
    TCUFolderInfo *folder = [[self alloc] init];
    folder.folderName = dict[@"folderName"] ?: @"";
    folder.displayContent = dict[@"displayContent"] ?: folder.folderName;
    return folder;
}

- (NSString *)description {
    return [NSString stringWithFormat:@"<TCUFolderInfo folder=%@ display=%@>",
            self.folderName, self.displayContent];
}

@end

// ==================== TCUFileListResponse ====================

@implementation TCUFileListResponse

+ (instancetype)responseWithDictionary:(NSDictionary *)dict {
    TCUFileListResponse *response = [[self alloc] init];
    response.success = [dict[@"success"] boolValue];
    response.message = dict[@"message"] ?: @"";
    response.errorCode = [dict[@"errorCode"] integerValue];
    response.timestamp = dict[@"timestamp"];
    
    // 解析folders数组
    NSDictionary *data = dict[@"data"];
    if ([data isKindOfClass:[NSDictionary class]]) {
        NSArray *foldersArray = data[@"folders"];
        if ([foldersArray isKindOfClass:[NSArray class]]) {
            NSMutableArray *folders = [NSMutableArray array];
            for (NSDictionary *folderDict in foldersArray) {
                TCUFolderInfo *folder = [TCUFolderInfo folderWithDictionary:folderDict];
                [folders addObject:folder];
            }
            response.folders = [folders copy];
        }
        response.totalCount = [data[@"totalCount"] integerValue];
    }
    
    return response;
}

@end

// ==================== TCULicenseValidateResponse ====================

@implementation TCULicenseValidateResponse

+ (instancetype)responseWithDictionary:(NSDictionary *)dict {
    TCULicenseValidateResponse *response = [[self alloc] init];
    response.success = [dict[@"success"] boolValue];
    response.message = dict[@"message"] ?: @"";
    response.errorCode = [dict[@"errorCode"] integerValue];
    response.timestamp = dict[@"timestamp"];
    
    // 解析data字段
    NSDictionary *data = dict[@"data"];
    if ([data isKindOfClass:[NSDictionary class]]) {
        response.isActivated = [data[@"isActivated"] boolValue];
        response.activatedAt = data[@"activatedAt"];
        response.expiresAt = data[@"expiresAt"];
        response.remainingActivations = [data[@"remainingActivations"] integerValue];
        response.boundHwid = data[@"boundHwid"];
    }
    
    return response;
}

@end
