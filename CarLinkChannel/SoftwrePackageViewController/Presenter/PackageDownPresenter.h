//
//  PackageDownPresenter.h
//  CarLinkChannel
//
//  Created by job on 2023/3/30.
//

#import <UIKit/UIKit.h>
#import "SoftwareDownloadView.h"
#import "PackageDownloadInteractive.h"
#import "informationView.h"
NS_ASSUME_NONNULL_BEGIN

@interface PackageDownPresenter : NSObject


@property (nonatomic, strong) UITableView * tableView;
@property (nonatomic, strong) SoftwareDownloadView * downloadView;
@property (nonatomic, strong) NSString * vinString;
@property (nonatomic, strong) NSString * binaryName;
@property (nonatomic, strong) informationView * infoView;

-(Boolean)checkFileConfig;
-(Boolean)getFileExists;
-(void)startFileHandler;
-(void)loadBinFile;
-(void)loadListString:(void(^)(NSString *liststring))doneBlock;
-(NSInteger)getRowCount;
-(NSString *)getRowString:(NSIndexPath *)indexPath;
-(NSString *)getTunePath:(NSIndexPath *)indexPath;
@end

NS_ASSUME_NONNULL_END
