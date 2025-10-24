//
//  LeftMenuView.m
//  CarLinkChannel
//
//  Created by job on 2023/4/24.
//

#import "LeftMenuView.h"
#import "EnterDiagnostic.h"

@interface LeftMenuView()
{
    UIButton * selectbutton;
    UIView * selectview;
}

@end

@implementation LeftMenuView

- (nullable instancetype)initWithCoder:(NSCoder *)coder{
    self = [super initWithCoder:coder];
    self.stateView1 = [self viewWithTag:1];
    self.stateView2 = [self viewWithTag:2];
    self.stateView3 = [self viewWithTag:3];
    self.stateView4 = [self viewWithTag:4];
    self.stateView5 = [self viewWithTag:5];
    self.stateView6 = [self viewWithTag:6];
    self.stateView7 = [self viewWithTag:7];
    self.stateView8 = [self viewWithTag:8];
    self.stateView9 = [self viewWithTag:9];
    self.stateView10 = [self viewWithTag:10];
    self.stateViewRacing = [self viewWithTag:100];
    NSLog(@"leftView initWithCode");
    return self;
}

- (IBAction)HomeButtonMethod:(id)sender {
    UIButton * button = (UIButton *)sender;

    button.selected = YES;
    selectbutton.selected = NO;
    selectbutton = button;
    selectview.backgroundColor = [UIColor whiteColor];
    self.stateView1.backgroundColor = [UIColor colorWithRed:61/255.0 green:117/255.0 blue:169/255.0 alpha:1.0];
    selectview = self.stateView1;
    
    
    if(self.delegate && [self.delegate respondsToSelector:@selector(didTapHomeButton)]){
        [self.delegate didTapHomeButton];
    }
}


- (IBAction)SpeedTestMethod:(id)sender {
    UIButton * button = (UIButton *)sender;
    button.selected = YES;
    selectbutton.selected = NO;
    selectbutton = button;
    selectview.backgroundColor = [UIColor whiteColor];
    self.stateView2.backgroundColor = [UIColor colorWithRed:61/255.0 green:117/255.0 blue:169/255.0 alpha:1.0];
    selectview = self.stateView2;
    if(self.delegate && [self.delegate respondsToSelector:@selector(didTapSpeedButton)]){
        [self.delegate didTapSpeedButton];
    }
}
- (IBAction)RacingVideoRecordMethod:(id)sender {
    
    UIButton * button = (UIButton *)sender;

    button.selected = YES;
    selectbutton.selected = NO;
    selectbutton = button;
    selectview.backgroundColor = [UIColor whiteColor];
    self.stateViewRacing.backgroundColor = [UIColor colorWithRed:61/255.0 green:117/255.0 blue:169/255.0 alpha:1.0];
    selectview = self.stateViewRacing;
    if(self.delegate && [self.delegate respondsToSelector:@selector(didTapSpeedButton)]){
        [self.delegate didTapRacingVideoRecord];
    }
}

- (IBAction)CloseButtonMethod:(id)sender {
    selectbutton.selected = NO;
    selectview.backgroundColor = [UIColor whiteColor];
    selectbutton = nil;
    selectview = nil;
    if(self.delegate && [self.delegate respondsToSelector:@selector(didTapCloseButton)]){
        [self.delegate didTapCloseButton];
    }
}

- (IBAction)supportButtonMethod:(id)sender {
    UIButton * button = (UIButton *)sender;

    button.selected = YES;
    selectbutton.selected = NO;
    selectbutton = button;
    selectview.backgroundColor = [UIColor whiteColor];
    self.stateView3.backgroundColor = [UIColor colorWithRed:61/255.0 green:117/255.0 blue:169/255.0 alpha:1.0];
    selectview = self.stateView3;
    if(self.delegate && [self.delegate respondsToSelector:@selector(didTapSupportButton)]){
        [self.delegate didTapSupportButton];
    }
}
- (IBAction)enterDiagnosticButtonMethod:(id)sender {
    UIButton * button = (UIButton *)sender;

    button.selected = YES;
    selectbutton.selected = NO;
    selectbutton = button;
    selectview.backgroundColor = [UIColor whiteColor];
    self.stateView4.backgroundColor = [UIColor colorWithRed:61/255.0 green:117/255.0 blue:169/255.0 alpha:1.0];
    selectview = self.stateView4;
    if(self.delegate && [self.delegate respondsToSelector:@selector(didTapEnterDiagnosticButton)]){
        [self.delegate didTapEnterDiagnosticButton];
    }
}

