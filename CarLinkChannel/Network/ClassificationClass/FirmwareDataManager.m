//
//  FirmwareDataManager.m
//  CarLinkChannel
//
//  Created by 刘润泽 on 2024/9/23.
//

#import "FirmwareDataManager.h"
#import "FlashBlockInfo.h"
@implementation FirmwareDataManager

-(instancetype)initWithFile:(NSString *)filePath{
    self = [super init];
    if (self) {
        NSData * file_data = [NSData dataWithContentsOfFile:filePath];
        file_data = [file_data AES256DecryptWithKey:@"Q1w2e3r4" andvi:@"Q1w2e3r4"];
        [self DataInit:file_data];
    }
    return self;
}

-(void)DataInit:(NSData *)originalData{
    const uint8_t *Databytes = [originalData bytes];
    //NSUInteger length = [originalData length];
    
    if((Databytes[0] != 0)||(Databytes[1] != 0x99))
    {
        _isValidBinFile  = false;
        return;
    }
    _isValidBinFile = true;
    
    NSData *Vindata = [NSData dataWithBytes:&Databytes[4] length:17];
    _FileVin = [[NSString alloc] initWithData:Vindata encoding:NSASCIIStringEncoding];
    
    _BtldInfo.Name = (Databytes[0x17]<<24) | (Databytes[0x18]<<16) | (Databytes[0x19]<<8) | Databytes[0x1A];
    _BtldInfo.FirstVersion =Databytes[0x1B];
    _BtldInfo.MidVersion =Databytes[0x1C];
    _BtldInfo.lastVersion =Databytes[0x1D];
    
    if(Databytes[0x21] == 0)
        _SetState1 = false;
    else
        _SetState1 = true;
    
    if(Databytes[0x22] == 0)
        _SetState2 = false;
    else
        _SetState2 = true;
    
    if(Databytes[0x23] == 0)
        _SetState3 = false;
    else
        _SetState3 = true;
    
    NSMutableArray *BlockArray = [[NSMutableArray alloc] init];
    for(int i = 0;i<14;i++)
    {
        if(Databytes[0x31 + i*0x10] == 0x01)
        {
            FlashBlockInfo *blockInfo = [[FlashBlockInfo alloc] init];
            
            blockInfo.BlockStartAddr =(Databytes[0x32 + i*0x10]<<24) | (Databytes[0x33 + i*0x10]<<16) | (Databytes[0x34 + i*0x10]<<8) | Databytes[0x35 + i*0x10];
            blockInfo.BlockLength = (Databytes[0x36 + i*0x10]<<24) | (Databytes[0x37 + i*0x10]<<16) | (Databytes[0x38 + i*0x10]<<8) | Databytes[0x39 + i*0x10];
            blockInfo.FileStartAddr = (Databytes[0x3A + i*0x10]<<24) | (Databytes[0x3B + i*0x10]<<16) | (Databytes[0x3C + i*0x10]<<8) | Databytes[0x3D + i*0x10];
            blockInfo.RequestDownloadFormatID = Databytes[0x3E + i*0x10];
            blockInfo.FF01State = Databytes[0x3F + i*0x10];
            if(Databytes[0x112 + i*0x10] == 0x11)
                blockInfo.SecurityState = true;
            else
                blockInfo.SecurityState = false;
            
            if(Databytes[0x113 + i*0x10] == 0x01)
                blockInfo.CheckOperationState = true;
            else
                blockInfo.CheckOperationState = false;
            
            if(Databytes[0x114 + i*0x10] == 0x01)
                blockInfo.IsDefaultSessionRequired = true;
            else
                blockInfo.IsDefaultSessionRequired = false;
            
            if(Databytes[0x115 + i*0x10] == 0x01)
                blockInfo.SendOtherState = true;
            else
                blockInfo.SendOtherState = false;
            
            if(Databytes[0x117 + i*0x10] == 0x01)
                blockInfo.RoutineControlState = 1;
            else if(Databytes[0x117 + i*0x10] == 0x03)
                blockInfo.RoutineControlState = 3;
            else
                blockInfo.RoutineControlState = 0;
            
//            if(blockInfo.RoutineControlState == 1)
//            {
                NSMutableData *mutableData = [NSMutableData dataWithLength:4];
                uint8_t *mutableBytes = mutableData.mutableBytes;
                mutableBytes[0] = Databytes[0x118 + i*0x10];
                mutableBytes[1] = Databytes[0x119 + i*0x10];
                mutableBytes[2] = Databytes[0x11A + i*0x10];
                mutableBytes[3] = Databytes[0x11B + i*0x10];
                blockInfo.RoutineData  =mutableData;
            //}
            
            blockInfo.FileLength = (Databytes[0x11C + i*0x10]<<24) | (Databytes[0x11D + i*0x10]<<16) | (Databytes[0x11E + i*0x10]<<8) | Databytes[0x11F + i*0x10];
            blockInfo.BlockData = [NSData dataWithBytes:(Databytes + blockInfo.FileStartAddr) length:blockInfo.FileLength];

            [BlockArray addObject:blockInfo];
        }
    }
    _BlockInfo = BlockArray;
    
    if(Databytes[0x201] == 0x01)
        _EndState1 = true;
    else
        _EndState1 = false;
    
    if(Databytes[0x202] == 0x01)
        _EndState2 = true;
    else
        _EndState2 = false;
    
    if(Databytes[0x203] == 0x01)
        _EndState3 = true;
    else
        _EndState3 = false;
    
    if(Databytes[0x204] == 0x01)
        _EndState4 = true;
    else
        _EndState4 = false;
    
    if(_EndState4 == true)
    {
        NSMutableData *mutableData = [NSMutableData dataWithLength:8];
        uint8_t *mutableBytes = mutableData.mutableBytes;
        mutableBytes[0] = Databytes[0x210];
        mutableBytes[1] = Databytes[0x211];
        mutableBytes[2] = Databytes[0x212];
        mutableBytes[3] = Databytes[0x213];
        mutableBytes[4] = Databytes[0x214];
        mutableBytes[5] = Databytes[0x215];
        mutableBytes[6] = Databytes[0x216];
        mutableBytes[7] = Databytes[0x217];
        _End4Data  =mutableData;
    }
}






@end
