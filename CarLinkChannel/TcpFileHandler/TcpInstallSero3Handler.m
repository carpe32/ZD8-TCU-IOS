//
//  TcpInstallSero3Handler.m
//  CarLinkChannel
//
//  Created by job on 2023/4/21.
//

#import "TcpInstallSero3Handler.h"
#import "HttpClient.h"
#import "NSData+Category.h"
#import <libkern/OSAtomic.h>
#import "CommunityInterface.h"
#import "NetworkInterface.h"

@interface TcpInstallSero3Handler()
{
    __block OSSpinLock oslock;
    NSString * receiveanquan;
}
@end
@implementation TcpInstallSero3Handler


-(void)receiveanquanvalue:(NSString *)anquan{
    
    NSLog(@"收到安全算法的通知，现在进行解锁");
    receiveanquan = anquan;
    OSSpinLockUnlock(&oslock);
}

-(BOOL)sendCommonData:(NSString *)datapacket {
    
   // NSLog(@"发送: %@",datapacket);
   // NSLog(@"发送: %@",datapacket);
    datapacket = [datapacket stringByReplacingOccurrencesOfString:@" " withString:@""];
    
    if(self.delegate && [self.delegate respondsToSelector:@selector(sendInstallControllerPacket:)]){
        NSLog(@"--------------------> 发送数据");
//        sleep(1);
        usleep(200000);
        return  [self.delegate sendInstallControllerPacket:datapacket];
    }
//
//    NSString * unitString = @"";
//
//    for (int l = 1; l <= datapacket.length; l += 2) {
//
//        NSString * subString = [datapacket substringWithRange:NSMakeRange(l-1, 2)];
//        unitString = [unitString stringByAppendingString:subString];
//        if(l > 1 && ((l+1) % 32) == 0){
//         //   NSLog(@"\r\n");
//            unitString = [unitString stringByAppendingString:@"\r\n"];
//        }else{
//          //  NSLog(@" ");
//            unitString = [unitString stringByAppendingString:@" "];
//        }
//
//    }
//    NSLog(@"%@",unitString);
    return false;
}

