//
//  FlashBlockInfo.h
//  CarLinkChannel
//
//  Created by 刘润泽 on 2024/9/23.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface FlashBlockInfo : NSObject

@property(nonatomic)uint32_t BlockStartAddr;
@property(nonatomic)uint32_t BlockLength;
@property(nonatomic)uint32_t FileStartAddr;

@property(nonatomic)uint8_t RequestDownloadFormatID;
@property(nonatomic)uint8_t FF01State;

@property(nonatomic)BOOL SecurityState;
@property(nonatomic)BOOL CheckOperationState;
@property(nonatomic)BOOL IsDefaultSessionRequired;
@property(nonatomic)BOOL SendOtherState;
@property(nonatomic)uint8_t RoutineControlState;
@property(nonatomic,strong)NSData *RoutineData;

@property(nonatomic)uint32_t FileLength;
@property(nonatomic,strong)NSData *BlockData;


@end

NS_ASSUME_NONNULL_END
