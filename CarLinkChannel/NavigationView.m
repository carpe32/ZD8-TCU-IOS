//
//  NavigationView.m
//  CarLinkChannel
//
//  Created by job on 2023/3/27.
//

#import "NavigationView.h"

@implementation NavigationView

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

-(void)initNavigation {
    
    
    
}

- (IBAction)escButtonTap:(id)sender {
    if(self.delegate){
        [self.delegate didTapEscButton];
    }

}

@end
