//
//  XmlProcess.m
//  TTS Tuning
//
//  Created by 刘润泽 on 2024/8/9.
//

#import "XmlProcess.h"

@implementation XmlProcess

//create cafd file
+(void)CreateGeneralXml:(NSString *)filePath{
    // 文件不存在，创建XML文件
    GDataXMLElement *rootElement = [GDataXMLElement elementWithName:@"information"];
    GDataXMLDocument *document = [[GDataXMLDocument alloc] initWithRootElement:rootElement];
    NSData *xmlData = document.XMLData;
    [xmlData writeToFile:filePath options:NSDataWritingAtomic error:nil];
}

+(void)CreateCafdFile:(NSString *)filePath{
    // 获取文件管理器实例
    NSFileManager *fileManager = [NSFileManager defaultManager];

    // 检查文件是否存在
    if (![fileManager fileExistsAtPath:filePath]) {
        // 文件不存在，创建文件
        BOOL success = [fileManager createFileAtPath:filePath contents:nil attributes:nil];
        
        if (success) {
            //NSLog(@"文件创建成功: %@", filePath);
        } else {
            //NSLog(@"文件创建失败");
        }
    } else {
        //NSLog(@"文件已存在: %@", filePath);
    }
}

+(void)AddSvtAndCafdInformationToCafd:(NSString *)filePath :(NSArray *)SvtMsg :(NSArray *)CafdMsg{
    NSData *xmlData = [NSData dataWithContentsOfFile:filePath];
    NSError *error = nil;
    GDataXMLDocument *CafdDocument = [[GDataXMLDocument alloc] initWithData:xmlData encoding:NSUTF8StringEncoding error:&error];
    
    NSArray *CafdElements = [CafdDocument nodesForXPath:@"/information/VersionInformation" error:&error];
    GDataXMLElement *cafdElement;
    if ([CafdElements count] == 0) {
        // 如果没有 VersionInformation 元素，创建一个
        GDataXMLElement *rootElement = [CafdDocument rootElement];
        if (!rootElement) {
            // 创建一个新的根元素
            rootElement = [GDataXMLElement elementWithName:@"information"];
            
            // 使用新的根元素创建一个新的 GDataXMLDocument
            CafdDocument = [[GDataXMLDocument alloc] initWithRootElement:rootElement];
        }
        cafdElement = [GDataXMLElement elementWithName:@"VersionInformation"];
        [rootElement addChild:cafdElement];
        
        // 手动刷新文档结构或重新获取cafElement
         CafdElements = [CafdDocument nodesForXPath:@"/information/VersionInformation" error:&error];
         cafdElement = [CafdElements firstObject];
    } else {
        // 如果有 VersionInformation 元素，使用第一个
        cafdElement = [CafdElements firstObject];
    }
    
    // 查找 Option 元素下的所有 Version 元素
    NSArray *selectionElements = [cafdElement elementsForName:@"Version"];
    NSInteger maxCount = 0;
    
    // 找到最大的 selectionX 计数值
    for (GDataXMLElement *element in selectionElements) {
        NSString *selectionName = [[element attributeForName:@"Count"] stringValue];
        NSInteger count = [[selectionName substringFromIndex:0] integerValue];
        if (count > maxCount) {
            maxCount = count;
        }
    }
    // 创建新的 selection 元素，编号为 maxCount + 1
    NSInteger newCount = maxCount + 1;
    NSString *newSelectionName = [NSString stringWithFormat:@"%ld", (long)newCount];
    GDataXMLElement *newSelectionElement = [GDataXMLElement elementWithName:@"Version"];
    
    // 添加新的 selection 的 name 属性
    [newSelectionElement addAttribute:[GDataXMLNode attributeWithName:@"Count" stringValue:newSelectionName]];
    // 添加当前时间属性
    NSString *currentDateString = [self GetCurrentTime];
    [newSelectionElement addAttribute:[GDataXMLNode attributeWithName:@"timestamp" stringValue:currentDateString]];
    
    NSString * SvtString = @"";
    NSMutableArray * svtarray = [NSMutableArray array];
    for (NSString * item in SvtMsg) {
        [svtarray addObject:item];
        SvtString = [SvtString stringByAppendingFormat:@" %@",item];
    }
    // 添加一个 Svt 字符串属性
    [newSelectionElement addAttribute:[GDataXMLNode attributeWithName:@"Svt" stringValue:SvtString]];

    NSInteger CafdCount = 0;
    for(NSString *Cafdinfo in CafdMsg)
    {
        NSString *xmlCafdIndexName = [NSString stringWithFormat:@"Cafd%ld",CafdCount];
        [newSelectionElement addAttribute:[GDataXMLNode attributeWithName:xmlCafdIndexName stringValue:Cafdinfo]];
        CafdCount++;
    }
    
    [cafdElement addChild:newSelectionElement];
    
    NSData *xmlDataUpdated = [CafdDocument XMLData];
    if (![xmlDataUpdated writeToFile:filePath atomically:YES]) {
        NSLog(@"Failed to save the updated XML document to the file.");
    } else {
        //NSLog(@"Updated XML document saved successfully to %@", filePath);
        
        // 打印整个 XML 文档的内容以确认更改
        //NSLog(@"Current XML Content after saving:\n%@", [CafdDocument rootElement].XMLString);
    }
}
+ (NSUInteger)countStartFlagInFile:(NSString *)filePath withStartFlag:(NSString *)startFlag {
    // 读取文件内容
    NSError *error = nil;
    NSString *fileContents = [NSString stringWithContentsOfFile:filePath encoding:NSUTF8StringEncoding error:&error];
    
    if (error) {
        NSLog(@"无法读取文件内容: %@", error.localizedDescription);
        return 0; // 返回 0 表示出错或未找到
    }
    
    // 使用 componentsSeparatedByString: 以 start_flag 为分隔符拆分字符串
    NSArray<NSString *> *components = [fileContents componentsSeparatedByString:startFlag];
    
    // 统计 start_flag 的次数
    // 注意：分割后的数组元素个数为 start_flag 出现次数 + 1
    // 如果文件内容为空或者 start_flag 不存在，则 count = 0
    NSUInteger count = components.count - 1;
    
    return count;
}

