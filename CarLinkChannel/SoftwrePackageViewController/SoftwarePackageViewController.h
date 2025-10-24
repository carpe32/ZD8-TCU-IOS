//
//  SoftwarePackageViewController.h
//  CarLinkChannel
//
//  Created by job on 2023/3/29.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface SoftwarePackageViewController : UIViewController
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (nonatomic, strong) NSString * vinString;
@property (nonatomic, strong) NSString * binaryName;
@property (nonatomic, strong) NSArray *VehicleSvt;

@end

NS_ASSUME_NONNULL_END
