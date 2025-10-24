//
//  EcuInstallView.h
//  CarLinkChannel
//
//  Created by job on 2023/3/30.
//

#import <UIKit/UIKit.h>
#import "BallRotationProgressBar.h"

NS_ASSUME_NONNULL_BEGIN

@interface EcuInstallView : UIView
@property (weak, nonatomic) IBOutlet UIImageView *LogoImageView;
@property (weak, nonatomic) IBOutlet BallRotationProgressBar *ballView;
@property (weak, nonatomic) IBOutlet UILabel *progresslabel;
@property (weak, nonatomic) IBOutlet UILabel *DataLabel;
@property (weak, nonatomic) IBOutlet UILabel *descriptionLabel;

-(void)initView;

-(void)initViewState;

-(void)beginLogoAnimation;

-(void)setNormalDescription;

-(void)setCafdDescription;

-(void)setPackageDataCount:(int)count;

-(void)setPackageDataInstallCount:(int)count;

-(void)setPackageTotalMount:(NSInteger)count;

-(void)setCurrentPackageInstallCount:(int)count;

-(void)setEcuFileDoneInstall;

-(void)setCurrentPackageInstallCount;
@end

NS_ASSUME_NONNULL_END