+(NSArray *)CheckCafdInfoFromFilePath:(NSString *)filePath{
    NSData *xmlData = [NSData dataWithContentsOfFile:filePath];
    NSError *error = nil;
    GDataXMLDocument *MidDocument = [[GDataXMLDocument alloc] initWithData:xmlData encoding:NSUTF8StringEncoding error:&error];
    GDataXMLElement *midElement;
    //create Svt element
    NSArray *MidElements = [MidDocument nodesForXPath:@"/information/VersionInformation" error:&error];
    if ([MidElements count] == 0) {
        return nil;
    } else {
        midElement = [MidElements firstObject];
    }
    NSArray *selectionElements = [midElement elementsForName:@"Version"];
    if([selectionElements count] == 0)
    {
        return nil;
    }
    

    NSInteger maxCount = 0;
    for (GDataXMLElement *element in selectionElements) {
        NSString *countString = [[element attributeForName:@"Count"] stringValue];
        NSInteger count = [countString integerValue];
        if (count > maxCount) {
            maxCount = count;
        }
    }
    for (NSInteger count = maxCount; count > 0; count--) {
        for (GDataXMLElement *element in selectionElements) {
            NSString *countString = [[element attributeForName:@"Count"] stringValue];
            NSInteger elementCount = [countString integerValue];
            if (elementCount == count) {
                NSString *SvtString = [[element attributeForName:@"Svt"] stringValue];
                NSRange range = [SvtString rangeOfString:@"CAFD"];
                
                NSString *resultString = nil;
                if (range.location != NSNotFound) {
                    NSRange substringRange = NSMakeRange(range.location, 24);
                    resultString = [SvtString substringWithRange:substringRange];
                }
                
                if(resultString !=nil)
                {
                    NSString *CafdFirstVersion = [resultString substringWithRange:NSMakeRange(5,8)];
                    if(![CafdFirstVersion isEqual:@"FFFFFFFF"])
                    {
                        NSMutableArray *cafdValuesArray = [NSMutableArray array];
                        
                        // 遍历element的所有属性
                        for (GDataXMLNode *attribute in [element attributes]) {
                            NSString *attributeName = [attribute name];
                            
                            // 判断属性名是否以 "Cafd" 开头
                            if ([attributeName hasPrefix:@"Cafd"]) {
                                // 提取属性名中的数字部分并按序号排序
                                NSInteger index = [[attributeName substringFromIndex:4] integerValue];
                                
                                // 确保数组的容量大于或等于index
                                while ([cafdValuesArray count] <= index) {
                                    [cafdValuesArray addObject:[NSNull null]]; // 用NSNull占位
                                }
                                
                                // 根据序号顺序存储属性值
                                NSString *attributeValue = [attribute stringValue];
                                [cafdValuesArray replaceObjectAtIndex:index withObject:attributeValue];
                            }
                        }
                        
                        // 移除所有的NSNull对象
                        [cafdValuesArray removeObjectIdenticalTo:[NSNull null]];
                        
                        return cafdValuesArray;
                    }
                }
            }
        }
    }
    return nil;
}

