//
//  SofawareDownloadView.h
//  CarLinkChannel
//
//  Created by job on 2023/3/29.
//

#import <UIKit/UIKit.h>
#import "UploadManager.h"
NS_ASSUME_NONNULL_BEGIN

@interface SoftwareDownloadView : UIView
@property (weak, nonatomic) IBOutlet UITextView *descTextView;
@property (weak, nonatomic) IBOutlet UIProgressView *progressView;

@property (nonatomic, strong) NSString * BinName;

-(void)initView;
@end

NS_ASSUME_NONNULL_END
