//
//  TransportModeView.m
//  CarLinkChannel
//
//  Created by job on 2023/5/4.
//

#import "TransportModeView.h"

@implementation TransportModeView

-(instancetype)initWithFrame:(CGRect)frame{
    self = [super initWithFrame: frame];
    self.frame = frame;
    if(self){
        self.descriptionLabel.text = @"  When the vehicle enters transportation mode,the vehicle's power output will belimited.Click \"OK\" to cancel transportation mode\r\n It takes approximately 3 seconds to maintain the connected between the behicle and the iPhone.";
        
    }

    return self;
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/
- (IBAction)cancelButtonMethod:(id)sender {
    if(self.delegate && [self.delegate respondsToSelector:@selector(TransportModeViedidTapCancelButton)]){
        [self.delegate TransportModeViedidTapCancelButton];
    }
}

- (IBAction)okButtonMethod:(id)sender {
    
    if(self.delegate && [self.delegate respondsToSelector:@selector(TransportModeViedidTapOkButton)]){
        [self.delegate TransportModeViedidTapOkButton];
    }
}

@end
