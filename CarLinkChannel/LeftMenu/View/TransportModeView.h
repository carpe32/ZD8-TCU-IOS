//
//  TransportModeView.h
//  CarLinkChannel
//
//  Created by job on 2023/5/4.
//

#import <UIKit/UIKit.h>

@protocol TransportModeViewDelegate <NSObject>
-(void)TransportModeViedidTapCancelButton;
-(void)TransportModeViedidTapOkButton;
@end

@interface TransportModeView : UIView
@property (weak, nonatomic) IBOutlet UILabel *descriptionLabel;
@property (weak, nonatomic) id<TransportModeViewDelegate> delegate;
@end
