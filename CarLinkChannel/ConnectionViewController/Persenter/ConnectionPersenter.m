//
//  ConnectionPersenter.m
//  CarLinkChannel
//
//  Created by job on 2023/5/4.
//

#import "ConnectionPersenter.h"
#import "EGSHealthViewController.h"
#import "FaultCodeViewController.h"
#import "SpeedTestViewController.h"

@interface ConnectionPersenter()
{
    int type;  // 1.
    UIView * bgView;
    FTPInteractive * interactive;
    UIScrollView * scrollView;
    
    AutoNetworkService *Network;
}

@end

@implementation ConnectionPersenter

-(void)addLeftView{
    type = 0;
    if(self->bgView == nil){
        self->bgView = [[UIView alloc] initWithFrame:[UIScreen mainScreen].bounds];
        self->bgView.backgroundColor = [UIColor blackColor];
        self->bgView.alpha = 0.4;
        UITapGestureRecognizer * tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(bgViewTaped)];
        [self->bgView addGestureRecognizer:tap];
    }
    [self.rootViewController.view addSubview:self->bgView];
    if(scrollView == nil){
        scrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(-300, 0, 300, [UIScreen mainScreen].bounds.size.height)];
        scrollView.showsVerticalScrollIndicator = false;
        scrollView.showsHorizontalScrollIndicator = false;
        scrollView.contentSize = CGSizeMake(300, 769);
        scrollView.backgroundColor = [UIColor blackColor];
    }
    if(self.leftMenuView == nil){
        //self.leftMenuView = [[LeftMenuView alloc] initWithFrame:CGRectMake(-300, 0, 300, [UIScreen mainScreen].bounds.size.height)];
        //self.leftMenuView = [[LeftMenuView alloc] init];
        self.leftMenuView = [self.leftMenuView initWithFrame:CGRectMake(0, 0, 300, [UIScreen mainScreen].bounds.size.height)];
        self.leftMenuView = [[NSBundle mainBundle] loadNibNamed:@"LeftMenuView" owner:self.leftMenuView options:nil][0];
        //self.leftMenuView = [self.leftMenuView initWithFrame:CGRectMake(0, 0, 300, [UIScreen mainScreen].bounds.size.height)];
        //self.leftMenuView.frame = CGRectMake(0, 0, 300, [UIScreen mainScreen].bounds.size.height);

        self.leftMenuView.delegate = self;
        [scrollView addSubview:self.leftMenuView];
    }
    if(self.enterDiagnostic == nil){
        //self.enterDiagnostic = [[EnterDiagnostic alloc] init];
        self.enterDiagnostic = [self.enterDiagnostic initWithFrame:CGRectMake(0, [UIScreen mainScreen].bounds.size.height, [UIScreen mainScreen].bounds.size.width, 300)];
        self.enterDiagnostic = [[NSBundle mainBundle] loadNibNamed:@"EnterDiagnostic" owner:self.enterDiagnostic options:nil][0];
        self.enterDiagnostic.delegate = self;
        //self.enterDiagnostic = [self.enterDiagnostic initWithFrame:CGRectMake(0, [UIScreen mainScreen].bounds.size.height, [UIScreen mainScreen].bounds.size.width, 300)];

//        [self.rootViewController.view addSubview:self.enterDiagnostic];
    }
    if(self.transportView == nil){
        //self.transportView = [[TransportModeView alloc] init];
        self.transportView.frame = CGRectMake(0, [UIScreen mainScreen].bounds.size.height, [UIScreen mainScreen].bounds.size.width, 240);
        self.transportView = [[NSBundle mainBundle] loadNibNamed:@"TransportModeView" owner:self.transportView options:nil][0];
        self.transportView.delegate = self;
        //self.transportView = [self.transportView initWithFrame:CGRectMake(0, [UIScreen mainScreen].bounds.size.height, [UIScreen mainScreen].bounds.size.width, 240)];
        //self.transportView.frame = CGRectMake(0, [UIScreen mainScreen].bounds.size.height, [UIScreen mainScreen].bounds.size.width, 240);
        
//        [self.rootViewController.view addSubview:self.transportView];
    }
    if(self.completeView == nil){
        //self.completeView = [[CompletedView alloc] init];
        self.completeView = [self.completeView initWithFrame:CGRectMake(0, [UIScreen mainScreen].bounds.size.height, 340, 220)];
        self.completeView = [[NSBundle mainBundle] loadNibNamed:@"CompletedView" owner:self.completeView options:nil][0];
        //self.completeView = [self.completeView initWithFrame:CGRectMake(0, [UIScreen mainScreen].bounds.size.height, 340, 220)];
        
    }

    [self.rootViewController.navigationController.view addSubview:self->scrollView];
    [UIView animateWithDuration:0.26 animations:^{
        self->scrollView.frame = CGRectMake(0, 10, 300, [UIScreen mainScreen].bounds.size.height);
    } completion:^(BOOL finish){}];
}
-(void)bgViewTaped {
    [self->scrollView removeFromSuperview];
    [self.transportView removeFromSuperview];
    [self.enterDiagnostic removeFromSuperview];
    [self.completeView removeFromSuperview];
    [self->bgView removeFromSuperview];
}
-(void)didTapCloseButton{
    [UIView animateWithDuration:0.26 animations:^{
        self->scrollView.frame = CGRectMake(0, 10, self->scrollView.frame.size.width, self->scrollView.frame.size.height);
    } completion:^(BOOL finish){
        [self->scrollView removeFromSuperview];
        [self->bgView removeFromSuperview];
    }];

}
-(void)didTapHomeButton{
    [UIView animateWithDuration:0.26 animations:^{
        self->scrollView.frame = CGRectMake(-300, 10, 300, [UIScreen mainScreen].bounds.size.height);
    } completion:^(BOOL finish){
        [self->scrollView removeFromSuperview];
        [self->bgView removeFromSuperview];

    }];

}
-(void)didTapSpeedButton{
    
    [UIView animateWithDuration:0.26 animations:^{
        self->scrollView.frame = CGRectMake(-300, 10, 300, [UIScreen mainScreen].bounds.size.height);
    } completion:^(BOOL finish){
        [self->scrollView removeFromSuperview];
        [self->bgView removeFromSuperview];
        
        [[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"fromHome"];
        [[NSUserDefaults standardUserDefaults] synchronize];
        
        [[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"videoexport"];
        [[NSUserDefaults standardUserDefaults] synchronize];
        UIStoryboard * storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
        SpeedTestViewController * speedViewController = [storyboard instantiateViewControllerWithIdentifier:@"SpeedTestViewController"];
        [self.rootViewController.navigationController pushViewController:speedViewController animated:YES];
    }];
    

}
-(void)didTapRacingVideoRecord{
    
    [UIView animateWithDuration:0.26 animations:^{
        self->scrollView.frame = CGRectMake(-300, 10, 300, [UIScreen mainScreen].bounds.size.height);
    } completion:^(BOOL finish){
        [self->scrollView removeFromSuperview];
        [self->bgView removeFromSuperview];
        
        [[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"fromHome"];
        [[NSUserDefaults standardUserDefaults] synchronize];
        
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"videoexport"];
        [[NSUserDefaults standardUserDefaults] synchronize];
        UIStoryboard * storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
        SpeedTestViewController * speedViewController = [storyboard instantiateViewControllerWithIdentifier:@"SpeedTestViewController"];
        [self.rootViewController.navigationController pushViewController:speedViewController animated:YES];
    }];
    
}
-(void)didTapSupportButton{
    
    [UIView animateWithDuration:0.26 animations:^{
        self->scrollView.frame = CGRectMake(-300, 10, 300, [UIScreen mainScreen].bounds.size.height);
    } completion:^(BOOL finish){
        [self->scrollView removeFromSuperview];
        [self.rootViewController.view addSubview:self.enterDiagnostic];
        [UIView animateWithDuration:0.26 animations:^{
            self.enterDiagnostic.frame = CGRectMake(0, [UIScreen mainScreen].bounds.size.height - 300, [UIScreen mainScreen].bounds.size.width, 300);
            
        } completion:^(BOOL finish){
//            [self.enterDiagnostic removeFromSuperview];
            
        }];
    }];
}
-(void)didTapEnterDiagnosticButton{
    
    type = 1;

    [UIView animateWithDuration:0.26 animations:^{
        self->scrollView.frame = CGRectMake(-300, 10, 300, [UIScreen mainScreen].bounds.size.height);
    } completion:^(BOOL finish){
        [self->scrollView removeFromSuperview];
        [self.rootViewController.view addSubview:self.enterDiagnostic];
        [self.enterDiagnostic setActiveDiagnosticMode];
        [UIView animateWithDuration:0.26 animations:^{
            self.enterDiagnostic.frame = CGRectMake(0, [UIScreen mainScreen].bounds.size.height - 300, [UIScreen mainScreen].bounds.size.width, 300);
            
        } completion:^(BOOL finish){
            
            
        }];
    }];


}
-(void)didTapFaultCodeButton{
//    type = 2;
    [UIView animateWithDuration:0.26 animations:^{
        self->scrollView.frame = CGRectMake(-300, 10, 300, [UIScreen mainScreen].bounds.size.height);
    } completion:^(BOOL finish){
        [self->bgView removeFromSuperview];
        [self->scrollView removeFromSuperview];
        
        FaultCodeViewController * faultController = [[UIStoryboard storyboardWithName:@"Main" bundle:nil] instantiateViewControllerWithIdentifier:@"FaultCodeViewController"];
        [self.rootViewController.navigationController pushViewController:faultController animated:YES];
    }];

}
-(void)didTapTransportModeButton{
    type = 2;
    [UIView animateWithDuration:0.26 animations:^{
        self->scrollView.frame = CGRectMake(-300, 10, 300, [UIScreen mainScreen].bounds.size.height);
    } completion:^(BOOL finish){
        [self->scrollView removeFromSuperview];
        [self.rootViewController.view addSubview:self.transportView];
        [UIView animateWithDuration:0.26 animations:^{
            self.transportView.frame = CGRectMake(0, [UIScreen mainScreen].bounds.size.height - 240, [UIScreen mainScreen].bounds.size.width, 240);
        } completion:^(BOOL finish){
            
//            [self.transportView removeFromSuperview];
        }];
    }];

}
-(void)didTapECUHealthQueryButton{
//    type = 4;
    [UIView animateWithDuration:0.26 animations:^{
        self->scrollView.frame = CGRectMake(-300, 10, 300, [UIScreen mainScreen].bounds.size.height);
    } completion:^(BOOL finish){
        [self->bgView removeFromSuperview];
        [self->scrollView removeFromSuperview];
        
        EGSHealthViewController * egsController = [[UIStoryboard storyboardWithName:@"Main" bundle:nil] instantiateViewControllerWithIdentifier:@"EGSHealthViewController"];
        [self.rootViewController.navigationController pushViewController:egsController animated:YES];
        
//        [self.rootViewController.view addSubview:self.enterDiagnostic];
//        [UIView animateWithDuration:0.26 animations:^{
//            self.enterDiagnostic.frame = CGRectMake(0, [UIScreen mainScreen].bounds.size.height - 300, [UIScreen mainScreen].bounds.size.width, 300);
//
//        } completion:^(BOOL finish){
////            [self.enterDiagnostic removeFromSuperview];
//
//        }];
    }];

    
}
-(void)didTapTCULearningResetButton{
    type = 4;
    [UIView animateWithDuration:0.26 animations:^{
        self->scrollView.frame = CGRectMake(-300, 10, 300, [UIScreen mainScreen].bounds.size.height);
    } completion:^(BOOL finish){
        [self->scrollView removeFromSuperview];
        [self.rootViewController.view addSubview:self.enterDiagnostic];
        [self.enterDiagnostic setEGSLearningReset];
        [UIView animateWithDuration:0.26 animations:^{
            self.enterDiagnostic.frame = CGRectMake(0, [UIScreen mainScreen].bounds.size.height - 300, [UIScreen mainScreen].bounds.size.width, 300);
            
        } completion:^(BOOL finish){
        }];
    }];

}
-(void)didTapClearFaultCodeButton{
    type = 3;
    [UIView animateWithDuration:0.26 animations:^{
        self->scrollView.frame = CGRectMake(-300, 10, 300, [UIScreen mainScreen].bounds.size.height);
    } completion:^(BOOL finish){
        [self->scrollView removeFromSuperview];
        [self.rootViewController.view addSubview:self.enterDiagnostic];
        [self.enterDiagnostic setClearFaultCodes];
        [UIView animateWithDuration:0.26 animations:^{
            self.enterDiagnostic.frame = CGRectMake(0, [UIScreen mainScreen].bounds.size.height - 300, [UIScreen mainScreen].bounds.size.width, 300);
            
        } completion:^(BOOL finish){
//            [self.enterDiagnostic removeFromSuperview];
            
        }];
    }];

}
-(void)didTapSyncDataButton{
    [UIView animateWithDuration:0.26 animations:^{
        self->scrollView.frame = CGRectMake(-300, 10, 300, [UIScreen mainScreen].bounds.size.height);
    } completion:^(BOOL finish){
        [self->scrollView removeFromSuperview];
        [self->bgView removeFromSuperview];
    }];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        UploadManager *uploadManager = [UploadManager sharedInstance];
        [uploadManager DownloadCafdFile];
    });
}
-(void)EnterViewdidTapOkButton{
    if(Network == nil)
        Network = [AutoNetworkService sharedInstance];
    if(type == 1){
        [self->Network SendEnterDiagnostic];
    }else if (type == 2){

    }else if (type == 3){
        [self->Network ClearFaultForVehicle];
    }else if (type == 4){
        [self->Network SendDataForegslearnreset];
    }
    NSLog(@"type : %d ",type);
    
    [UIView animateWithDuration:0.26 animations:^{
        self.enterDiagnostic.frame = CGRectMake(0, [UIScreen mainScreen].bounds.size.height, [UIScreen mainScreen].bounds.size.width, 300);
    } completion:^(BOOL finish){
        NSLog(@"现在动画收起，开始加载对勾符号");
        [self.enterDiagnostic removeFromSuperview];
        [self.rootViewController.navigationController.view addSubview:self.completeView];
        [self.completeView startAnimation];
        self.completeView.center = self.rootViewController.view.center;
        [self performSelector:@selector(dismissCompleteView) withObject:nil afterDelay:4 inModes:@[NSRunLoopCommonModes]];
    }];
}
-(void)dismissCompleteView {
    NSLog(@"现在对勾符号收起，动画结束");
    [self->bgView removeFromSuperview];
    [self.completeView removeFromSuperview];
}
-(void)TransportModeViedidTapCancelButton{
    [UIView animateWithDuration:0.26 animations:^{
        self.transportView.frame = CGRectMake(0, [UIScreen mainScreen].bounds.size.height, [UIScreen mainScreen].bounds.size.width, 240);
    } completion:^(BOOL finish){
        [self->bgView removeFromSuperview];
        [self.transportView removeFromSuperview];
    }];
}
-(void)TransportModeViedidTapOkButton{
    if(self->Network == nil)
        self->Network = [AutoNetworkService sharedInstance];
    
    [self->Network RemoveTransportMode];
    [UIView animateWithDuration:0.26 animations:^{
        self.transportView.frame = CGRectMake(0, [UIScreen mainScreen].bounds.size.height, [UIScreen mainScreen].bounds.size.width, 240);
    } completion:^(BOOL finish){
        [self.transportView removeFromSuperview];
        [self.rootViewController.navigationController.view addSubview:self.completeView];
        [self.completeView startAnimation];
        self.completeView.center = self.rootViewController.view.center;
        [self performSelector:@selector(dismissCompleteView) withObject:nil afterDelay:4 inModes:@[NSRunLoopCommonModes]];
    }];
    
}

@end
