//
//  LeftMenuView.h
//  CarLinkChannel
//
//  Created by job on 2023/4/24.
//

#import <UIKit/UIKit.h>

@protocol LeftMenuDelegate <NSObject>

-(void)didTapCloseButton;
-(void)didTapHomeButton;
-(void)didTapSpeedButton;
-(void)didTapSupportButton;
-(void)didTapRacingVideoRecord;

-(void)didTapEnterDiagnosticButton;
-(void)didTapTransportModeButton;
-(void)didTapECUHealthQueryButton;
-(void)didTapTCULearningResetButton;
-(void)didTapFaultCodeButton;
-(void)didTapClearFaultCodeButton;
-(void)didTapSyncDataButton;
@end

NS_ASSUME_NONNULL_BEGIN

@interface LeftMenuView : UIView
@property (nonatomic,strong) id<LeftMenuDelegate> delegate;
@property (strong, nonatomic)  UIView *stateView1;
@property (strong, nonatomic)  UIView *stateView2;
@property (strong, nonatomic)  UIView *stateView3;
@property (strong, nonatomic)  UIView *stateView4;
@property (strong, nonatomic)  UIView *stateView5;
@property (strong, nonatomic)  UIView *stateView6;
@property (strong, nonatomic)  UIView *stateView7;
@property (strong, nonatomic)  UIView *stateView8;
@property (strong, nonatomic)  UIView *stateView9;
@property (strong, nonatomic)  UIView *stateView10;
@property (strong, nonatomic)  UIView *stateViewRacing;
@end

NS_ASSUME_NONNULL_END
