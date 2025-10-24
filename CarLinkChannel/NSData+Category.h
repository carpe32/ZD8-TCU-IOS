#import <Foundation/Foundation.h>

@interface NSData (Category)

// 注意:在NSData里面,<01>表示1个字节,用2个十六进制表示,1个十六进制表示4个bits

#pragma mark - valueMehthod

/// 返回包含8个字节Data，如:输入1 -> <00 00 00 00 00 00 00 01>
+ (instancetype)dataFromLong:(long)value ;
/// 返回包含4个字节Data，如:输入1 -> <00 00 00 01>
+ (instancetype)dataFromInt:(int)value ;
/// 返回包含2个字节Data，如:输入1 -> <00 01>
+ (instancetype)dataFromShort:(short)value ;
/// 返回包含1个字节Data，如:输入1 -> <01> value必须小于256
+ (instancetype)dataOneByteFromShort:(short)value ;

/// 返回long (必须满足:self.length >= 8)
- (long)longValue ;
/// 返回int (必须满足:self.length >= 4)
- (int)intValue ;
/// 返回short (必须满足:self.length >= 2)
- (short)shortValue ;
/// 返回short (必须满足:self.length >= 1)
- (short)shortValueFromOneByteData ;


#pragma mark - StringMethod

+ (unsigned int)digitalFromHexString:(NSString *)hexString;

/// 返回Data <01ff> -> "01ff" 如果传入参数 str 为 1ff, 则hexdata打印出:hexdata: <01ff>
+ (instancetype)hexDataFromHexString:(NSString *)hexString ;
/// 十六进制字符串 <01ff> -> "01ff"
+ (NSString *)hexStringFromHexData:(NSData *)hexData ;

/// 返回网络字节序的Data IPString -> data
+ (instancetype)ipDataFromIpString:(NSString *)ipString ;
/// ip字符串
+ (NSString *)ipStringFromIpData:(NSData *)ipData ;

/// 小端大端反转 (原本是小端,则变成大端;反之亦然)
- (NSData *)reverseBitAndLittleEnd;

-(NSData *)AES256EncryptWithKey:(NSString *)key;

- (NSData *)AES256DecryptWithKey:(NSString *)key andvi:(NSString *)viString;

@end
