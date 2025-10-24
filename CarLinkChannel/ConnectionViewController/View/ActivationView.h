//
//  ActivationView.h
//  CarLinkChannel
//
//  Created by job on 2023/3/29.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface ActivationView : UIView
@property (weak, nonatomic) IBOutlet UITextField *codeField;
@property (weak, nonatomic) IBOutlet UIButton *activationButton;
- (void)showView;
- (void)hideView;
@end

NS_ASSUME_NONNULL_END
