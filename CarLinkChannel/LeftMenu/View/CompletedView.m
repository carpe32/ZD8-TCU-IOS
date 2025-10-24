//
//  CompletedView.m
//  CarLinkChannel
//
//  Created by job on 2023/5/6.
//

#import "CompletedView.h"
#import "UIImageView+Tool.h"

@implementation CompletedView

-(instancetype)initWithFrame:(CGRect)frame {
  self = [super initWithFrame:frame];
  self.frame = frame;
    if(self){
            
            
      }
    return self;
}
-(void)startAnimation {
    NSString * path = [[NSBundle mainBundle] pathForResource:@"wait" ofType:@"gif"];
    NSURL * waitingurl = [NSURL fileURLWithPath:path];
    [self.stateImageView yh_setImage:waitingurl];
}
/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

@end
