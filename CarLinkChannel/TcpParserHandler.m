//
//  TcpParserHandler.m
//  CarLinkChannel
//
//  Created by job on 2023/3/23.
//

#import "TcpParserHandler.h"
#import "NSData+Category.h"
#import "NetworkInterface.h"
#import "LuaInvoke.h"
@implementation TcpParserHandler


- (NSString *) tceReceiveData:(NSData *)data{
    
 //  NSString * dataString =  [NSData hexStringFromHexData:data];
    //命令解析  0第一位  到第九位和第十位
    int sign1 = 9; int sign2 = 10;   int sign3 = 20; int sign4 = 21;
    //f1 90 ==》241 144  解析后回填直vin  后17位
    //f1 01 ==》241  1 取后边数据进行解析
    //00 00 01 02 00 01 18 f4 63 ==> 0 0 1 2 0 1 18 244 99
    char * charData = (char *)data.bytes;
    
    if((charData[sign1] & 0xff) == 241 && (charData[sign2] & 0xff) == 144) {
        char * dstchar = (char*)malloc(data.length-11+1);
        memset(dstchar, 0, data.length-11+1);
        memcpy(dstchar, charData + 11, data.length-11);
        NSString * vinString =  [NSString stringWithUTF8String:dstchar];
        return vinString;
        
//
//        NSMutableData * mutabledata = [[NSMutableData alloc] initWithData:data];
//        mutabledata = [mutabledata subdataWithRange:NSMakeRange(11, data.length - 11)];
//        NSString * vinStr = [[NSString alloc] initWithData:mutabledata encoding:NSUTF8StringEncoding];
//
//        return [NSString stringWithFormat:@"a: %@   vin: %@",a,vinStr];
//        return [NSString stringWithFormat:@"a: %@   b: %@",a,b];
//
//        NSString * b = @"";
//
//        for (int i = 0; i < data.length - 11; i++) {
//
//            b = [b stringByAppendingFormat:@" %d %d",i,dstchar];
//        }
        
//        return [NSString stringWithFormat:@"%d %d %@  b: %@",dstchar[0] & 0xff,dstchar[data.length - 11 -1] & 0xff,a];
    }
    
    if((charData[sign1] & 0xff) == 241 && (charData[sign2] & 0xff )== 1 && data.length > 12)
    {
        char * dstchar = (char*)malloc(data.length-11+1);
        memset(dstchar, 0, data.length-11+1);
        memcpy(dstchar, charData + 11, data.length-11);
        NSData * dstData = [[NSData alloc] initWithBytes:dstchar length:data.length-11];
        NSString * hexString = [NSData hexStringFromHexData:dstData];
        hexString = [hexString uppercaseString];
    
        LuaInvoke * invoke = [[LuaInvoke alloc] init];
        return [invoke parseEcuWithHexString:hexString];
        
    }

                NSString * hexString = [NSData hexStringFromHexData:data];
               // 这里进行安全算法的判断
                NSString * anquan_prefix_1 = [recv_anquan_1_prefix stringByReplacingOccurrencesOfString:@" " withString:@""];
                NSString * anquan_prefix_2 = [recv_anquan_2_prefix stringByReplacingOccurrencesOfString:@" " withString:@""];
                                  
                NSString * anquanvalue = @"";
    
                if([hexString hasPrefix:anquan_prefix_1] || [hexString hasPrefix:anquan_prefix_2]){
                    hexString = [hexString substringFromIndex:anquan_suanfa_start_index];
                    NSString * string2c = @"";
                    NSString * chararray = @"abcdefABCDEF1234567890,";
                    NSCharacterSet * charset = [[NSCharacterSet characterSetWithCharactersInString:chararray] invertedSet];
                    for (int i = 0; i < hexString.length; i+=2) {
                        string2c = [string2c stringByAppendingString:[hexString substringWithRange:NSMakeRange(i, 2)]];
                        if(i != hexString.length - 2){
                            string2c = [string2c stringByAppendingString:@","];
                        }
                    }
                    NSString * encodedString = [string2c  stringByAddingPercentEncodingWithAllowedCharacters:charset];
                    anquanvalue = encodedString;
                }
    

    return anquanvalue;
}

-(NSString*)getAnquanString:(NSData *)data{
    
    
    return @"";
}

-(NSString*)convertDataToHexStrBLE:(NSData*)data {
    
    if(!data || [data length] ==0)
        
    {
        return nil;
    }
    
    NSMutableString * string = [[NSMutableString alloc]initWithCapacity:[data length]];
    
    [data enumerateByteRangesUsingBlock:^(const void*bytes,NSRange byteRange,BOOL*stop) {
        unsigned char*dataBytes = (unsigned char*)bytes;
        for(NSInteger i =0; i < byteRange.length; i++)
        {
            NSString * hexStr = [NSString stringWithFormat:@"%02x", (dataBytes[i]) &0xff];
            [string appendString:hexStr];
          //  if([hexStr length] ==2) {
          //      [string appendString:hexStr];
           // }else
           // {
             //   [string appendFormat:@"0%@", hexStr];
           // }
        }
    }];
    
    return string;
}

/*
 nsdata转成16进制字符串
 */
+ (NSString*)stringWithHexBytes2:(NSData *)sender {
    static const char hexdigits[] = "0123456789ABCDEF";
    const size_t numBytes = [sender length];
    const unsigned char* bytes = [sender bytes];
    char *strbuf = (char *)malloc(numBytes * 2 + 1);
    char *hex = strbuf;
    NSString *hexBytes = nil;
    
    for (int i = 0; i<numBytes; ++i) {
        const unsigned char c = *bytes++;
        *hex++ = hexdigits[(c >> 4) & 0xF];
        *hex++ = hexdigits[(c ) & 0xF];
    }
    
    *hex = 0;
    hexBytes = [NSString stringWithUTF8String:strbuf];
    
//    free(strbuf);
    return hexBytes;
}


/*
 将16进制数据转化成NSData 数组
 */
+(NSData*) parseHexToByteArray:(NSString*) hexString
{
    int j=0;
    Byte bytes[hexString.length];
    for(int i=0;i<[hexString length];i++)
    {
        int int_ch;  /// 两位16进制数转化后的10进制数
        unichar hex_char1 = [hexString characterAtIndex:i]; ////两位16进制数中的第一位(高位*16)
        int int_ch1;
        if(hex_char1 >= '0' && hex_char1 <='9')
            int_ch1 = (hex_char1-48)*16;   //// 0 的Ascll - 48
        else if(hex_char1 >= 'A' && hex_char1 <='F')
            int_ch1 = (hex_char1-55)*16; //// A 的Ascll - 65
        else
            int_ch1 = (hex_char1-87)*16; //// a 的Ascll - 97
        i++;
        unichar hex_char2 = [hexString characterAtIndex:i]; ///两位16进制数中的第二位(低位)
        int int_ch2;
        if(hex_char2 >= '0' && hex_char2 <='9')
            int_ch2 = (hex_char2-48); //// 0 的Ascll - 48
        else if(hex_char2 >= 'A' && hex_char1 <='F')
            int_ch2 = hex_char2-55; //// A 的Ascll - 65
        else
            int_ch2 = hex_char2-87; //// a 的Ascll - 97
        
        int_ch = int_ch1+int_ch2;
        bytes[j] = int_ch;  ///将转化后的数放入Byte数组里
        j++;
    }
    
    NSData *newData = [[NSData alloc] initWithBytes:bytes length:hexString.length/2];
    return newData;
}

@end
