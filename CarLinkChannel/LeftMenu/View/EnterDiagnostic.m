//
//  EnterDiagnostic.m
//  CarLinkChannel
//
//  Created by job on 2023/5/4.
//

#import "EnterDiagnostic.h"

@implementation EnterDiagnostic
-(instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    self.frame = frame;
    if(self){
        self.DescriptionLabel.text = @"  If you encounter a problem that requires official technical support from ZD8,or want to purchase an activation code,please contact:\r\n  support@zd8.org";
    }
    return self;
}
-(void)setActiveDiagnosticMode {
    self.titleLabel.text = @"Active Diagnostic";
    self.DescriptionLabel.text = @" The vehicle has entered diagnostic mode. After hearing the prompt tone,observe the prompt below the dashboard to ensure that it has entered diagnostic moe.";
}
-(void)setEGSLearningReset{
    self.titleLabel.text = @"EGS Learining Reset";
    self.DescriptionLabel.text = @"Are you sure you want to reset EGS?\r\nThis function is that after a period of tuning,the vehicle's gearbox will automatically learn at 75km,causing a change in the driver's driving experience.Clicking on this button will restore the state of brushing";
//    self.okButton.titleLabel.text = @"Reset";
    [self.okButton setTitle:@"Reset" forState:UIControlStateNormal];
}
-(void)setClearFaultCodes {
    self.titleLabel.text = @"Clear Fault Codes";
    self.DescriptionLabel.text = @"Clicking OK will quickly delete the vehicle fault code";
}
- (IBAction)didTapOkButton:(id)sender {
    if(self.delegate && [self.delegate respondsToSelector:@selector(EnterViewdidTapOkButton)]){
        [self.delegate EnterViewdidTapOkButton];
    }
    
}
/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

@end
