//
//  CompletedView.h
//  CarLinkChannel
//
//  Created by job on 2023/5/6.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface CompletedView : UIView
@property (weak, nonatomic) IBOutlet UIImageView *stateImageView;
-(void)startAnimation;
@end

NS_ASSUME_NONNULL_END