+ (BOOL)doesStringContainCAFD:(NSString *)inputString {
    // 检查是否包含 "CAFD"
     NSRange rangeOfCAFD = [inputString rangeOfString:@"CAFD"];
     if (rangeOfCAFD.location != NSNotFound) {
         // 获取 "CAFD" 后面的字符串，提取出第二部分 (0000023F 的部分)
         NSString *substringAfterCAFD = [inputString substringFromIndex:NSMaxRange(rangeOfCAFD)];
         // 按 "_" 分割
         NSArray *components = [substringAfterCAFD componentsSeparatedByString:@"_"];
         if (components.count > 1) {
             NSString *idPart = components[1]; // 取出 CAFD 后面的部分
             // 检查是否等于 "FFFFFFFF"
             if (![idPart isEqualToString:@"FFFFFFFF"]) {
                 return YES;
             }
         }
     }
     return NO;
}
+ (NSString *)findElementWithCount:(NSInteger)targetCount inArray:(NSArray *)stringArray {
    for (NSString *str in stringArray) {
        // 定义正则表达式来匹配 "Count:" 后面的数字
        NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"Count:\\s*(\\d+)" options:0 error:nil];
        // 在字符串中查找匹配的结果
        NSTextCheckingResult *match = [regex firstMatchInString:str options:0 range:NSMakeRange(0, [str length])];
        if (match) {
            // 提取匹配结果
            NSString *count = [str substringWithRange:[match rangeAtIndex:1]];
            NSInteger Thiscount = [count integerValue];
            
            // 如果找到的 count 等于目标参数，则返回此元素
            if (Thiscount == targetCount) {
                return str;
            }
        }
    }
    
    return nil; // 没有找到匹配的元素时返回 nil
}


+(void)AddSvtToMid:(NSString *)filePath :(NSArray *)SvtMsg{
    NSString * SvtString = @"";
    NSMutableArray * svtarray = [NSMutableArray array];
    for (NSString * item in SvtMsg) {
        [svtarray addObject:item];
        SvtString = [SvtString stringByAppendingFormat:@" %@",item];
    }
    
    NSData *xmlData = [NSData dataWithContentsOfFile:filePath];
    NSError *error = nil;
    GDataXMLDocument *MidDocument = [[GDataXMLDocument alloc] initWithData:xmlData encoding:NSUTF8StringEncoding error:&error];
    //create Svt element
    NSArray *MidElements = [MidDocument nodesForXPath:@"/information/Svt" error:&error];
    GDataXMLElement *midElement;
    if ([MidElements count] == 0) {
        GDataXMLElement *rootElement = [MidDocument rootElement];
        if (!rootElement) {
            rootElement = [GDataXMLElement elementWithName:@"information"];
            MidDocument = [[GDataXMLDocument alloc] initWithRootElement:rootElement];
        }
        midElement = [GDataXMLElement elementWithName:@"Svt"];
        [rootElement addChild:midElement];
        
        // 重新查询以获取新创建的 `Svt` 元素
        MidElements = [MidDocument nodesForXPath:@"/information/Svt" error:&error];
        midElement = [MidElements firstObject];
    } else {
        midElement = [MidElements firstObject];
    }
    
    //create DownloadBinFIle element
    NSArray *loadElements = [MidDocument nodesForXPath:@"/information/DownloadBinFile" error:&error];
    if ([loadElements count] == 0) {
        GDataXMLElement *rootElement = [MidDocument rootElement];
        
        GDataXMLElement *DownloadElement = [GDataXMLElement elementWithName:@"DownloadBinFile"];
        GDataXMLElement *BinfileElement = [GDataXMLElement elementWithName:@"UseBinFile"];
        [BinfileElement addAttribute:[GDataXMLNode attributeWithName:@"state" stringValue:@"0"]];
        [BinfileElement addAttribute:[GDataXMLNode attributeWithName:@"BinFileName" stringValue:@""]];
        [DownloadElement addChild:BinfileElement];
        [rootElement addChild:DownloadElement];
    }
    
    // 处理 RegisterSVT 元素
    NSArray *RegisterElements = [midElement elementsForName:@"RegisterSVT"];
    if([RegisterElements count] == 0) {
        GDataXMLElement *newRegisterSvtElement = [GDataXMLElement elementWithName:@"RegisterSVT"];
        GDataXMLElement *TimeElement = [GDataXMLElement elementWithName:@"time"];
        NSString *currentDateString = [self GetCurrentTime];
        [TimeElement setStringValue:currentDateString];
        GDataXMLElement *DataElement = [GDataXMLElement elementWithName:@"Data"];
        [DataElement setStringValue:SvtString];
        
        [newRegisterSvtElement addChild:TimeElement];
        [newRegisterSvtElement addChild:DataElement];
        [midElement addChild:newRegisterSvtElement];
    }
    
    // 处理 CurrentSVT 元素
    NSArray *CurrentElements = [midElement elementsForName:@"CurrentSVT"];
    if([CurrentElements count] == 0) {
        GDataXMLElement *newCurrentSvtElement = [GDataXMLElement elementWithName:@"CurrentSVT"];
        GDataXMLElement *TimeElement = [GDataXMLElement elementWithName:@"time"];
        GDataXMLElement *DataElement = [GDataXMLElement elementWithName:@"Data"];
        [newCurrentSvtElement addChild:TimeElement];
        [newCurrentSvtElement addChild:DataElement];
        [midElement addChild:newCurrentSvtElement];
        CurrentElements = [midElement elementsForName:@"CurrentSVT"];
    }
    
    // 更新 CurrentSVT 的 time 和 Data 元素
    GDataXMLElement *currentSvtElement = [CurrentElements firstObject];
    GDataXMLElement *currentTimeElement = [[currentSvtElement elementsForName:@"time"] firstObject];
    GDataXMLElement *currentDataElement = [[currentSvtElement elementsForName:@"Data"] firstObject];
    [currentTimeElement setStringValue:[self GetCurrentTime]];
    [currentDataElement setStringValue:SvtString];
    
    // 保存更新后的 XML 文档
    NSData *xmlDataUpdated = [MidDocument XMLData];
    if (![xmlDataUpdated writeToFile:filePath atomically:YES]) {
        NSLog(@"Failed to save the updated XML document to the file.");
    } else {
        //NSLog(@"Updated XML document saved successfully to %@", filePath);
        //NSLog(@"Current XML Content after saving:\n%@", [MidDocument rootElement].XMLString);
    }
}

