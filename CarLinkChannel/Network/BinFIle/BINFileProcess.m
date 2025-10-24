//
//  BINFileProcess.m
//  CarLinkChannel
//
//  Created by 刘润泽 on 2024/9/24.
//

#import "BINFileProcess.h"

@implementation BINFileProcess

-(BOOL)RegisterVinAndBINNameToServer:(NSString *)Vin BinName:(NSString *)fileName{
    
    LicenseKeyManager * KeyManager = [[LicenseKeyManager alloc] init];
    return [KeyManager RegisterBinName:Vin FileName:fileName error:nil timeout:5.0];
}

-(void)loadBinaryFile:(NSString *)Vin :(NSArray *)SvtMsg :(void(^)(NSString *))doneBlock withErrorBlock:(void(^)(NSError*))errorBlock{
    NSLog(@"开始读取binaryurl");
    LicenseKeyManager * KeyManager = [[LicenseKeyManager alloc] init];
    [KeyManager getListFileDoneBlock:^(NSString * listString){
        //NSLog(@"binaryFileName: %@",listString);
        dispatch_async(dispatch_get_global_queue(0, 0), ^{
            NSString * binaryFileName = [self getBinaryFileNameWithRuleString:listString :Vin :SvtMsg];
            //NSLog(@"读取的binaryFileName: %@",binaryFileName);
//            self.binaryFileName = binaryFileName;
            doneBlock(binaryFileName);
        });

    } withError:^(NSError * error){
        errorBlock(error);
        
    }];
}
-(NSString *)getBinaryFileNameWithRuleString:(NSString *)ruleString :(NSString *)VIN :(NSArray *)Svt{
    
    // 新版本的逻辑
    NSArray<NSString *> * listrule = [ruleString componentsSeparatedByString:@"#"];
    //NSLog(@"listStringt: %@",ruleString);
    
    // 遍历出的 binary 压缩包的名字
    NSString * binString = @"";
    // 规则数组
    NSMutableArray * ruleArray = [NSMutableArray array];
    for (NSString * itemrule in listrule) {
        if(itemrule.length <= 0)continue;
        // 先将文件名和规则区分开
        NSArray<NSString *> * item = [itemrule componentsSeparatedByString:@"@"];
        // 文件名
        NSString * binName = item[1];
        // 规则字符数组
        NSMutableDictionary * ruleDict = [NSMutableDictionary dictionary];
        NSArray<NSString *> * rulearray = [item[0] componentsSeparatedByString:@"&"];
        for (NSString * rule in rulearray) {
            NSArray<NSString *> * arrayrule = [rule componentsSeparatedByString:@":"];
            [ruleDict setObject:arrayrule[1] forKey:arrayrule[0]];
        }
        [ruleDict setObject:binName forKey:BINARY_FILE_KEY];

        [ruleArray addObject:ruleDict];
    }
    bool isfound = false;
    // 从找出的规则中搜索符合的规则
    for (NSDictionary * ruleItem in ruleArray) {
        if(isfound == true)break;
        
        NSString * swvalue = ruleItem[list_sw];
        NSString * vinvalue = ruleItem[list_vin];
        NSString * btldvalue = ruleItem[list_btld];
        NSString * binfilevalue = ruleItem[BINARY_FILE_KEY];
        
        NSString * bldtValue = [self makeStringWithNoZero:btldvalue];
        NSString * swString = [self makeStringWithNoZero:swvalue];
        NSString * vinprefix = [self makeStringWithNoZero:vinvalue];
        for (NSString * svtitme in Svt) {
            if(isfound == true)break;
            if([svtitme hasPrefix:list_btld]){
                NSArray<NSString *> * btldArray = [svtitme componentsSeparatedByString:svt_separated];
                if(btldArray.count >= 2){
                    NSString * svt = btldArray[1];
                    if([svt hasSuffix:bldtValue]){
                        for (NSString * switem in Svt) {
                            if ([switem hasPrefix:list_unkw]){
                                if([swString isEqualToString:list_unkw]){
                                    binString = binfilevalue;
                                    isfound = true;
                                    break;
                                }else{
                                    continue;
                                }
                            }else if([switem hasPrefix:list_sw]){
                                if([swString hasPrefix:list_unkw]){
                                    continue;
                                }
                                
                                NSArray<NSString *> * swdArray = [switem componentsSeparatedByString:svt_separated];
                                if(swdArray.count >= 2){
                                    NSString * sw = swdArray[1];
                                    if([sw hasSuffix:swString]){
                                        binString = binfilevalue;
                                        isfound = true;
                                        break;
                                    }
                                    if([swString hasSuffix:@"XXXX"]){
                                        if(isfound == false){
                                            binString = binfilevalue;
                                        }
                                    }
                                    if(VIN && VIN.length >= 10){
                                        
                                        NSString * tempVinfix = [VIN substringWithRange:NSMakeRange(3, 4)];
                                        if([tempVinfix hasSuffix:vinprefix]){
                                            binString = binfilevalue;
                                            isfound = true;
                                            break;
                                        }
                                    }
 
                                    if([vinprefix hasSuffix:@"XXXX"]){
                                        if(isfound == false){
                                            binString = binfilevalue;
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    return binString;
}

-(NSString *)makeStringWithNoZero:(NSString *)origin {
    NSString * bldtValue = origin;
    for (int i = 0; i < origin.length; i++) {
        NSString * subStr = [origin substringWithRange:NSMakeRange(i, 1)];
        if(![subStr isEqualToString:@"0"]){
            bldtValue = [origin substringFromIndex:i];
            break;
        }
    }
    return bldtValue;
}
@end
