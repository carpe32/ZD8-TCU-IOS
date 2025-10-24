//
//  XmlProcess.h
//  TTS Tuning
//
//  Created by 刘润泽 on 2024/8/9.
//

#import <Foundation/Foundation.h>
#import "GDataXMLNode.h"
NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, ResponseXmlMidReadUseBin) {
    ResponseXmlMidNeedSetFile,   // need set
    ResponseXmlMidNoNeedSetFile     //no need
};

@interface MidSetBin : NSObject
@property (nonatomic, assign) ResponseXmlMidReadUseBin status;
@property (nonatomic, strong) NSString *BINName;
@end


@interface XmlProcess : NSObject
+(void)CreateGeneralXml:(NSString *)filePath;
+(void)CreateCafdFile:(NSString *)filePath;
+(void)AddSvtAndCafdInformationToCafd:(NSString *)filePath :(NSArray *)SvtMsg :(NSArray *)CafdMsg;
+(void)AddSvtToMid:(NSString *)filePath :(NSArray *)SvtMsg;
+(void)DownloadMidFileProess:(NSString *)MidFilePath :(NSString *)Vin;
+(MidSetBin *)ReadWhetherSetBin:(NSString *)XmlPath;
+(void)AddDownloadBinFileNameToMid:(NSString *)filePath :(NSString *)BinfileName;
+(void)AddOptionOrChangeStateToMid:(NSString *)filePath :(NSString *)OptionName :(BOOL)State;
+(void)AddOptionErrorMessage:(NSString *)filePath :(NSString *)OptionName :(NSString *)index :(NSString *)processName :(NSData *)ErrorInfo :(uint8_t)Fid;
+(NSDictionary *)ReadlastFlashFileName:(NSString *)filePath;
+(void)AddLicenceinformation:(NSString *)filePath :(NSString *)Code :(NSString *)Type;
+(NSArray *)CheckCafdInfoFromFilePath:(NSString *)filePath;
+(NSString *)deserializeIsValidDataFromXML:(NSData *)xmlData;
+(NSString *)ReadDownloadBinFile:(NSString *)XmlPath;
+(BOOL)WriteStateAndBinFileName:(NSString *)XmlPath
                        state:(NSString *)state
                    binFileName:(NSString *)binFileName ;
+ (NSString *)valueForElement:(NSString *)elementName inNewsFromXMLData:(NSData *)xmlData;
@end


NS_ASSUME_NONNULL_END