-(BOOL)sendCommonBinaryData:(NSString *)datapacket {
    datapacket = [datapacket stringByReplacingOccurrencesOfString:@" " withString:@""];
    if(self.delegate && [self.delegate respondsToSelector:@selector(sendInstallBinaryPacket:)]){
//        sleep(1);
        usleep(200000);
        return  [self.delegate sendInstallBinaryPacket:datapacket];
    }
  
    return false;
}
-(void)LoadFileWithPath:(NSString *) path cafdPath:(NSString *)cafdPath {
    if(oslock){
        OSSpinLockUnlock(&oslock);
        oslock = nil;
    }
    
  //  path = [[NSBundle mainBundle] pathForResource:@"tune" ofType:@"bin"];
    
  //  NSString * path = [[NSBundle mainBundle] pathForResource:@"tune" ofType:@"bin"];
    NSData * file_data = [NSData dataWithContentsOfFile:path];
    file_data = [file_data AES256DecryptWithKey:@"Q1w2e3r4" andvi:@"Q1w2e3r4"];
    NSData * tempdata;
   // CommunityInterface * interface = [CommunityInterface getInstance];
    // 1. 先取第一位的校验值
    NSData * oneData = [file_data subdataWithRange:NSMakeRange(0, 2)];
    NSString * testbin = [NSData hexStringFromHexData:oneData];
    if([testbin isEqualToString:binheader]){
        
        //00000002 - 00000003：F190固定
        //00000004 - 00000014：17位车架号（校验使用）
        NSData * vinData = [file_data subdataWithRange:NSMakeRange(0x4, 0x14-0x4+1)];
        char * dst = (char*)vinData.bytes;
        //  NSString * vinString = [NSData hexStringFromHexData:carjiaData];
        NSString * vin = [NSString stringWithUTF8String:dst];
        
        NSLog(@"vin: %@",vin);
        // 判断vin字符串
        if([vin isEqualToString:@""]){
            
        }
        
        
        // BLDT   名字
        NSData * bldtData = [file_data subdataWithRange:NSMakeRange(0x17, 0x1A-0x17+1)];
        NSString * bldtName = [NSData hexStringFromHexData:bldtData];
        
        // BLDT  版本
        NSData * bldtVerData = [file_data subdataWithRange:NSMakeRange(0x1B, 0x1D-0x1B+1)];
        NSData * verdata1 = [bldtVerData subdataWithRange:NSMakeRange(0, 1)];
        NSData * verdata2 = [bldtVerData subdataWithRange:NSMakeRange(1, 1)];
        NSData * verdata3 = [bldtVerData subdataWithRange:NSMakeRange(2, 1)];
        NSString * version1 = [[NSString alloc] initWithData:verdata1 encoding:NSUTF8StringEncoding];
        NSString * version2 = [[NSString alloc] initWithData:verdata2 encoding:NSUTF8StringEncoding];
        NSString * version3 = [[NSString alloc] initWithData:verdata3 encoding:NSUTF8StringEncoding];
        
        NSString * bldtVersion = [NSString stringWithFormat:@"%@-%@-%@",verdata1,version2,version3];
        
        NSString * BTLD = [NSString stringWithFormat:@"btld-%@-%@",bldtName,bldtVersion];
        
        NSLog(@"btld: %@",BTLD);
        
        //00000220 - 000002BF是第一段数据，以BD BD BD BD BD（5个BD结尾，这5个BD不发送）
        //000002C0 - 0000035F是第二段数据，以BD BD BD BD BD（5个BD结尾，这5个BD不发送）
        //00000360 - 000003FF是第二段数据，以BD BD BD BD BD（5个BD结尾，这5个BD不发送）
        //temps = datas_ev.Skip(Convert.ToInt32("0x220", 16)).Take(Convert.ToInt32("0x2BF", 16) - Convert.ToInt32("0x220", 16) + 1).ToArray();
        //string end2data11 = BitConverter.ToString(temps, 0).Replace("-", string.Empty).ToLower().Replace("bdbdbd","-").Split('-')[0];
        
        //temps = datas_ev.Skip(Convert.ToInt32("0x2C0", 16)).Take(Convert.ToInt32("0x35F", 16) - Convert.ToInt32("0x2C0", 16) + 1).ToArray();
        //string end2data22 = BitConverter.ToString(temps, 0).Replace("-", string.Empty).ToLower().Replace("bdbdbd", "-").Split('-')[0];
        
        //temps = datas_ev.Skip(Convert.ToInt32("0x360", 16)).Take(Convert.ToInt32("0x3FF", 16) - Convert.ToInt32("0x360", 16) + 1).ToArray();
        //string end2data33 = BitConverter.ToString(temps, 0).Replace("-", string.Empty).ToLower().Replace("bdbdbd", "-").Split('-')[0];
        
        
        //00000020预留
        //00000021 - 00000023：为前置条件
        //021为前置条件1，值为00或11（00不执行，11执行）
        //022为前置条件2，值为00或11（00不执行，11执行）
        //023为前置条件3，值为00或11（00不执行，11执行）
        //00000024 - 00000025：预留
        //00000026 - 00000027：功能版本（暂时记录，之后会显示出来，现在无需操作）
        //00000028 - 0000002F：预留
        
        
        NSData * frontData1 = [file_data subdataWithRange:NSMakeRange(0x21, 1)];
        NSString * front1 = [NSData hexStringFromHexData:frontData1];
        NSData * frontData2 = [file_data subdataWithRange:NSMakeRange(0x22, 1)];
        NSString * front2 = [NSData hexStringFromHexData:frontData2];
        NSData * frontData3 = [file_data subdataWithRange:NSMakeRange(0x23, 1)];
        NSString * front3 = [NSData hexStringFromHexData:frontData3];
        
        
        NSLog(@"front1: %@,front2: %@,front3: %@",front1,front2,front3);
        
        
      //  if([front1 isEqualToString:condition_on]){
            
        //    [self sendCommonData:front1_data_packet_1];
            
       // }
        NSMutableDictionary *ErroruserInfo = [NSMutableDictionary dictionary];

        if([front2 isEqualToString:condition_on]){
            
          BOOL result =  [self sendCommonData:front2_data_packet_1];
            if(result == false){
                [ErroruserInfo setObject:@"0301" forKey:@"ErrorCode"];
                [[NSNotificationCenter defaultCenter] postNotificationName:fail_install_notify_name object:nil userInfo:ErroruserInfo];
                return;
            }
           result = [self sendCommonData:front2_data_packet_2];
            if(result == false){
                [ErroruserInfo setObject:@"0302" forKey:@"ErrorCode"];
                [[NSNotificationCenter defaultCenter] postNotificationName:fail_install_notify_name object:nil userInfo:ErroruserInfo];
                return;
            }
           result = [self sendCommonData:front2_data_packet_3];
            if(result == false){
                [ErroruserInfo setObject:@"0303" forKey:@"ErrorCode"];
                [[NSNotificationCenter defaultCenter] postNotificationName:fail_install_notify_name object:nil userInfo:ErroruserInfo];
                return;
            }
           result = [self sendCommonData:front2_data_packet_4];
            if(result == false){
                [ErroruserInfo setObject:@"0304" forKey:@"ErrorCode"];
                [[NSNotificationCenter defaultCenter] postNotificationName:fail_install_notify_name object:nil userInfo:ErroruserInfo];
                return;
            }
           result = [self sendCommonData:front2_data_packet_5];
            if(result == false){
                [ErroruserInfo setObject:@"0305" forKey:@"ErrorCode"];
                [[NSNotificationCenter defaultCenter] postNotificationName:fail_install_notify_name object:nil userInfo:ErroruserInfo];
                return;
            }
           result = [self sendCommonData:front2_data_packet_6];
            if(result == false){
                [ErroruserInfo setObject:@"0306" forKey:@"ErrorCode"];
                [[NSNotificationCenter defaultCenter] postNotificationName:fail_install_notify_name object:nil userInfo:ErroruserInfo];
                return;
            }
           result = [self sendCommonData:front2_data_packet_7];
            if(result == false){
                [ErroruserInfo setObject:@"0307" forKey:@"ErrorCode"];
                [[NSNotificationCenter defaultCenter] postNotificationName:fail_install_notify_name object:nil userInfo:ErroruserInfo];
                return;
            }
        }
        
        //   保留字段
        if([front3 isEqualToString:condition_on]){
            
            
        }
        
        int filestart = 48; int inscrease = 16 * 14; //int times = 14;
        int yingshestart = 272;
        //00000030 - 0000003F：到 00000100 - 0000010F：
        //这些是文件的存放信息，相当于我们之前的xml，里面的：
        //第0位 = 文件编号
        //第1位 = 文件是否有，00是不考虑，没有对应文件；01是需要考虑，有对应文件
        //第2 - 5位的AAAAAAAA是相当于xml里面的起始位置
        //第6 - 9位的BBBBBBBB是相当于xml里面的大小（这里已经设置成大小了，不需要再进行计算了）
        //第A - D位的CCCCCCCC是这些数据内容存在本文件的位置，是bin文件的位置
        //  第E位的EE是写入文件配置时候的34 ZZ 44这个ZZ（原先是在软件里面手输入那个值，现在是这里直接配置）
        //第F位：预留
        //////////////////////////////////////////////////////////////////////////////////////////////////////////
        /////////////////////////////////////////////////////////////////////////////////////////////////////////
        ///00000110-0000011F：到 000001E0-000001EF：
        //第0位 = 文件编号
        //第1位 = 文件是否有，00是不考虑，没有对应文件；01是需要考虑，有对应文件
        //继续2 - F这些是文件的功能的选项
        //2 = 安全算法是否有，11是需要安全算法，文件传输前有安全算法流程；00是没有安全算法流程
        //3 = 检测是否写入成功，01是发送检测指令（如果检测，需要提示是否成功、失败、未知）；00是不发送（第9 - F位为内容）
        //4 = 1101的发送，01是发送；00是不发送
        //5 = 额外执行的特定数据，01是发送；00是不发送
        //  第6位暂时预留
        //第7位为写入设置前面那行是否需要执行：00为不执行这行；01为执行这行，之前是以xml为参考，所以每个xml执行写入前需要发送这条，现在没有xml，所以需要这样设置一下是否执行了，写入前面那行的内容是（00 00 00 0c 00 01 f4 18 31 01 ff 00 02 40 BB BB BB BB）
        //第8 - B位：BB BB BB BB的内容（如果为00000000则不发送这条数据）
        //第C - F位：CC CC CC CC的内容是检测是否写入成功的那个值（对应文件：检测是否写入成功.txt）
        int instart = 0;
        int yinsheinstart = 0;
        int filecount = 0;
        
        // 需要先看有多少个需要写入的文件
        for (int i = 0; i<14; i++) {
            instart = filestart + 16 * i;
            tempdata = [file_data subdataWithRange:NSMakeRange(instart+1, 1)];
            NSString * iswrite = [NSData hexStringFromHexData:tempdata];
            if([iswrite isEqualToString:attribute_01]){
                filecount ++;
            }else{
                break;
            }
        }
        
        instart = 0;
        for (int i = 0; i < 14; i++) {
            
            instart = filestart + 16 * i;
            tempdata = [file_data subdataWithRange:NSMakeRange(instart+1, 1)];
            NSString * iswrite = [NSData hexStringFromHexData:tempdata];
            
            //如果不存在文件的时候就不再读取
            if(![iswrite isEqualToString:attribute_01]){
                break;
            }else{
                NSDictionary * dataDict = @{@"fileCount":@(filecount),@"fileInstallCount":@(i+1)};
                [[NSNotificationCenter defaultCenter] postNotificationName:install_file_read_notify_name object:nil userInfo:dataDict];
            }
            
            tempdata = [file_data subdataWithRange:NSMakeRange(instart + 2, 4)];
            NSString * xmlstartaddress = [[NSData hexStringFromHexData:tempdata] lowercaseString];
            
            tempdata = [file_data subdataWithRange:NSMakeRange(instart + 6, 4)];
            NSString * xmlfileslength = [[NSData hexStringFromHexData:tempdata] lowercaseString];
            
            tempdata = [file_data subdataWithRange:NSMakeRange(instart + 10, 4)];
            NSString * xmlbinaddress = [[NSData hexStringFromHexData:tempdata] lowercaseString];
            
            tempdata = [file_data subdataWithRange:NSMakeRange(instart + 14, 1)];
            NSString * xmlzz = [NSData hexStringFromHexData:tempdata];
            
            tempdata = [file_data subdataWithRange:NSMakeRange(instart + 15, 1)];
            NSString * succsendend = [NSData hexStringFromHexData:tempdata];
            
            
            NSLog(@"iswrite: %@ , xmlstartaddress: %@,xmlfileslength: %@,xmlbinaddress: %@,xmlzz: %@,successend: %@",iswrite,xmlstartaddress,xmlfileslength,xmlbinaddress,xmlzz,succsendend);
            

            /////////////////////////////////////////////////////////////////////////////////
            yinsheinstart = yingshestart + 16 * i;
            
            tempdata = [file_data subdataWithRange:NSMakeRange(yinsheinstart + 1, 1)];
            NSString * isfuzhu = [NSData hexStringFromHexData:tempdata];
            
            tempdata = [file_data subdataWithRange:NSMakeRange(yinsheinstart + 2, 1)];
            NSString * issafe = [NSData hexStringFromHexData:tempdata];
            
            tempdata = [file_data subdataWithRange:NSMakeRange(yinsheinstart + 3, 1)];
            NSString * ischecksuccess = [NSData hexStringFromHexData:tempdata];
            
            tempdata = [file_data subdataWithRange:NSMakeRange(yinsheinstart + 4, 1)];
            NSString * is1101 = [NSData hexStringFromHexData:tempdata];
            
            tempdata = [file_data subdataWithRange:NSMakeRange(yinsheinstart + 5, 1)];
            NSString * isspecdata = [NSData hexStringFromHexData:tempdata];
            
            tempdata = [file_data subdataWithRange:NSMakeRange(yinsheinstart + 7, 1)];
            NSString * issend = [NSData hexStringFromHexData:tempdata];
            
            tempdata = [file_data subdataWithRange:NSMakeRange(yinsheinstart + 8, 4)];
            NSString * bdatas = [[NSData hexStringFromHexData:tempdata] lowercaseString];
            
            tempdata = [file_data subdataWithRange:NSMakeRange(yinsheinstart + 12, 4)];
            NSString * ccdatas = [[NSData hexStringFromHexData:tempdata] lowercaseString];
            
            
            NSLog(@"isfuzhu: %@,issafe: %@,ischecksuccess: %@, is1101: %@,isspecdata: %@,issend: %@,bdatas: %@,ccdatas: %@",isfuzhu,issafe,ischecksuccess,is1101,isspecdata,issend,bdatas,ccdatas);
            
            
            // 先判断是否有数据，如果有的话就进行发送
            if([iswrite isEqualToString:attribute_01]){
                if([issafe isEqualToString:condition_on]){
                    NSLog(@"当前文件有安全算法");
                    oslock = OS_SPINLOCK_INIT;
                    NSLog(@"现在是初始化锁完成开始加锁");
                    OSSpinLockLock(&oslock);
                    __block BOOL result = [self sendCommonData:safe_data_packet_1];
                    if(result == false){
                        [ErroruserInfo setObject:@"0308" forKey:@"ErrorCode"];
                        [[NSNotificationCenter defaultCenter] postNotificationName:fail_install_notify_name object:nil userInfo:ErroruserInfo];
                        return;
                    }
                    result =  [self sendCommonData:safe_data_packet_2];
                    if(result == false){
                        [[NSNotificationCenter defaultCenter] postNotificationName:tcp_security_timeout_notify_name object:nil];
                        return;
                    }
     
                    OSSpinLockLock(&oslock);
                  //  NSString * var3 = [recv_var3 stringByReplacingOccurrencesOfString:@" " withString:@","];
                  //  NSRange range = [receiveanquan rangeOfString:@"ff"];
                  //  NSString * var3 = [receiveanquan substringFromIndex:anquan_suanfa_start_index];
                    
//                    NSCharacterSet * encode_set = [NSCharacterSet URLUserAllowedCharacterSet];
//                    NSString * encodedString = [var3 stringByAddingPercentEncodingWithAllowedCharacters:encode_set];
                    
//                    NSString *encodedString = (NSString *)
//                       CFBridgingRelease(CFURLCreateStringByAddingPercentEscapes(kCFAllocatorDefault,
//                                                                                 (CFStringRef)var3,
//                                                                                 (CFStringRef)@"!$&'()*+,-./:;=?@_~%#[]",
//                                                                                 NULL,
//                                                                                 kCFStringEncodingUTF8));
 
                    
//                    NSString * chararray = @"abcdefABCDEF1234567890";
//                    NSCharacterSet * charset = [[NSCharacterSet characterSetWithCharactersInString:chararray] invertedSet];
//                    NSString * charstring = [var3 stringByAddingPercentEncodingWithAllowedCharacters:charset];
                    
                  //  NSString * strurl = [NSString stringWithFormat:@"%@%@",anquan_suanfa_url,receiveanquan];
                    NSLog(@"现在进行http请求，获取安全算法值, receiveanquan: %@",receiveanquan);
                    NetworkInterface * interface = [NetworkInterface getInterface];
                    [interface getanquansuanfabtld:self.btldValue parmarsvar3:receiveanquan doneBlock:^(NSString * suanfa){
                        NSLog(@"现在是获取到安全算法值，发送安全值: %@",suanfa);
                        NSString * packetString = [sero_3_datapcket_1_anquan_prefix stringByAppendingString:suanfa];
                        result = [self sendCommonData:packetString];
                        OSSpinLockUnlock(&oslock);
                        } withError:^(NSError * error){
                            NSLog(@"http 请求出错: %@",error);
                            result = false;
                            OSSpinLockUnlock(&oslock);
                    }];
                    NSLog(@"发送http请求后: interface: %@",interface);

//                    NSURLSessionDataTask * task = [[NSURLSession sharedSession] dataTaskWithURL:[NSURL URLWithString:strurl] completionHandler:^(NSData * data,NSURLResponse * response,NSError * error){
//                        NSString * dataString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
//                        dataString = [dataString stringByReplacingOccurrencesOfString:@"," withString:@""];
//                        dataString = [dataString stringByReplacingOccurrencesOfString:@"\r" withString:@""];
//                        dataString = [dataString stringByReplacingOccurrencesOfString:@"\n" withString:@""];
//                        NSData * hexData = [NSData hexDataFromHexString:dataString];
//                        NSString * hexString = [NSData hexStringFromHexData:hexData];
//                        NSString * packetString = [safe_data_packet_3_unit_1 stringByAppendingString:hexString];
//                        [self sendCommonData:packetString];
//                        OSSpinLockUnlock(&oslock);
//
//                    }];
//                    [task resume];
//
                    OSSpinLockLock(&oslock);
                    if(result == false){
                        [ErroruserInfo setObject:@"0309" forKey:@"ErrorCode"];
                        [[NSNotificationCenter defaultCenter] postNotificationName:fail_install_notify_name object:nil userInfo:ErroruserInfo];
                        return;
                    }
                    
                    NSLog(@"现在在锁之外");
                
                  result =  [self sendCommonData:sero_3_datapcket_1];
                    if(result == false){
                        [ErroruserInfo setObject:@"0310" forKey:@"ErrorCode"];
                        [[NSNotificationCenter defaultCenter] postNotificationName:fail_install_notify_name object:nil userInfo:ErroruserInfo];
                        return;
                    }
                  //  [];
                }
                
                if([issend isEqualToString:attribute_01]){
                    NSString * dataString = [[send_data_packet_1_1_unit_1 stringByAppendingString:bdatas] stringByAppendingString:@"06"];
                  BOOL result = [self sendCommonData:dataString];
                    if(result == false){
                        [ErroruserInfo setObject:@"0311" forKey:@"ErrorCode"];
                        [[NSNotificationCenter defaultCenter] postNotificationName:fail_install_notify_name object:nil userInfo:ErroruserInfo];
                        return;
                    }
                }else if ([issend isEqualToString:attribute_03]){
                    BOOL result =  [self sendCommonData:send_data_packet_3_1];
                    if(result == false){
                        [ErroruserInfo setObject:@"0312" forKey:@"ErrorCode"];
                        [[NSNotificationCenter defaultCenter] postNotificationName:fail_install_notify_name object:nil userInfo:ErroruserInfo];
                        return;
                    }
                    result = [self sendCommonData:send_data_packet_3_2];
                    if(result == false){
                        [ErroruserInfo setObject:@"0313" forKey:@"ErrorCode"];
                        [[NSNotificationCenter defaultCenter] postNotificationName:fail_install_notify_name object:nil userInfo:ErroruserInfo];
                        return;
                    }
                    result =  [self sendCommonData:send_data_packet_3_3];
                    if(result == false){
                        [ErroruserInfo setObject:@"0314" forKey:@"ErrorCode"];
                        [[NSNotificationCenter defaultCenter] postNotificationName:fail_install_notify_name object:nil userInfo:ErroruserInfo];
                        return;
                    }
                }else{
                    
                    
                }
                NSString * xmlzz_packet = [send_data_xmlzz_packet_unit_1 stringByAppendingFormat:@"%@44%@%@",xmlzz,xmlstartaddress,xmlfileslength];
                BOOL result =  [self sendCommonData:xmlzz_packet];
                if(result == false){
                    [ErroruserInfo setObject:@"0315" forKey:@"ErrorCode"];
                    [[NSNotificationCenter defaultCenter] postNotificationName:fail_install_notify_name object:nil userInfo:ErroruserInfo];
                    return;
                }
                int location_bin = [NSData digitalFromHexString:xmlbinaddress];
                int length_bin = [NSData digitalFromHexString:ccdatas];
                NSData * binData  = [file_data subdataWithRange:NSMakeRange(location_bin, length_bin)];
              //  NSString * binString = [NSData hexStringFromHexData:binData];
                
                NSLog(@"location_bin: %d, lenght_bin: %d",location_bin,length_bin);
            //    NSLog(@"binString: %@",binString);
                
                // 开始发送文件
                long times = binData.length / 2999;
                long last = binData.length % 2999;
                long total_packet = (last > 0 ? 1 : 0) + times;
                NSMutableArray * indexArray = [NSMutableArray array];
                for (int i = 0; i < times; i+=256) {
                    for (int j = 1; j < 256; j++) {
                        if(indexArray.count >= times){
                            break;
                        }
                        [indexArray addObject:@(j)];
                    }
                    if(indexArray.count >= times){
                        break;
                    }
                    [indexArray addObject:@(0)];
                }
                
                if(times != 0){
                    for (int i = 0; i < times; i++) {
                        NSString * pos_hex = [NSString stringWithFormat:@"%02X",[[indexArray objectAtIndex:i] intValue]];
                        NSString * data_packet = [send_bin_data_unit1 stringByAppendingString:pos_hex];
                        tempdata = [binData subdataWithRange:NSMakeRange(i*2999, 2999)];
                        NSString * data_string = [NSData hexStringFromHexData:tempdata];
                        data_packet = [data_packet stringByAppendingString:data_string];
                        bool result = [self sendCommonBinaryData:data_packet];
                        if(!result){
                            [ErroruserInfo setObject:@"0316" forKey:@"ErrorCode"];
                            [[NSNotificationCenter defaultCenter] postNotificationName:fail_install_notify_name object:nil userInfo:ErroruserInfo];
                            return;
                        }else{
                            NSDictionary * dataDict = @{@"count":@(total_packet),@"install":@(i+1)};
                            [[NSNotificationCenter defaultCenter] postNotificationName:install_notify_name object:nil userInfo:dataDict];
                            NSLog(@"发送安装过程通知: %@",dataDict);
                        }
//                        sleep(0.5);
                    }
                }
                
                if(last > 0){
                    int nextv = 1;
                    if(indexArray.count > 0){
                        nextv = [indexArray[indexArray.count - 1] intValue] + 1;
                    }
                    if(nextv == 256){
                        nextv = 0;
                    }
                    
                    NSString * digital = [NSString stringWithFormat:@"%08lx",last + 4];
                    NSString * digital_end = [NSString stringWithFormat:@"%02x",nextv];
                    NSString * data_packet = [digital stringByAppendingString:send_bin_data_last_header];
                    data_packet = [data_packet stringByAppendingString:digital_end];
                    tempdata = [binData subdataWithRange:NSMakeRange(times * 2999, last)];
                    NSString * dataString = [[[NSData hexStringFromHexData:tempdata] stringByReplacingOccurrencesOfString:@"-" withString:@""] lowercaseString];
                    data_packet = [data_packet stringByAppendingString:dataString];
                    bool result =  [self sendCommonBinaryData:data_packet];
                    if(!result){
                        [ErroruserInfo setObject:@"0317" forKey:@"ErrorCode"];
                        [[NSNotificationCenter defaultCenter] postNotificationName:fail_install_notify_name object:nil userInfo:ErroruserInfo];
                        return;
                    }else{
                        NSDictionary * dataDict = @{@"count":@(total_packet),@"install":@(times+1)};
                        [[NSNotificationCenter defaultCenter] postNotificationName:install_notify_name object:nil userInfo:dataDict];
                        NSLog(@"发送第%d个文件安装完成通知: %@",i,dataDict);
                    }
//                    sleep(0.5);
                }
  
                // 发送结束符
               result =  [self sendCommonData:send_data_end_1];
                if(result == false){
                    [ErroruserInfo setObject:@"0318" forKey:@"ErrorCode"];
                    [[NSNotificationCenter defaultCenter] postNotificationName:fail_install_notify_name object:nil userInfo:ErroruserInfo];
                    return;
                }
               result = [self sendCommonData:send_data_end_2];
                if(result == false){
                    [ErroruserInfo setObject:@"0319" forKey:@"ErrorCode"];
                    [[NSNotificationCenter defaultCenter] postNotificationName:fail_install_notify_name object:nil userInfo:ErroruserInfo];
                    return;
                }
                
                
                if([ischecksuccess isEqualToString:attribute_01]){
                    
                    NSString * datapacket = [check_succ_packet_1_unit_1 stringByAppendingString:bdatas];
                    datapacket = [datapacket stringByAppendingString:@"00 00"];
                    BOOL resu = [self sendCommonData:datapacket];
                    if(resu){
                        if([succsendend isEqualToString:attribute_00]){
                            // 如果发送成功
                            result = [self sendCommonData:check_succ_end_packet_2];
                            if(result == false){
                                [ErroruserInfo setObject:@"0320" forKey:@"ErrorCode"];
                                [[NSNotificationCenter defaultCenter] postNotificationName:fail_install_notify_name object:nil userInfo:ErroruserInfo];
                                return;
                            }
                        }
                    }else{
                        [[NSNotificationCenter defaultCenter] postNotificationName:data_send_fail_notify_name object:nil];
                        return;
                    }

                }
                
                
                if([is1101 isEqualToString:attribute_01]){
                    
                   result =  [self sendCommonData:send_1101_data_packet];
                    if(result == false){
                        [ErroruserInfo setObject:@"0321" forKey:@"ErrorCode"];
                        [[NSNotificationCenter defaultCenter] postNotificationName:fail_install_notify_name object:nil userInfo:ErroruserInfo];
                        return;
                    }
                }
                
                if([isspecdata isEqualToString:attribute_01]){
                    
                    result =  [self sendCommonData:send_spec_data_packet_1];
                    if(result == false){
                        [ErroruserInfo setObject:@"0322" forKey:@"ErrorCode"];
                        [[NSNotificationCenter defaultCenter] postNotificationName:fail_install_notify_name object:nil userInfo:ErroruserInfo];
                        return;
                    }
                    result =  [self sendCommonData:send_spec_data_packet_2];
                    if(result == false){
                        [ErroruserInfo setObject:@"0323" forKey:@"ErrorCode"];
                        [[NSNotificationCenter defaultCenter] postNotificationName:fail_install_notify_name object:nil userInfo:ErroruserInfo];
                        return;
                    }
                    result =  [self sendCommonData:send_spec_data_packet_3];
                    if(result == false){
                        [ErroruserInfo setObject:@"0324" forKey:@"ErrorCode"];
                        [[NSNotificationCenter defaultCenter] postNotificationName:fail_install_notify_name object:nil userInfo:ErroruserInfo];
                        return;
                    }
                    result =  [self sendCommonData:send_spec_data_packet_4];
                    if(result == false){
                        [ErroruserInfo setObject:@"0325" forKey:@"ErrorCode"];
                        [[NSNotificationCenter defaultCenter] postNotificationName:fail_install_notify_name object:nil userInfo:ErroruserInfo];
                        return;
                    }
                    result =  [self sendCommonData:send_spec_data_packet_5];
                    if(result == false){
                        [ErroruserInfo setObject:@"0326" forKey:@"ErrorCode"];
                        [[NSNotificationCenter defaultCenter] postNotificationName:fail_install_notify_name object:nil userInfo:ErroruserInfo];
                        return;
                    }
                    result =  [self sendCommonData:send_spec_data_packet_6];
                    if(result == false){
                        [ErroruserInfo setObject:@"0327" forKey:@"ErrorCode"];
                        [[NSNotificationCenter defaultCenter] postNotificationName:fail_install_notify_name object:nil userInfo:ErroruserInfo];
                        return;
                    }
                    result =  [self sendCommonData:send_spec_data_packet_7];
                    if(result == false){
                        [ErroruserInfo setObject:@"0328" forKey:@"ErrorCode"];
                        [[NSNotificationCenter defaultCenter] postNotificationName:fail_install_notify_name object:nil userInfo:ErroruserInfo];
                        return;
                    }
                }
                
            }
            
        }
        
        [[NSNotificationCenter defaultCenter] postNotificationName:ecu_file_done_install_notify_name object:nil userInfo:nil];
        //00000201：结尾条件1的选定，01是执行；00是不执行
        //00000202：结尾条件2的选定，01是执行；00是不执行
        //00000203：结尾条件3的选定，01是执行；00是不执行
        //00000204：结尾条件4的选定，01是执行；00是不执行
        
        tempdata = [file_data subdataWithRange:NSMakeRange(0x201, 1)];
        NSString * end1 = [NSData hexStringFromHexData:tempdata];
        
        tempdata = [file_data subdataWithRange:NSMakeRange(0x202, 1)];
        NSString * end2 = [NSData hexStringFromHexData:tempdata];
        
        tempdata = [file_data subdataWithRange:NSMakeRange(0x203, 1)];
        NSString * end3 = [NSData hexStringFromHexData:tempdata];
        
        tempdata = [file_data subdataWithRange:NSMakeRange(0x204, 1)];
        NSString * end4 = [NSData hexStringFromHexData:tempdata];
        
        NSLog(@"end1: %@,end2: %@,end3: %@,end4: %@",end1,end2,end3,end4);
        
        //00000210 - 0000021F：为结尾条件4的手动输入值，发送数据是：00 00 00 0e 00 01 f4 18 31 01 02 05 BB BB BB BB BB BB BB BB
        //210 - 217位（8位值）是对应的手动输入的地方
        
        tempdata = [file_data subdataWithRange:NSMakeRange(0x210, 0x21F-0x210 + 1)];
        NSString * handwrite = [[[NSData hexStringFromHexData:tempdata] lowercaseString] substringWithRange:NSMakeRange(0, 16)];
        
        
        //00000220 - 000002BF是第一段数据，以BD BD BD BD BD（5个BD结尾，这5个BD不发送）
        //000002C0 - 0000035F是第二段数据，以BD BD BD BD BD（5个BD结尾，这5个BD不发送）
        //00000360 - 000003FF是第二段数据，以BD BD BD BD BD（5个BD结尾，这5个BD不发送）
        tempdata = [file_data subdataWithRange:NSMakeRange(0x220, 0x2BF-0x220+1)];
        NSString * end2data1 = [[[[NSData hexStringFromHexData:tempdata] lowercaseString] stringByReplacingOccurrencesOfString:@"bdbdbd" withString:@""] componentsSeparatedByString:@"-"][0];
        
        tempdata = [file_data subdataWithRange:NSMakeRange(0x2C0, 0x2FF-0x2C0+1)];
        NSString * end2data2 = [[[[NSData hexStringFromHexData:tempdata] lowercaseString] stringByReplacingOccurrencesOfString:@"bdbdbd" withString:@"-"] componentsSeparatedByString:@"-"][0];
        
        tempdata = [file_data subdataWithRange:NSMakeRange(0x300, 0x35F-0x300+1)];
        NSString * end2data3 = [[[[NSData hexStringFromHexData:tempdata] lowercaseString] stringByReplacingOccurrencesOfString:@"bdbdbd" withString:@"-"] componentsSeparatedByString:@"-"][0];
        
        tempdata = [file_data subdataWithRange:NSMakeRange(0x360, 0x3FF-0x360+1)];
        NSString * end2data4 = [[[[NSData hexStringFromHexData:tempdata] lowercaseString] stringByReplacingOccurrencesOfString:@"bdbdbd" withString:@"-"] componentsSeparatedByString:@"-"][0];
        
        NSLog(@"handwrite: %@,end2data1: %@,end2data2: %@,end2data3: %@,end2data4:%@",handwrite,end2data1,end2data2,end2data3,end2data4);
        
        
        if([end1 isEqualToString:attribute_01]){
            
           BOOL result = [self sendCommonData:send_end_1_packet_1];
            if(result == false){
                [ErroruserInfo setObject:@"0329" forKey:@"ErrorCode"];
                [[NSNotificationCenter defaultCenter] postNotificationName:fail_install_notify_name object:nil userInfo:ErroruserInfo];
                return;
            }
            
            char * vinchar = (char*)[self.vinString dataUsingEncoding:NSUTF8StringEncoding].bytes;
            NSData * vinData = [NSData dataWithBytes:vinchar length:self.vinString.length];
            NSString * hexVin = [NSData hexStringFromHexData:vinData];
            NSString * datapcket = [send_end_1_packet_2_unit_1 stringByAppendingString:hexVin];
            result = [self sendCommonData:datapcket];
            if(result == false){
                [ErroruserInfo setObject:@"0330" forKey:@"ErrorCode"];
                [[NSNotificationCenter defaultCenter] postNotificationName:fail_install_notify_name object:nil userInfo:ErroruserInfo];
                return;
            }
            result = [self sendCommonData:send_end_1_packet_3];
            if(result == false){
                [ErroruserInfo setObject:@"0331" forKey:@"ErrorCode"];
                [[NSNotificationCenter defaultCenter] postNotificationName:fail_install_notify_name object:nil userInfo:ErroruserInfo];
                return;
            }
            result = [self sendCommonData:send_end_1_packet_4];
            if(result == false){
                [ErroruserInfo setObject:@"0332" forKey:@"ErrorCode"];
                [[NSNotificationCenter defaultCenter] postNotificationName:fail_install_notify_name object:nil userInfo:ErroruserInfo];
                return;
            }
            result = [self sendCommonData:send_end_1_packet_5];
            if(result == false){
                [ErroruserInfo setObject:@"0333" forKey:@"ErrorCode"];
                [[NSNotificationCenter defaultCenter] postNotificationName:fail_install_notify_name object:nil userInfo:ErroruserInfo];
                return;
            }
            result = [self sendCommonData:send_end_1_packet_6];
            if(result == false){
                [ErroruserInfo setObject:@"0334" forKey:@"ErrorCode"];
                [[NSNotificationCenter defaultCenter] postNotificationName:fail_install_notify_name object:nil userInfo:ErroruserInfo];
                return;
            }
            result = [self sendCommonData:send_end_1_packet_7];
            if(result == false){
                [ErroruserInfo setObject:@"0335" forKey:@"ErrorCode"];
                [[NSNotificationCenter defaultCenter] postNotificationName:fail_install_notify_name object:nil userInfo:ErroruserInfo];
                return;
            }
            result = [self sendCommonData:send_end_1_packet_8];
            if(result == false){
                [ErroruserInfo setObject:@"0336" forKey:@"ErrorCode"];
                [[NSNotificationCenter defaultCenter] postNotificationName:fail_install_notify_name object:nil userInfo:ErroruserInfo];
                return;
            }
        }
 
        if([end2 isEqualToString:attribute_01]){
            
            __block BOOL result = [self sendCommonData:send_end_2_packet_1];
            if(result == false){
                [ErroruserInfo setObject:@"0337" forKey:@"ErrorCode"];
                [[NSNotificationCenter defaultCenter] postNotificationName:fail_install_notify_name object:nil userInfo:ErroruserInfo];
                return;
            }
            result =  [self sendCommonData:send_end_2_packet_2];
            if(result == false){
                [[NSNotificationCenter defaultCenter] postNotificationName:tcp_security_timeout_notify_name object:nil];
                return;
            }
            
            OSSpinLockLock(&oslock);
     
            NetworkInterface * interface = [NetworkInterface getInterface];
            [interface getanquansuanfabtld:self.btldValue parmarsvar3:receiveanquan doneBlock:^(NSString * anquan){
                NSString * packetString = [sero_3_datapackt_anquan_prefix stringByAppendingString:anquan];
                result =  [self sendCommonData:packetString];
                OSSpinLockUnlock(&oslock);
            } withError:^(NSError * error){
                result = false;
                OSSpinLockUnlock(&oslock);
            }];
            OSSpinLockLock(&oslock);
            if(result == false){
                [ErroruserInfo setObject:@"0338" forKey:@"ErrorCode"];
                [[NSNotificationCenter defaultCenter] postNotificationName:fail_install_notify_name object:nil userInfo:ErroruserInfo];
                return;
            }
        }
        
       // [self sendCommonData:send_anquan_packet_req];
        
    
//        NSString * path = [[NSUserDefaults standardUserDefaults] objectForKey:vin_file_path];
        
        
        // NSString * path = [[NSBundle mainBundle] pathForResource:@"vin" ofType:@"caf"];
        
        NSString * infoText = [NSString stringWithContentsOfFile:cafdPath encoding:NSUTF8StringEncoding error:nil];
        
        // 这里需要使用第一次保存的cafd值，发送给硬件
        NSArray<NSString *> * startArray = [infoText componentsSeparatedByString:end_flag];
        NSString * contentString = [startArray firstObject];
        NSArray<NSString *> * endArray = [contentString componentsSeparatedByString:start_flag];
        contentString = [endArray lastObject];
        
        // 开始从文件中读取cafd的部分
        NSArray<NSString *> * cafdArray = [contentString componentsSeparatedByString:cafd_prefix];
        contentString = [cafdArray lastObject];
        
        NSArray<NSString *> * cafdString = [contentString componentsSeparatedByString:@"\n"];
        
        
        for (NSString * subString in cafdString) {
            if(subString.length > 0){
                NSString * dataString = [subString stringByReplacingOccurrencesOfString:@"18f462" withString:@"f4182e"];
                BOOL result = [self sendCommonData:dataString];
                if(result == false){
                    [ErroruserInfo setObject:@"0339" forKey:@"ErrorCode"];
                    [[NSNotificationCenter defaultCenter] postNotificationName:fail_install_notify_name object:nil userInfo:ErroruserInfo];
                    return;
                }
            }
            
        }
        
        if([end3 isEqualToString:attribute_01]){
            
            
        }else{
            
            
        }
        
        if([end4 isEqualToString:attribute_01]){
            
           BOOL result = [self sendCommonData:send_end_4_packet_1];
            if(result == false){
                [ErroruserInfo setObject:@"0340" forKey:@"ErrorCode"];
                [[NSNotificationCenter defaultCenter] postNotificationName:fail_install_notify_name object:nil userInfo:ErroruserInfo];
                return;
            }
            
            NSData * vinData = [NSData dataWithBytes:self.vinString.UTF8String length:self.vinString.length];
//            NSData * tst = [vin dataUsingEncoding:NSUTF8StringEncoding];
            NSString * hexData = [NSData hexStringFromHexData:vinData];
            hexData = [hexData substringFromIndex:hexData.length-14];
            NSString * dataPacket = [send_end_4_packet_2_unit_1 stringByAppendingString:hexData];
//            [self sendCommonData:send_end_4_packet_2_unit_1];
            result = [self sendCommonData:dataPacket];
            if(result == false){
                [ErroruserInfo setObject:@"0341" forKey:@"ErrorCode"];
                [[NSNotificationCenter defaultCenter] postNotificationName:fail_install_notify_name object:nil userInfo:ErroruserInfo];
                return;
            }
            result = [self sendCommonData:send_end_4_packet_3];
            if(result == false){
                [ErroruserInfo setObject:@"0342" forKey:@"ErrorCode"];
                [[NSNotificationCenter defaultCenter] postNotificationName:fail_install_notify_name object:nil userInfo:ErroruserInfo];                return;
            }
            result = [self sendCommonData:send_end_4_packet_4];
            if(result == false){
                [ErroruserInfo setObject:@"0343" forKey:@"ErrorCode"];
                [[NSNotificationCenter defaultCenter] postNotificationName:fail_install_notify_name object:nil userInfo:ErroruserInfo];
                return;
            }
            result = [self sendCommonData:send_end_4_packet_5];
            if(result == false){
                [ErroruserInfo setObject:@"0344" forKey:@"ErrorCode"];
                [[NSNotificationCenter defaultCenter] postNotificationName:fail_install_notify_name object:nil userInfo:ErroruserInfo];
                return;
            }
            result = [self sendCommonData:send_end_4_packet_6];
            if(result == false){
                [ErroruserInfo setObject:@"0345" forKey:@"ErrorCode"];
                [[NSNotificationCenter defaultCenter] postNotificationName:fail_install_notify_name object:nil userInfo:ErroruserInfo];
                return;
            }
        }

        NSArray * directorys = [path componentsSeparatedByString:@"/"];
        NSString * directoryName = directorys[directorys.count - 2];
        NSDictionary * dataDict = @{flash_stage:directoryName};
        [[NSNotificationCenter defaultCenter] postNotificationName:done_install_notify_name object:nil userInfo:dataDict];
        NSLog(@"发送安装完成通知");
    }
    
}

