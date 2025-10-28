//
//  TuneContentViewController.h
//  CarLinkChannel
//
//  显示文件夹说明，下载并解密，发送数据给刷写模块
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface TuneContentViewController : UIViewController

/// 从上一个界面传入的数据
@property (nonatomic, strong) NSString *selectedFolderName;  // 选中的文件夹名称
@property (nonatomic, strong) NSString *displayContent;      // 显示内容（show.txt）
@property (nonatomic, strong) NSString *vinString;           // 车架号
@property (nonatomic, strong) NSString *license;             // 激活码

/// 兼容旧版本的属性
@property (nonatomic, strong, nullable) NSString *binFilePath;  // 旧版本的本地文件路径

@end

NS_ASSUME_NONNULL_END
