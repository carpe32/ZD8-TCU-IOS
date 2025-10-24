#import "NSData+Category.h"
#import <arpa/inet.h>
#import <CommonCrypto/CommonCryptor.h>

@implementation NSData (Category)

#pragma mark -- valueMethod

+ (instancetype)dataFromLong:(long)value {
    return [NSMutableData dataWithBytes: &value length: sizeof(long)];
}

+ (instancetype)dataFromInt:(int)value {
    return [NSMutableData dataWithBytes: &value length: sizeof(int)];
}

+ (instancetype)dataFromShort:(short)value {
    return [NSMutableData dataWithBytes: &value length: sizeof(short)];
}

+ (instancetype)dataOneByteFromShort:(short)value {
    NSAssert(value <= 256-1, @"value must be not overflow one byte value");
    return [NSMutableData dataWithBytes: &value length: sizeof(short)-1];
}

- (long)longValue {
    NSAssert(self.length >= 8, @"data length must be bigger than 8");
    long value;
    [self getBytes: &value length: sizeof(long)];
    return value;
}

- (int)intValue {
    NSAssert(self.length >= 4, @"data length must be bigger than 4");
    int value;
    [self getBytes: &value length: sizeof(int)];
    return value;
}

- (short)shortValue {
    NSAssert(self.length >= 2, @"data length must be bigger than 2");
    short value;
    [self getBytes: &value length: sizeof(short)];
    return value;
}

- (short)shortValueFromOneByteData {
    NSAssert(self.length >= 1, @"data length must be bigger than 1");
    short value;
    [self getBytes: &value length: 1];
    return value;
}

#pragma Mark - stringMethod
/// 返回Data <01ff> -> "01ff" 如果传入参数 str 为 1ff, 则hexdata打印出:hexdata: <01ff>
+ (instancetype)hexDataFromHexString:(NSString *)hexString {
    if (!hexString || [hexString length] == 0)  return nil;
    
    NSMutableData *hexData = [[NSMutableData alloc] initWithCapacity:8];
    NSRange range;
    if ([hexString length] % 2 == 0) {
        range = NSMakeRange(0, 2);
    } else {
        range = NSMakeRange(0, 1);
    }
    for (NSInteger i = range.location; i < [hexString length]; i += 2) {
        unsigned int anInt;
        NSString *hexCharStr = [hexString substringWithRange:range];
        NSScanner *scanner = [[NSScanner alloc] initWithString:hexCharStr];
        
        [scanner scanHexInt:&anInt];
        NSData *entity = [[NSData alloc] initWithBytes:&anInt length:1];
        [hexData appendData:entity];
        
        range.location += range.length;
        range.length = 2;
    }
    return hexData;
}

/// 十六进制字符串 <01ff> -> "01ff"
+ (NSString *)hexStringFromHexData:(NSData *)hexData {
    if (!hexData || [hexData length] == 0) return @"";
    
    NSMutableString *string = [[NSMutableString alloc] initWithCapacity:[hexData length]];
    
    [hexData enumerateByteRangesUsingBlock:^(const void *bytes, NSRange byteRange, BOOL *stop) {
        unsigned char *dataBytes = (unsigned char*)bytes;
        for (NSInteger i = 0; i < byteRange.length; i++) {
            NSString *hexStr = [NSString stringWithFormat:@"%x", (dataBytes[i]) & 0xff];
            if ([hexStr length] == 2) {
                [string appendString:hexStr];
            } else {
                [string appendFormat:@"0%@", hexStr];
            }
        }
    }];
    
    return string;
}
// data转成int
+ (unsigned int)digitalFromHexString:(NSString *)hexString {
    if (!hexString || [hexString length] == 0)  return 0;
    
  //  NSMutableData *hexData = [[NSMutableData alloc] initWithCapacity:8];
//    NSRange range;
//    if ([hexString length] % 2 == 0) {
//        range = NSMakeRange(0, 2);
//    } else {
//        range = NSMakeRange(0, 1);
//    }
    unsigned int count = 0;
    
   // NSString *hexCharStr = [hexString substringWithRange:range];
    NSScanner *scanner = [[NSScanner alloc] initWithString:hexString];
    
    [scanner scanHexInt:&count];
    
  //  count += anInt;
    
    
//    for (NSInteger i = range.location; i < [hexString length]; i += 2) {
//        unsigned int anInt;
//        NSString *hexCharStr = [hexString substringWithRange:range];
//        NSScanner *scanner = [[NSScanner alloc] initWithString:hexCharStr];
//
//        [scanner scanHexInt:&anInt];
//
//        count += anInt;
//
////        NSData *entity = [[NSData alloc] initWithBytes:&anInt length:1];
////        [hexData appendData:entity];
//
//        range.location += range.length;
//        range.length = 2;
//    }
    return count;
}

