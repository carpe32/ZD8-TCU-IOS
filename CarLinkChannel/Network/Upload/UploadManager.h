//
//  UploadManager.h
//  TTS Tuning
//
//  Created by 刘润泽 on 2024/8/7.
//

#import <Foundation/Foundation.h>
#import "Constents.h"
#import "FTPManager.h"
#import "XmlProcess.h"
NS_ASSUME_NONNULL_BEGIN

@protocol DownloadProgressDelegate <NSObject>
-(void)ReceivePercent:(NSNumber *)Percent;
-(void)DownloadError;
-(void)DownloadSuccess:(NSString *)Path;
@end

@interface UploadManager : NSObject
+(instancetype)sharedInstance;
-(void)firstECUVersionUpload:(NSString *)Vin SvtInfo:(NSArray *)Svtinfo CafdInfo:(NSArray *)Cafdinfo;
-(MidSetBin *)CheckWhetherSetBIN;
-(BOOL)checkVehicleInfoFileAvailability:(NSString *)VehicleVin;
-(void)UploadMidFromServer;
-(void)DownloadFlashFile:(NSString *)FileName;
-(void)SaveAndUploadDownloadFileName:(NSString *)filename;
-(void)uploadFlashCellName:(NSString *)nameFile :(BOOL)State;
-(void)uploadFlashErrorInformation:(NSString *)OptionName :(NSString *)info :(NSString *)index :(NSString *)processName :(NSData *)Data :(uint8_t)Fid;
-(NSDictionary *)ReadFlashLastName;
-(void)UploadLicence:(NSString *)Code :(NSString *)level;
-(NSArray *)ReadServerCafd;
-(void)CheckAndCreateLogFolder:(NSString *)Vin;
-(void)uploadLogFile:(NSString *)FilePath;
-(NSString *)CheckFirstDownloadBinFile;
-(BOOL)DownloadCafdFile;
-(void)uploadMidFile;
-(void)SetBinStateAndFileName:(NSString *)State :(NSString *)BinName;

@property (nonatomic ,weak) id<DownloadProgressDelegate> delegate;
@end

NS_ASSUME_NONNULL_END