+(void)AddLicenceinformation:(NSString *)filePath :(NSString *)Code :(NSString *)Type{
    NSData *xmlData = [NSData dataWithContentsOfFile:filePath];
    NSError *error = nil;
    GDataXMLDocument *MidDocument = [[GDataXMLDocument alloc] initWithData:xmlData encoding:NSUTF8StringEncoding error:&error];
    //create Svt element
    NSArray *MidElements = [MidDocument nodesForXPath:@"/information/Licence" error:&error];
    GDataXMLElement *midElement;
    if ([MidElements count] == 0) {
        GDataXMLElement *rootElement = [MidDocument rootElement];
        if (!rootElement) {
            rootElement = [GDataXMLElement elementWithName:@"information"];
            MidDocument = [[GDataXMLDocument alloc] initWithRootElement:rootElement];
        }
        midElement = [GDataXMLElement elementWithName:@"Licence"];
        [rootElement addChild:midElement];
        
        // 重新查询以获取新创建的 `Svt` 元素
        MidElements = [MidDocument nodesForXPath:@"/information/Licence" error:&error];
        midElement = [MidElements firstObject];
    } else {
        midElement = [MidElements firstObject];
    }
    
    GDataXMLElement *newSelectionElement = [GDataXMLElement elementWithName:@"licence"];
    NSString *currentDateString = [self GetCurrentTime];
    [newSelectionElement addAttribute:[GDataXMLNode attributeWithName:@"timestamp" stringValue:currentDateString]];
    [newSelectionElement addAttribute:[GDataXMLNode attributeWithName:@"code" stringValue:Code]];
    [newSelectionElement addAttribute:[GDataXMLNode attributeWithName:@"type" stringValue:Type]];
    [midElement addChild:newSelectionElement];
    
    NSData *xmlDataUpdated = [MidDocument XMLData];
    if (![xmlDataUpdated writeToFile:filePath atomically:YES]) {
        NSLog(@"Failed to save the updated XML document to the file.");
    } else {
        NSLog(@"Updated XML document saved successfully to %@", filePath);
        
        // 打印整个 XML 文档的内容以确认更改
        //NSLog(@"Current XML Content after saving:\n%@", [MidDocument rootElement].XMLString);
    }
}
//This method is used to proess Download mid file information
+(void)DownloadMidFileProess:(NSString *)MidFilePath :(NSString *)Vin{
    //This part is used to read the "UseBinFile"value in the server download file
    NSString *DownloadFilePath = [MidFilePath stringByAppendingPathComponent:@"Download"];
    DownloadFilePath = [DownloadFilePath stringByAppendingPathComponent:Vin];
    
    NSData *DownloadxmlData = [NSData dataWithContentsOfFile:DownloadFilePath];
    NSError *error = nil;
    GDataXMLDocument *DownloadDocument = [[GDataXMLDocument alloc] initWithData:DownloadxmlData encoding:NSUTF8StringEncoding error:&error];
    NSArray *UseBinFileNodes = [DownloadDocument nodesForXPath:@"/information/DownloadBinFile/UseBinFile" error:nil];
    if([UseBinFileNodes count] == 0)
        return;
        
    GDataXMLElement *UseBinFileElement = [UseBinFileNodes firstObject];
    GDataXMLNode *stateAttribute = [UseBinFileElement attributeForName:@"state"];
    NSString *StateValue = [stateAttribute stringValue];

    GDataXMLNode *FilenameAttribute = [UseBinFileElement attributeForName:@"BinFileName"];
    NSString *BinFIleName = [FilenameAttribute stringValue];
    
    //update local file
    NSString *loaclMinFilePath = [MidFilePath stringByAppendingPathComponent:Vin];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    
    if([fileManager fileExistsAtPath:loaclMinFilePath])//loaclly existing file
    {
        NSData *LocalxmlData = [NSData dataWithContentsOfFile:loaclMinFilePath];
        GDataXMLDocument *LoaclDocument = [[GDataXMLDocument alloc] initWithData:LocalxmlData encoding:NSUTF8StringEncoding error:&error];
        NSArray *LocalNodes = [LoaclDocument nodesForXPath:@"/information/DownloadBinFile" error:nil];
        if([LocalNodes count] != 0)
        {
            GDataXMLElement *informationElement = [LocalNodes firstObject];
            GDataXMLElement *UseBinFile =  [[informationElement elementsForName:@"UseBinFile"] firstObject];
            
            GDataXMLNode *StateAttribute = [UseBinFile attributeForName:@"state"];
            [StateAttribute setStringValue:StateValue];
            GDataXMLNode *FilenameAttribute = [UseBinFile attributeForName:@"BinFileName"];
            [FilenameAttribute setStringValue:BinFIleName];
            
            // 保存更新后的 XML 文档
            NSData *xmlDataUpdated = [LoaclDocument XMLData];
            if (![xmlDataUpdated writeToFile:loaclMinFilePath atomically:YES]) {
                NSLog(@"Failed to save the updated XML document to the file.");
            } else {
                NSLog(@"Updated XML document saved successfully to %@", loaclMinFilePath);
                //NSLog(@"Current XML Content after saving:\n%@", [LoaclDocument rootElement].XMLString);
            }
        }
    }
    else//no file exists locally
    {
        //copy Download file
        BOOL success = [fileManager copyItemAtPath:DownloadFilePath toPath:loaclMinFilePath error:nil];
        NSLog(@"copy %d",success);
    }
}

