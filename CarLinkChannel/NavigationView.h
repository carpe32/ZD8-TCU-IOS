//
//  NavigationView.h
//  CarLinkChannel
//
//  Created by job on 2023/3/27.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN


@protocol NavigationViewDelegate

-(void)didTapEscButton;

@end

@interface NavigationView : UIView
@property (weak, nonatomic) IBOutlet UILabel *titLabel;
@property (weak, nonatomic) IBOutlet UIButton *escButton;

@property (nonatomic,strong) id<NavigationViewDelegate> delegate;

@end

NS_ASSUME_NONNULL_END