-(void)RecoveryCAFD:(NSString *)vin cafdPath:(NSString *)cafdpath {
    if(oslock){
        OSSpinLockUnlock(&oslock);
        oslock = nil;
    }
    
    oslock = OS_SPINLOCK_INIT;
    NSLog(@"开始刷新cafd完成开始加锁");
    OSSpinLockLock(&oslock);
    
    NSMutableDictionary *ErroruserInfo = [NSMutableDictionary dictionary];

   __block BOOL result =  [self sendCommonData:send_1101_data_packet];
    if(result == false){
        [ErroruserInfo setObject:@"0301" forKey:@"ErrorCode"];
        [[NSNotificationCenter defaultCenter] postNotificationName:fail_recovery_notify_name object:nil userInfo:ErroruserInfo];
        return;
    }
    result =  [self sendCommonData:@"000000050001f4df22f101"];
    if(result == false){
        [ErroruserInfo setObject:@"0302" forKey:@"ErrorCode"];
        [[NSNotificationCenter defaultCenter] postNotificationName:fail_recovery_notify_name object:nil userInfo:ErroruserInfo];
        return;
    }
    result = [self sendCommonData:@"000000040001f4df3e80"];
    if(result == false){
        [ErroruserInfo setObject:@"0303" forKey:@"ErrorCode"];
        [[NSNotificationCenter defaultCenter] postNotificationName:fail_recovery_notify_name object:nil userInfo:ErroruserInfo];
        return;
    }
    result = [self sendCommonData:@"000000050001f418222504"];
    if(result == false){
        [ErroruserInfo setObject:@"0304" forKey:@"ErrorCode"];
        [[NSNotificationCenter defaultCenter] postNotificationName:fail_recovery_notify_name object:nil userInfo:ErroruserInfo];
        return;
    }
    result = [self sendCommonData:@"000000050001f4df22f186"];
    if(result == false){
        [ErroruserInfo setObject:@"0305" forKey:@"ErrorCode"];
        [[NSNotificationCenter defaultCenter] postNotificationName:fail_recovery_notify_name object:nil userInfo:ErroruserInfo];
        return;
    }
    result = [self sendCommonData:@"000000040001f4df3e80"];
    if(result == false){
        [ErroruserInfo setObject:@"0306" forKey:@"ErrorCode"];
        [[NSNotificationCenter defaultCenter] postNotificationName:fail_recovery_notify_name object:nil userInfo:ErroruserInfo];
        return;
    }
    result = [self sendCommonData:@"000000050001f4df22f186"];
    if(result == false){
        [ErroruserInfo setObject:@"0307" forKey:@"ErrorCode"];
        [[NSNotificationCenter defaultCenter] postNotificationName:fail_recovery_notify_name object:nil userInfo:ErroruserInfo];
        return;
    }
    result = [self sendCommonData:@"000000040001f4df3e80"];
    if(result == false){
        [ErroruserInfo setObject:@"0308" forKey:@"ErrorCode"];
        [[NSNotificationCenter defaultCenter] postNotificationName:fail_recovery_notify_name object:nil userInfo:ErroruserInfo];
        return;
    }
    result = [self sendCommonData:@"000000050001f41822f101"];
    if(result == false){
        [ErroruserInfo setObject:@"0309" forKey:@"ErrorCode"];
        [[NSNotificationCenter defaultCenter] postNotificationName:fail_recovery_notify_name object:nil userInfo:ErroruserInfo];
        return;
    }
    result = [self sendCommonData:@"000000040001f4181001"];
    if(result == false){
        [ErroruserInfo setObject:@"0310" forKey:@"ErrorCode"];
        [[NSNotificationCenter defaultCenter] postNotificationName:fail_recovery_notify_name object:nil userInfo:ErroruserInfo];
        return;
    }
    result = [self sendCommonData:@"000000040001f4181003"];
    if(result == false){
        [ErroruserInfo setObject:@"0311" forKey:@"ErrorCode"];
        [[NSNotificationCenter defaultCenter] postNotificationName:fail_recovery_notify_name object:nil userInfo:ErroruserInfo];
        return;
    }
    result = [self sendCommonData:@"000000040001f4181041"];
    if(result == false){
        [ErroruserInfo setObject:@"0312" forKey:@"ErrorCode"];
        [[NSNotificationCenter defaultCenter] postNotificationName:fail_recovery_notify_name object:nil userInfo:ErroruserInfo];        return;
    }
//    [self sendCommonData:@"000000050001f418222504"];
    result = [self sendCommonData:send_end_2_packet_2];
    if(result == false){
        [[NSNotificationCenter defaultCenter] postNotificationName:tcp_security_timeout_notify_name object:nil];
        return;
    }
//    [self sendCommonData:send_spec_data_packet_1];
//    [self sendCommonData:send_end_1_packet_5];
//    [self sendCommonData:send_end_1_packet_6];
//
//    [self sendCommonData:send_end_1_packet_7];
//    [self sendCommonData:send_end_1_packet_8];
//    [self sendCommonData:send_end_2_packet_1];
//    [self sendCommonData:send_end_2_packet_2];
//
    
    OSSpinLockLock(&oslock);

    NetworkInterface * interface = [NetworkInterface getInterface];
    [interface getanquansuanfabtld:self.btldValue parmarsvar3:receiveanquan doneBlock:^(NSString * anquan){
        NSString * packetString = [sero_2_datapacket_3 stringByAppendingString:anquan];
        result = [self sendCommonData:packetString];
        OSSpinLockUnlock(&oslock);
    } withError:^(NSError * error){
        result = false;
        OSSpinLockUnlock(&oslock);
        
    }];
    OSSpinLockLock(&oslock);
    if(result == false){
        [ErroruserInfo setObject:@"0313" forKey:@"ErrorCode"];
        [[NSNotificationCenter defaultCenter] postNotificationName:fail_recovery_notify_name object:nil userInfo:ErroruserInfo];
        return;
    }
    // 这里是读取cafd文件并进行写入
   // NSString * path = [[NSUserDefaults standardUserDefaults] objectForKey:vin_file_path];
    
    // NSString * path = [[NSBundle mainBundle] pathForResource:@"vin" ofType:@"caf"];
    
    NSString * infoText = [NSString stringWithContentsOfFile:cafdpath encoding:NSUTF8StringEncoding error:nil];
    
    // 这里默认读取第一条存取的cafd数据
    NSArray<NSString *> * startArray = [infoText componentsSeparatedByString:end_flag];
    NSString * contentString = [startArray firstObject];
    NSArray<NSString *> * endArray = [contentString componentsSeparatedByString:start_flag];
    contentString = [endArray lastObject];
    
    // 开始从文件中读取cafd的部分
    NSArray<NSString *> * cafdArray = [contentString componentsSeparatedByString:cafd_prefix];
    contentString = [cafdArray lastObject];
    
    
    NSArray<NSString *> * cafdString = [contentString componentsSeparatedByString:@"\n"];
    
    
    for (NSString * subString in cafdString) {
        if(subString.length > 0){
            NSString * dataString = [subString stringByReplacingOccurrencesOfString:@"18f462" withString:@"f4182e"];
            result = [self sendCommonData:dataString];
            if(result == false){
                [ErroruserInfo setObject:@"0314" forKey:@"ErrorCode"];
                [[NSNotificationCenter defaultCenter] postNotificationName:fail_recovery_notify_name object:nil userInfo:ErroruserInfo];
                return;
            }
        }
        
    }
    
//    [self sendCommonData:send_end_4_packet_1];
//
//
//    NSLog(@" 传输的vin: %@",vin);
//    NSData * vinData = [NSData dataWithBytes:vin.UTF8String length:vin.length];
////            NSData * tst = [vin dataUsingEncoding:NSUTF8StringEncoding];
//    NSString * hexData = [NSData hexStringFromHexData:vinData];
//    hexData = [hexData substringFromIndex:hexData.length-14];
//    NSString * dataPacket = [send_end_4_packet_2_unit_1 stringByAppendingString:hexData];
////            [self sendCommonData:send_end_4_packet_2_unit_1];
//    [self sendCommonData:dataPacket];
//    [self sendCommonData:send_end_4_packet_3];
//    [self sendCommonData:send_end_4_packet_4];
    
    
    
   result = [self sendCommonData:@"000000060001f41831010f01"];
    if(result == false){
        [ErroruserInfo setObject:@"0315" forKey:@"ErrorCode"];
        [[NSNotificationCenter defaultCenter] postNotificationName:fail_recovery_notify_name object:nil userInfo:ErroruserInfo];
        return;
    }
        NSData * vinData = [NSData dataWithBytes:vin.UTF8String length:vin.length];
    //            NSData * tst = [vin dataUsingEncoding:NSUTF8StringEncoding];
        NSString * hexData = [NSData hexStringFromHexData:vinData];
        hexData = [hexData substringFromIndex:hexData.length-14];
        NSString * dataPacket = [send_end_4_packet_2_unit_1 stringByAppendingString:hexData];
   result = [self sendCommonData:dataPacket];
    if(result == false){
        [ErroruserInfo setObject:@"0316" forKey:@"ErrorCode"];
        [[NSNotificationCenter defaultCenter] postNotificationName:fail_recovery_notify_name object:nil userInfo:ErroruserInfo];
        return;
    }
   result = [self sendCommonData:@"000000050001f4182237fe"];
    if(result == false){
        [ErroruserInfo setObject:@"0317" forKey:@"ErrorCode"];
        [[NSNotificationCenter defaultCenter] postNotificationName:fail_recovery_notify_name object:nil userInfo:ErroruserInfo];
        return;
    }
   result = [self sendCommonData:@"000000040001f4181001"];
    if(result == false){
        [ErroruserInfo setObject:@"0318" forKey:@"ErrorCode"];
        [[NSNotificationCenter defaultCenter] postNotificationName:fail_recovery_notify_name object:nil userInfo:ErroruserInfo];
        return;
    }
   result = [self sendCommonData:@"000000040001f4df3e80"];
    if(result == false){
        [ErroruserInfo setObject:@"0319" forKey:@"ErrorCode"];
        [[NSNotificationCenter defaultCenter] postNotificationName:fail_recovery_notify_name object:nil userInfo:ErroruserInfo];
        return;
    }
   result = [self sendCommonData:@"000000050001f4df22f101"];
    if(result == false){
        [ErroruserInfo setObject:@"0320" forKey:@"ErrorCode"];
        [[NSNotificationCenter defaultCenter] postNotificationName:fail_recovery_notify_name object:nil userInfo:ErroruserInfo];
        return;
    }
   result = [self sendCommonData:@"000000040001f4df3e80"];
    if(result == false){
        [ErroruserInfo setObject:@"0321" forKey:@"ErrorCode"];
        [[NSNotificationCenter defaultCenter] postNotificationName:fail_recovery_notify_name object:nil userInfo:ErroruserInfo];
        return;
    }
   result = [self sendCommonData:@"000000060001f4df14ffffff"];
    if(result == false){
        [ErroruserInfo setObject:@"0322" forKey:@"ErrorCode"];
        [[NSNotificationCenter defaultCenter] postNotificationName:fail_recovery_notify_name object:nil userInfo:ErroruserInfo];
        return;
    }
    
    
    [[NSNotificationCenter defaultCenter] postNotificationName:done_recovery_notify_name object:nil];
    
}
@end
