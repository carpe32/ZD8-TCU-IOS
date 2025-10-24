//
//  EnterDiagnostic.h
//  CarLinkChannel
//
//  Created by job on 2023/5/4.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@protocol EnterViewDelegate <NSObject>
-(void)EnterViewdidTapOkButton;
@end

@interface EnterDiagnostic : UIView
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UILabel *DescriptionLabel;
@property (weak, nonatomic) IBOutlet UIButton *okButton;
@property (nonatomic,weak) id<EnterViewDelegate> delegate;

-(void)setActiveDiagnosticMode;
-(void)setEGSLearningReset;
-(void)setClearFaultCodes;
@end

NS_ASSUME_NONNULL_END
