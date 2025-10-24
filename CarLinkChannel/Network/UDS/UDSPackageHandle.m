//
//  UDSPackageHandle.m
//  CarLinkChannel
//
//  Created by 刘润泽 on 2024/9/23.
//

#import "UDSPackageHandle.h"

@interface UDSPackageHandle()
{
    
}
@property (nonatomic, strong) NSMutableData *databuffer;
//@property (nonatomic, strong) UdsStructured *UdsDataQueue;
@property (nonatomic, copy) void (^dataReceivedCallback)(UdsStructured *element);
@end

@implementation UDSPackageHandle

- (instancetype)init {
    self = [super init];
    if (self) {
        _databuffer = [[NSMutableData alloc] init];
    }
    return self;
}

- (void)registerDataReceivedCallback:(void (^)(UdsStructured *element))callback {
    self.dataReceivedCallback = callback;
}

-(void)InputData:(NSData *)UdsOriginalData{
    [self.databuffer appendData:UdsOriginalData];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [self DataProcess];
    });
}

-(void)DataProcess{
    if(self.databuffer.length<4)
        return;
    
    const unsigned char *bytes = [self.databuffer bytes];
    if((bytes[0] != 0)||(bytes[1] !=0))
    {
        [self.databuffer replaceBytesInRange:NSMakeRange(0, 1) withBytes:NULL length:0];
        [self DataProcess];
        return;
    }

    int packagelength = ((bytes[2]<<8) + bytes[3]) + 6;
    if(self.databuffer.length < packagelength)
        return;
    
    uint8_t transfer = bytes[5];
    uint8_t sourceAddr = bytes[6];
    uint8_t destinationAddr = bytes[7];
    uint8_t Fid = bytes[8];
    uint8_t Sid = 0;
    if(packagelength>9)
        Sid = bytes[9];

    NSData *newData = nil;
    if(packagelength>10)
    {
        newData = [NSData dataWithBytes:bytes + 10 length:packagelength - 10];
    }

    
    UdsStructured *UdsElement = [[UdsStructured alloc] initWithTransferDirection:transfer  sourceAddress:sourceAddr destinationAddress:destinationAddr functionID:Fid subFunctionID:Sid payload:newData];
    
    if (self.databuffer.length >= packagelength) {
        [self.databuffer replaceBytesInRange:NSMakeRange(0, packagelength) withBytes:NULL length:0];
    }
     // 调用回调处理解包后的数据
     if (self.dataReceivedCallback) {
         dispatch_async(dispatch_get_main_queue(), ^{
             self.dataReceivedCallback(UdsElement);
         });
     }
     
     // 继续处理可能剩余的数据
     [self DataProcess];
}

+ (NSData *)createUDSSendPacket:(uint8_t)Destaddr Functionid:(uint8_t)Fid SubFunctionId:(NSData *)Sid parameterData:(NSData *)parameterData{
    NSMutableData *packet = [NSMutableData data];
    uint8_t PackageHead[] = {0x00, 0x00};
    [packet appendBytes:PackageHead length:2];
    NSUInteger  packageLength = 0;
    if(parameterData != nil)
    {
        packageLength = parameterData.length + 4;
    }
    else
        packageLength = 4;
    
    if(Sid == nil)
        packageLength--;
    
    uint16_t lengthField = (uint16_t)packageLength; // 加上其他字段的长度
    // 拆分长度字段为两个字节
    uint8_t lengthBytes[2];
    lengthBytes[0] = (lengthField >> 8) & 0xFF; // 高字节
    lengthBytes[1] = lengthField & 0xFF;        // 低字节

    [packet appendBytes:lengthBytes length:sizeof(lengthBytes)];
    
    // 定义要拆分的数字
    uint16_t number = 0x0001;

    // 以字节数组形式将数字添加到 NSMutableData
    uint16_t bigEndianNumber = CFSwapInt16HostToBig(number);
    [packet appendBytes:&bigEndianNumber length:sizeof(bigEndianNumber)];
    uint8_t SourceAddr = 0xF4;                  //本地地址
    [packet appendBytes:&SourceAddr length:1];
    [packet appendBytes:&Destaddr length:1];    //目标地址
    [packet appendBytes:&Fid length:1];         //功能ID
    if(Sid !=nil)
        [packet appendData:Sid];
    if(parameterData!=nil)
        [packet appendData:parameterData];
    
    return packet;
}

@end