+(void)AddDownloadBinFileNameToMid:(NSString *)filePath :(NSString *)BinfileName{
    NSData *xmlData = [NSData dataWithContentsOfFile:filePath];
    NSError *error = nil;
    GDataXMLDocument *MidDocument = [[GDataXMLDocument alloc] initWithData:xmlData encoding:NSUTF8StringEncoding error:&error];
    NSArray *DownloadFileNodes = [MidDocument nodesForXPath:@"/information/DownloadBinFile" error:nil];
    GDataXMLElement *DownloadElement;
    if([DownloadFileNodes count] == 0)
    {
        GDataXMLElement *rootElement = [MidDocument rootElement];
        GDataXMLElement *DownloadBinElement = [GDataXMLElement elementWithName:@"DownloadBinFile"];
        [rootElement addChild:DownloadBinElement];
        DownloadFileNodes = [MidDocument nodesForXPath:@"/information/DownloadBinFile" error:nil];
        DownloadElement = [DownloadFileNodes firstObject];
    }
    else
    {
        DownloadElement = [DownloadFileNodes firstObject];
    }
    NSArray *selectionElements = [DownloadElement elementsForName:@"RecordFile"];
    NSInteger maxCount = 0;
    // 找到最大的 selectionX 计数值
    for (GDataXMLElement *element in selectionElements) {
        NSString *selectionName = [[element attributeForName:@"Count"] stringValue];
        NSInteger count = [[selectionName substringFromIndex:0] integerValue];
        if (count > maxCount) {
            maxCount = count;
        }
    }
    
    NSInteger newCount = maxCount + 1;
    NSString *newSelectionName = [NSString stringWithFormat:@"%ld", (long)newCount];
    GDataXMLElement *newSelectionElement = [GDataXMLElement elementWithName:@"RecordFile"];
    
    [newSelectionElement addAttribute:[GDataXMLNode attributeWithName:@"Count" stringValue:newSelectionName]];
    NSString *currentDateString = [self GetCurrentTime];
    [newSelectionElement addAttribute:[GDataXMLNode attributeWithName:@"timestamp" stringValue:currentDateString]];
    [newSelectionElement addAttribute:[GDataXMLNode attributeWithName:@"name" stringValue:BinfileName]];
    
    [DownloadElement addChild:newSelectionElement];
    NSData *xmlDataUpdated = [MidDocument XMLData];
    if (![xmlDataUpdated writeToFile:filePath atomically:YES]) {
        NSLog(@"Failed to save the updated XML document to the file.");
    } else {
        NSLog(@"Updated XML document saved successfully to %@", filePath);
        
        // 打印整个 XML 文档的内容以确认更改
        //NSLog(@"Current XML Content after saving:\n%@", [MidDocument rootElement].XMLString);
    }
}
+(void)AddOptionOrChangeStateToMid:(NSString *)filePath :(NSString *)OptionName :(BOOL)State{
    NSData *xmlData = [NSData dataWithContentsOfFile:filePath];
    NSError *error = nil;
    GDataXMLDocument *MidDocument = [[GDataXMLDocument alloc] initWithData:xmlData encoding:NSUTF8StringEncoding error:&error];
    //create Svt element
    NSArray *MidElements = [MidDocument nodesForXPath:@"/information/Option" error:&error];
    GDataXMLElement *midElement;
    if ([MidElements count] == 0) {
        GDataXMLElement *rootElement = [MidDocument rootElement];
        if (!rootElement) {
            rootElement = [GDataXMLElement elementWithName:@"information"];
            MidDocument = [[GDataXMLDocument alloc] initWithRootElement:rootElement];
        }
        midElement = [GDataXMLElement elementWithName:@"Option"];
        [rootElement addChild:midElement];
        
        // 重新查询以获取新创建的 `Svt` 元素
        MidElements = [MidDocument nodesForXPath:@"/information/Option" error:&error];
        midElement = [MidElements firstObject];
    } else {
        midElement = [MidElements firstObject];
    }
    
    NSArray *selectionElements = [midElement elementsForName:@"Selection"];
    NSInteger maxCount = 0;
    GDataXMLElement *maxSelectionElement = nil;
    // 找到最大的 selectionX 计数值
    for (GDataXMLElement *element in selectionElements) {
        NSString *selectionName = [[element attributeForName:@"Count"] stringValue];
        NSInteger count = [[selectionName substringFromIndex:0] integerValue];
        if (count > maxCount) {
            maxCount = count;
            maxSelectionElement = element;
        }
    }
    if(!State)
    {
        NSInteger newCount = maxCount + 1;
        NSString *newSelectionName = [NSString stringWithFormat:@"%ld", (long)newCount];
        GDataXMLElement *newSelectionElement = [GDataXMLElement elementWithName:@"Selection"];
        
        // 添加新的 selection 的 name 属性
        [newSelectionElement addAttribute:[GDataXMLNode attributeWithName:@"Count" stringValue:newSelectionName]];
        // 添加当前时间属性
        NSString *currentDateString = [self GetCurrentTime];
        [newSelectionElement addAttribute:[GDataXMLNode attributeWithName:@"timestamp" stringValue:currentDateString]];
        [newSelectionElement addAttribute:[GDataXMLNode attributeWithName:@"optionName" stringValue:OptionName]];
        [newSelectionElement addAttribute:[GDataXMLNode attributeWithName:@"State" stringValue:@"false"]];
        [midElement addChild:newSelectionElement];
    }
    else
    {
        if(maxSelectionElement)
        {
            NSString *existingOptionName = [[maxSelectionElement attributeForName:@"optionName"] stringValue];
            if ([existingOptionName isEqualToString:OptionName]) {
                // 修改 State 为 true
                GDataXMLNode *stateAttribute = [maxSelectionElement attributeForName:@"State"];
                if (stateAttribute) {
                    // 修改现有的属性值
                    [stateAttribute setStringValue:@"true"];
                } else {
                    // 如果属性不存在，则添加属性
                    [maxSelectionElement addAttribute:[GDataXMLNode attributeWithName:@"State" stringValue:@"true"]];
                }
            }
        }
    }
    
    NSData *xmlDataUpdated = [MidDocument XMLData];
    if (![xmlDataUpdated writeToFile:filePath atomically:YES]) {
        NSLog(@"Failed to save the updated XML document to the file.");
    } else {
        NSLog(@"Updated XML document saved successfully to %@", filePath);
        
        // 打印整个 XML 文档的内容以确认更改
        //NSLog(@"Current XML Content after saving:\n%@", [MidDocument rootElement].XMLString);
    }
}
+(void)AddOptionErrorMessage:(NSString *)filePath :(NSString *)OptionName :(NSString *)index :(NSString *)processName :(NSData *)ErrorInfo :(uint8_t)Fid{
    NSData *xmlData = [NSData dataWithContentsOfFile:filePath];
    NSError *error = nil;
    GDataXMLDocument *MidDocument = [[GDataXMLDocument alloc] initWithData:xmlData encoding:NSUTF8StringEncoding error:&error];
    //create Svt element
    NSArray *MidElements = [MidDocument nodesForXPath:@"/information/Option" error:&error];
    GDataXMLElement *midElement;
    if ([MidElements count] == 0) {
        GDataXMLElement *rootElement = [MidDocument rootElement];
        if (!rootElement) {
            rootElement = [GDataXMLElement elementWithName:@"information"];
            MidDocument = [[GDataXMLDocument alloc] initWithRootElement:rootElement];
        }
        midElement = [GDataXMLElement elementWithName:@"Option"];
        [rootElement addChild:midElement];
        
        // 重新查询以获取新创建的 `Svt` 元素
        MidElements = [MidDocument nodesForXPath:@"/information/Option" error:&error];
        midElement = [MidElements firstObject];
    } else {
        midElement = [MidElements firstObject];
    }
    
    NSArray *selectionElements = [midElement elementsForName:@"Selection"];
    NSInteger maxCount = 0;
    GDataXMLElement *maxSelectionElement = nil;
    // 找到最大的 selectionX 计数值
    for (GDataXMLElement *element in selectionElements) {
        NSString *selectionName = [[element attributeForName:@"Count"] stringValue];
        NSInteger count = [[selectionName substringFromIndex:0] integerValue];
        if (count > maxCount) {
            maxCount = count;
            maxSelectionElement = element;
        }
    }
    
    if(maxSelectionElement)
    {
        NSString *existingOptionName = [[maxSelectionElement attributeForName:@"optionName"] stringValue];
        if ([existingOptionName isEqualToString:OptionName]) {
            [maxSelectionElement addAttribute:[GDataXMLNode attributeWithName:@"Index" stringValue:index]];
            [maxSelectionElement addAttribute:[GDataXMLNode attributeWithName:@"FID" stringValue:[NSString stringWithFormat:@"%lX", (long)Fid]]];
            [maxSelectionElement addAttribute:[GDataXMLNode attributeWithName:@"ProcessName" stringValue:processName]];
            NSMutableString *hexString = [NSMutableString stringWithCapacity:ErrorInfo.length * 2];

            const unsigned char *dataBytes = (const unsigned char *)[ErrorInfo bytes];
            for (NSInteger i = 0; i < ErrorInfo.length; i++) {
                if (i > 0) {
                    [hexString appendString:@" "]; // 在每个字节之间添加空格
                }
                [hexString appendFormat:@"%02x", dataBytes[i]];
            }
            [maxSelectionElement addAttribute:[GDataXMLNode attributeWithName:@"ErrorData" stringValue:hexString]];
        }
    }

    
    NSData *xmlDataUpdated = [MidDocument XMLData];
    if (![xmlDataUpdated writeToFile:filePath atomically:YES]) {
        NSLog(@"Failed to save the updated XML document to the file.");
    } else {
        NSLog(@"Updated XML document saved successfully to %@", filePath);
        
        // 打印整个 XML 文档的内容以确认更改
        //NSLog(@"Current XML Content after saving:\n%@", [MidDocument rootElement].XMLString);
    }
    
    
}

