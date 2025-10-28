//
//  TuneContentViewController.h
//  CarLinkChannel
//
//  重构版：显示文件夹说明并下载文件
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface TuneContentViewController : UIViewController

/// 从 SoftwarePackageViewController 传入
@property (nonatomic, strong) NSString *selectedFolderName;  // 选中的文件夹名（如 "Stage 1"）
@property (nonatomic, strong) NSString *displayContent;      // 显示内容（show.txt内容）
@property (nonatomic, strong) NSString *vinString;           // VIN码
@property (nonatomic, strong) NSString *license;             // 激活码

/// 旧属性（保留兼容）
@property (nonatomic, strong) NSString *binFilePath;

@end

NS_ASSUME_NONNULL_END
