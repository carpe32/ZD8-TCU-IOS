//
//  ConnectionPersenter.h
//  CarLinkChannel
//
//  Created by job on 2023/5/4.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "LeftMenuView.h"
#import "EnterDiagnostic.h"
#import "TransportModeView.h"
#import "CompletedView.h"
#import "FTPInteractive.h"
#import "ConnectionViewController.h"

@interface ConnectionPersenter : NSObject <LeftMenuDelegate,EnterViewDelegate,TransportModeViewDelegate>
@property (nonatomic,strong) ConnectionViewController * rootViewController;
@property (nonatomic,strong) LeftMenuView * leftMenuView;
@property (nonatomic,strong) EnterDiagnostic * enterDiagnostic;
@property (nonatomic,strong) TransportModeView * transportView;
@property (nonatomic,strong) CompletedView * completeView;

-(void)addLeftView;
@end