+(NSDictionary *)ReadlastFlashFileName:(NSString *)filePath{
    NSData *xmlData = [NSData dataWithContentsOfFile:filePath];
    NSError *error = nil;
    GDataXMLDocument *MidDocument = [[GDataXMLDocument alloc] initWithData:xmlData encoding:NSUTF8StringEncoding error:&error];
    //create Svt element
    NSArray *MidElements = [MidDocument nodesForXPath:@"/information/Option" error:&error];
    GDataXMLElement *midElement;
    if ([MidElements count] == 0) {
        NSDictionary *dictionary = @{@"name": @"", @"state": @""};
        return dictionary;
    } else {
        midElement = [MidElements firstObject];
    }
    
    NSArray *selectionElements = [midElement elementsForName:@"Selection"];
    
    if([selectionElements count] == 0)
    {
        NSDictionary *dictionary = @{@"name": @"", @"state": @""};
        return dictionary;
    }
    NSInteger maxCount = 0;
    GDataXMLElement *maxSelectionElement = nil;
    // 找到最大的 selectionX 计数值
    for (GDataXMLElement *element in selectionElements) {
        NSString *selectionName = [[element attributeForName:@"Count"] stringValue];
        NSInteger count = [[selectionName substringFromIndex:0] integerValue];
        if (count > maxCount) {
            maxCount = count;
            maxSelectionElement = element;
        }
    }
    
    if(maxSelectionElement)
    {
        NSString *ReadName = [[maxSelectionElement attributeForName:@"optionName"] stringValue];
        NSString *ReadState =[[maxSelectionElement attributeForName:@"State"] stringValue];
        NSDictionary *dictionary = @{@"name": ReadName, @"state": ReadState};
        return dictionary;
    }

    return nil;
}
+(NSString *)GetCurrentTime{
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
    return [dateFormatter stringFromDate:[NSDate date]];
}