- (IBAction)transportModeButtonMethod:(id)sender {
    UIButton * button = (UIButton *)sender;

    button.selected = YES;
    selectbutton.selected = NO;
    selectbutton = button;
    selectview.backgroundColor = [UIColor whiteColor];
    self.stateView5.backgroundColor = [UIColor colorWithRed:61/255.0 green:117/255.0 blue:169/255.0 alpha:1.0];
    selectview = self.stateView5;
    if(self.delegate && [self.delegate respondsToSelector:@selector(didTapTransportModeButton)]){
        [self.delegate didTapTransportModeButton];
    }
}
- (IBAction)healthQueryButtonMethod:(id)sender {
    UIButton * button = (UIButton *)sender;
//    if(button == selectbutton){
//        return;
//    }
    button.selected = YES;
    selectbutton.selected = NO;
    selectbutton = button;
    selectview.backgroundColor = [UIColor whiteColor];
    self.stateView6.backgroundColor = [UIColor colorWithRed:61/255.0 green:117/255.0 blue:169/255.0 alpha:1.0];
    selectview = self.stateView6;
    if(self.delegate && [self.delegate respondsToSelector:@selector(didTapECUHealthQueryButton)]){
        [self.delegate didTapECUHealthQueryButton];
    }
}
- (IBAction)egslearningresetButtonMethod:(id)sender {
    UIButton * button = (UIButton *)sender;
    button.selected = YES;
    selectbutton.selected = NO;
    selectbutton = button;
    selectview.backgroundColor = [UIColor whiteColor];
    self.stateView7.backgroundColor = [UIColor colorWithRed:61/255.0 green:117/255.0 blue:169/255.0 alpha:1.0];
    selectview = self.stateView7;
    if(self.delegate && [self.delegate respondsToSelector:@selector(didTapTCULearningResetButton)]){
        [self.delegate didTapTCULearningResetButton];
    }
}
- (IBAction)faultcodedtcButtonMethod:(id)sender {
    UIButton * button = (UIButton *)sender;

    button.selected = YES;
    selectbutton.selected = NO;
    selectbutton = button;
    selectview.backgroundColor = [UIColor whiteColor];
    self.stateView8.backgroundColor = [UIColor colorWithRed:61/255.0 green:117/255.0 blue:169/255.0 alpha:1.0];
    selectview = self.stateView8;
    if(self.delegate && [self.delegate respondsToSelector:@selector(didTapFaultCodeButton)]){
        [self.delegate didTapFaultCodeButton];
    }
}
- (IBAction)clearFaultCodeButtonMethod:(id)sender {
    UIButton * button = (UIButton *)sender;

    button.selected = YES;
    selectbutton.selected = NO;
    selectbutton = button;
    selectview.backgroundColor = [UIColor whiteColor];
    self.stateView9.backgroundColor = [UIColor colorWithRed:61/255.0 green:117/255.0 blue:169/255.0 alpha:1.0];
    selectview = self.stateView9;
    if(self.delegate && [self.delegate respondsToSelector:@selector(didTapClearFaultCodeButton)]){
        [self.delegate didTapClearFaultCodeButton];
    }
}

- (IBAction)syncDataButtonMethod:(id)sender {
    UIButton * button = (UIButton *)sender;

    button.selected = YES;
    selectbutton.selected = NO;
    selectbutton = button;
    selectview.backgroundColor = [UIColor whiteColor];
    self.stateView10.backgroundColor = [UIColor colorWithRed:61/255.0 green:117/255.0 blue:169/255.0 alpha:1.0];
    selectview = self.stateView10;
    if(self.delegate && [self.delegate respondsToSelector:@selector(didTapSyncDataButton)]){
        [self.delegate didTapSyncDataButton];
    }
}

@end
