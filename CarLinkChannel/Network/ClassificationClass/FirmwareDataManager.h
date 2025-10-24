//
//  FirmwareDataManager.h
//  CarLinkChannel
//
//  Created by 刘润泽 on 2024/9/23.
//

#import <Foundation/Foundation.h>
#import "NSData+Category.h"
NS_ASSUME_NONNULL_BEGIN
typedef struct {
    int Name;
    uint8_t FirstVersion;
    uint8_t MidVersion;
    uint8_t lastVersion;
} BTLDInfo;


@interface FirmwareDataManager : NSObject

-(instancetype)initWithFile:(NSString *)filePath;

@property(nonatomic,readonly)BOOL isValidBinFile;
@property(nonatomic,readonly,strong)NSString *FileVin;
@property(nonatomic,readonly)BTLDInfo BtldInfo;
@property(nonatomic,readonly)BOOL SetState1;
@property(nonatomic,readonly)BOOL SetState2;
@property(nonatomic,readonly)BOOL SetState3;
@property(nonatomic,readonly,strong)NSArray *BlockInfo;

@property(nonatomic,readonly)BOOL EndState1;
@property(nonatomic,readonly)BOOL EndState2;
@property(nonatomic,readonly)BOOL EndState3;
@property(nonatomic,readonly)BOOL EndState4;

@property(nonatomic,readonly,strong)NSData *End4Data;

@end

NS_ASSUME_NONNULL_END