+(MidSetBin *)ReadWhetherSetBin:(NSString *)XmlPath{
    MidSetBin *ResultState = [[MidSetBin alloc] init];
    NSData *xmlData = [NSData dataWithContentsOfFile:XmlPath];
    NSError *error = nil;
    GDataXMLDocument *DownloadDocument = [[GDataXMLDocument alloc] initWithData:xmlData encoding:NSUTF8StringEncoding error:&error];
    NSArray *UseBinFileNodes = [DownloadDocument nodesForXPath:@"/information/DownloadBinFile/UseBinFile" error:nil];
    if([UseBinFileNodes count] == 0)
    {
        ResultState.status = ResponseXmlMidNoNeedSetFile;
        return ResultState;
    }
        
    GDataXMLElement *UseBinFileElement = [UseBinFileNodes firstObject];
    GDataXMLNode *stateAttribute = [UseBinFileElement attributeForName:@"state"];
    NSString *StateValue = [stateAttribute stringValue];

    GDataXMLNode *FilenameAttribute = [UseBinFileElement attributeForName:@"BinFileName"];
    NSString *BinFIleName = [FilenameAttribute stringValue];
    
    if([StateValue isEqual:@"0"])
    {
        ResultState.status = ResponseXmlMidNoNeedSetFile;
        return ResultState;
    }
    else
    {
        ResultState.status = ResponseXmlMidNeedSetFile;
        ResultState.BINName = BinFIleName;
        return ResultState;
    }
}

