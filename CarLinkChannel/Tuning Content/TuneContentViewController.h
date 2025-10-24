//
//  TuneContentViewController.h
//  CarLinkChannel
//
//  Created by job on 2023/3/31.
//

#import <UIKit/UIKit.h>
#import "UploadManager.h"
NS_ASSUME_NONNULL_BEGIN

@interface TuneContentViewController : UIViewController
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UITextView *contentTextView;
@property (nonatomic, strong) NSString * binFilePath;

@end

NS_ASSUME_NONNULL_END
