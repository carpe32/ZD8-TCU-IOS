//
//  SoftwarePackageViewController.h
//  CarLinkChannel
//
//  重构版：使用新API获取文件列表
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface SoftwarePackageViewController : UIViewController

/// 从上一个界面传入
@property (nonatomic, strong) NSString *vinString;
@property (nonatomic, strong) NSString *binaryName;
@property (nonatomic, strong) NSArray *VehicleSvt;

@end

NS_ASSUME_NONNULL_END