+(BOOL)WriteStateAndBinFileName:(NSString *)XmlPath
                        state:(NSString *)state
                   binFileName:(NSString *)binFileName {
    // 读取现有的 XML 数据
    NSData *xmlData = [NSData dataWithContentsOfFile:XmlPath];
    NSError *error = nil;
    GDataXMLDocument *xmlDoc = [[GDataXMLDocument alloc] initWithData:xmlData encoding:NSUTF8StringEncoding error:&error];
    
    if (error) {
        NSLog(@"Error loading XML: %@", error.localizedDescription);
        return NO;
    }
    
    // 获取需要修改的节点
    NSArray *useBinFileNodes = [xmlDoc nodesForXPath:@"/information/DownloadBinFile/UseBinFile" error:nil];
    GDataXMLElement *useBinFileElement = [useBinFileNodes firstObject];
    
    // 如果没有找到 UseBinFile 元素，创建一个新的节点
    if (!useBinFileElement) {
        useBinFileElement = [GDataXMLElement elementWithName:@"UseBinFile"];
        [useBinFileElement addAttribute:[GDataXMLNode attributeWithName:@"state" stringValue:state]];
        [useBinFileElement addAttribute:[GDataXMLNode attributeWithName:@"BinFileName" stringValue:binFileName]];
        
        // 添加新的元素到根节点
        GDataXMLElement *downloadBinFileElement = [xmlDoc.rootElement elementsForName:@"DownloadBinFile"].firstObject;
        if (!downloadBinFileElement) {
            downloadBinFileElement = [GDataXMLElement elementWithName:@"DownloadBinFile"];
            [xmlDoc.rootElement addChild:downloadBinFileElement];
        }
        [downloadBinFileElement addChild:useBinFileElement];
    } else {
        // 如果已找到 UseBinFile 元素，更新属性值
        GDataXMLNode *stateAttribute = [useBinFileElement attributeForName:@"state"];
        [stateAttribute setStringValue:state];
        
        GDataXMLNode *filenameAttribute = [useBinFileElement attributeForName:@"BinFileName"];
        [filenameAttribute setStringValue:binFileName];
    }
    
    // 将修改后的 XML 保存回文件
    BOOL success = [xmlDoc.XMLData writeToFile:XmlPath atomically:YES];
    //NSLog(@"Current XML Content after saving:\n%@", [xmlDoc rootElement].XMLString);
    return success;
}


+(NSString *)ReadDownloadBinFile:(NSString *)XmlPath{
    NSData *xmlData = [NSData dataWithContentsOfFile:XmlPath];
    NSError *error = nil;
    GDataXMLDocument *DownloadDocument = [[GDataXMLDocument alloc] initWithData:xmlData encoding:NSUTF8StringEncoding error:&error];
    if(DownloadDocument !=nil)
    {
        GDataXMLElement *rootElement = [DownloadDocument rootElement];
        GDataXMLElement *DownElement = [[rootElement elementsForName:@"DownloadBinFile"] firstObject];
        NSArray *selectionElements = [DownElement elementsForName:@"RecordFile"];
        
        NSInteger maxCount = 0;
        GDataXMLElement *maxSelectionElement = nil;
        // 找到最大的 selectionX 计数值
        for (GDataXMLElement *element in selectionElements) {
            NSString *selectionName = [[element attributeForName:@"Count"] stringValue];
            NSInteger count = [[selectionName substringFromIndex:0] integerValue];
            if (count > maxCount) {
                maxCount = count;
                maxSelectionElement = element;
            }
        }
        
        if(maxSelectionElement)
        {
            return [[maxSelectionElement attributeForName:@"name"] stringValue];
        }
    }
    return nil;
}

+(NSString *)deserializeIsValidDataFromXML:(NSData *)xmlData{
    NSError *error = nil;
    GDataXMLDocument *DownloadDocument = [[GDataXMLDocument alloc] initWithData:xmlData encoding:NSUTF8StringEncoding error:&error];
    if(DownloadDocument !=nil)
    {
        GDataXMLElement *rootElement = [DownloadDocument rootElement];
        GDataXMLElement *newsElement = [[rootElement elementsForName:@"News"] firstObject];
        GDataXMLElement *contentElement = [[newsElement elementsForName:@"Content"] firstObject];
        return [contentElement stringValue];
    }
    
    return nil;
}

+ (NSString *)valueForElement:(NSString *)elementName inNewsFromXMLData:(NSData *)xmlData {
    NSError *error = nil;

    // 用 GDataXMLDocument 解析 NSData
    GDataXMLDocument *doc = [[GDataXMLDocument alloc] initWithData:xmlData encoding:NSUTF8StringEncoding error:&error];
    if (error) {
        NSLog(@"解析 XML 失败: %@", error.localizedDescription);
        return nil;
    }

    // 获取根节点
    GDataXMLElement *rootElement = [doc rootElement];

    // 找到 <News> 节点
    NSArray *newsArray = [rootElement elementsForName:@"News"];
    if (newsArray.count == 0) {
        NSLog(@"未找到 <News> 节点");
        return nil;
    }

    GDataXMLElement *newsElement = [newsArray firstObject];

    // 找到 <News> 下的目标子节点
    NSArray *targetElements = [newsElement elementsForName:elementName];
    if (targetElements.count == 0) {
        NSLog(@"未找到 <News> 下的 <%@> 节点", elementName);
        return nil;
    }

    // 返回子节点的文本内容
    NSString *value = [[targetElements firstObject] stringValue];
    return value;
}



@end


@implementation MidSetBin
@end