/// 返回网络字节序的Data IPString -> data
+ (instancetype)ipDataFromIpString:(NSString *)ipString {
    unsigned int s_addr = inet_addr([ipString UTF8String]);
    NSData *data = [NSMutableData dataWithBytes: &s_addr length: sizeof(unsigned int)];
    return data.reverseBitAndLittleEnd;
}

/// ip字符串
+ (NSString *)ipStringFromIpData:(NSData *)ipData {
    /// to unsigned int
    unsigned int value = *(unsigned int *)ipData.reverseBitAndLittleEnd.bytes;
    
    /// to char
    struct in_addr addr;
    addr.s_addr = value;
    char *strAddr = inet_ntoa(addr);
    
    return [NSString stringWithUTF8String:strAddr];
}

/// 小端大端反转 (原本是小端,则变成大端;反之亦然)
- (NSData *)reverseBitAndLittleEnd {
    NSMutableData *littleEndData = [NSMutableData data];
    
    for(int i = 0; i < self.length; i++){
        NSData *subdata = [self subdataWithRange:NSMakeRange(self.length -i -1, 1)];
        [littleEndData appendData:subdata];
    }
    return littleEndData;
}

-(NSData *)AES256EncryptWithKey:(NSString *)key {
    // 'key' should be 32 bytes for AES256, will be null-padded otherwise
    char keyPtr[kCCKeySizeAES256+1]; // room for terminator (unused)
    bzero(keyPtr, sizeof(keyPtr)); // fill with zeroes (for padding)
    
    // fetch key data
    [key getCString:keyPtr maxLength:sizeof(keyPtr) encoding:NSUTF8StringEncoding];
    
    NSUInteger dataLength = [self length];
    
    //See the doc: For block ciphers, the output size will always be less than or
    //equal to the input size plus the size of one block.
    //That's why we need to add the size of one block here
    size_t bufferSize = dataLength + kCCBlockSizeAES128;
    void *buffer = malloc(bufferSize);
    
    size_t numBytesEncrypted = 0;
    CCCryptorStatus cryptStatus = CCCrypt(kCCEncrypt, kCCAlgorithmAES128, kCCOptionPKCS7Padding,
                                          keyPtr, kCCKeySizeAES256,
                                          NULL /* initialization vector (optional) */,
                                          [self bytes], dataLength, /* input */
                                          buffer, bufferSize, /* output */
                                          &numBytesEncrypted);
    if (cryptStatus == kCCSuccess) {
        //the returned NSData takes ownership of the buffer and will free it on deallocation
        return [NSData dataWithBytesNoCopy:buffer length:numBytesEncrypted];
    }
    
    free(buffer); //free the buffer;
    return nil;
    
}

- (NSData *)AES256DecryptWithKey:(NSString *)key andvi:(NSString *)viString{
    // 'key' should be 32 bytes for AES256, will be null-padded otherwise
    char keyPtr[kCCKeySizeAES256+1]; // room for terminator (unused)
    bzero(keyPtr, sizeof(keyPtr)); // fill with zeroes (for padding)
    
    // fetch key data
    [key getCString:keyPtr maxLength:sizeof(keyPtr) encoding:NSUTF16StringEncoding];
    
    NSUInteger dataLength = [self length];
    
    //See the doc: For block ciphers, the output size will always be less than or
    //equal to the input size plus the size of one block.
    //That's why we need to add the size of one block here
    size_t bufferSize = dataLength + kCCBlockSizeAES128;
    void *buffer = malloc(bufferSize);
    
    
    char ivPtr[kCCBlockSizeAES128+1];
    memset(ivPtr, 0, sizeof(ivPtr));
    if (viString != nil) {
        [viString getCString:ivPtr maxLength:sizeof(ivPtr) encoding:NSUTF16StringEncoding];
    }
    
    size_t numBytesDecrypted = 0;
    CCCryptorStatus cryptStatus = CCCrypt(kCCDecrypt, kCCAlgorithmAES128, kCCOptionPKCS7Padding,
                                          keyPtr, kCCKeySizeAES128,
                                          ivPtr /* initialization vector (optional) */,
                                          [self bytes], dataLength, /* input */
                                          buffer, bufferSize, /* output */
                                          &numBytesDecrypted);
    
    if (cryptStatus == kCCSuccess) {
        //the returned NSData takes ownership of the buffer and will free it on deallocation
        return [NSData dataWithBytesNoCopy:buffer length:numBytesDecrypted];
    }
    
    free(buffer); //free the buffer;
    return nil;
}
@end
