//
//  PrePareLoadingViewController.m
//  CarLinkChannel
//
//  Created by job on 2023/3/27.
//

#import "PrePareLoadingViewController.h"
#import "ConnectionViewController.h"

#import "NetworkInterface.h"
#import "UIImageView+Tool.h"
#import "XTDebugControl.h"

#import "AppDelegate.h"
#import "SpeedTestViewController.h"
#import <AVFoundation/AVFoundation.h>
static const DDLogLevel ddLogLevel = DDLogLevelVerbose;
@interface PrePareLoadingViewController()
{
    __block Boolean auth;
    NSString * mobile_ip;
    NSString * hardware_ip;
    NSString * vin;
}
@property (weak, nonatomic) IBOutlet UIImageView *startImageView;
@property (weak, nonatomic) IBOutlet UIImageView *statusImageView;

@property (weak, nonatomic) IBOutlet UILabel *infoLabel;
@property (weak, nonatomic) IBOutlet UILabel *vinLabel;
@property (weak, nonatomic) IBOutlet UILabel *localip;
@property (weak, nonatomic) IBOutlet UIButton *videoexportbutton;

@property(nonatomic,strong) UIView * bgView;
@property(nonatomic,strong) UIView * selectView;


@property(nonatomic, strong) AutoNetworkService *AutoNetworkManager;
@end

@implementation PrePareLoadingViewController

// This method is used to initialize the vehicle network
-(void)InitVehicleNetwork{
    self.AutoNetworkManager = [AutoNetworkService sharedInstance];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(ConnectVehicelSuccessNotify:) name:Vehicle_Connect_Success object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(addDisconnectNotify:) name:tcp_disconnect_notify_name object:nil];
}

-(void)ConnectVehicelSuccessNotify:(NSNotification *)notify{
    self->hardware_ip = notify.userInfo[@"Vehcile"];
    self->mobile_ip = notify.userInfo[@"Loacl"];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        [self.AutoNetworkManager WakeUpGetway];
        Boolean VinState = YES;
        
        while(VinState)
        {
            sleep(1);
            self->vin = [self.AutoNetworkManager ReadVehicleVIN];
            if(self->vin == nil)
            {
                VinState = YES;
            }
            else
            {
                VinState = NO;
            }
        }
        

        dispatch_async(dispatch_get_main_queue(), ^{
            NSLog(@"车辆已经连接");
            [self OpenConnectionButton];
            
            [[HttpClient alloc] sendGetWithUrl:Connect_Internet doneBlock:^(id data){
            } errBlock:^(NSError * error){}];
        });
    });
}
-(void)OpenConnectionButton{
    dispatch_async(dispatch_get_main_queue(), ^{
        NSLog(@"车辆已经连接");
        self.videoexportbutton.hidden = YES;
        self.infoLabel.text = [NSString stringWithFormat:@"Vehicle IP: %@",self->hardware_ip];
        self.localip.text = [NSString stringWithFormat:@"Local IP: %@",self->mobile_ip];
        self.vinLabel.text = [NSString stringWithFormat:@"VIN: %@",self->vin];
        [self.startButton setHidden:NO];
        [[self.statusImageView layer] removeAnimationForKey:@"gifAnimation"];
        UIImage * connectImage = [[UIImage imageNamed:@"PrepareimgConnect"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
        [self.statusImageView setImage:connectImage];
    });
}


-(void)viewDidLoad {
    DDLogInfo(@"\r\n\r\nNewly start");
    
    [UIApplication sharedApplication].idleTimerDisabled = YES;
    self.navigationController.navigationBar.barTintColor = [UIColor blackColor];
    [self startStartImageAnimation];
    [self requestprivacy];
    [self addSwapGesture];
    
    NSFileManager *  fm = [NSFileManager defaultManager];

    NSString * Racing = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)[0];
    Racing = [Racing stringByAppendingString:@"/Movie"];
    
    NSArray<NSString *> * files = [fm contentsOfDirectoryAtPath:Racing error:nil];
    NSLog(@"racing files: %@",files);

    
    NSString * moviepath = [Racing stringByAppendingPathComponent:@"11-07-2023 13:30_origin.mp4"];
    AVAsset * asset = [AVAsset assetWithURL:[NSURL fileURLWithPath:moviepath]];
    NSLog(@"------->  asset.duration: %f",CMTimeGetSeconds(asset.duration));
    
    self.bgView = [[UIView alloc] initWithFrame:[UIScreen mainScreen].bounds];
    UITapGestureRecognizer * tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(bgViewTap)];
    [self.bgView addGestureRecognizer:tap];
}
-(void)addDisconnectNotify:(NSNotification *) notify {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.navigationController popToRootViewControllerAnimated:YES];
        UIWindow * window;
        if([[UIDevice currentDevice].systemVersion floatValue] >= 15.0){
            NSSet<UIWindowScene *> *scenes =  [[UIApplication sharedApplication] connectedScenes];
            UIWindowScene * scene = [scenes allObjects].firstObject;
            window = scene.keyWindow;
        }else{
            window = [UIApplication sharedApplication].keyWindow;
        }
        NSLog(@"车辆断开连接");
        UIAlertController * controller = [UIAlertController alertControllerWithTitle:TCP_DISCONNECT_TITLE message:TCP_DISCONNECT_CONTENT preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction * action = [UIAlertAction actionWithTitle:DONE_WRITE_ALLOW_TEXT style:UIAlertActionStyleDefault handler:^(UIAlertAction * action){}];
        [controller addAction:action];
        [window.rootViewController presentViewController:controller animated:YES completion:^{
            self.videoexportbutton.hidden = NO;
            self.infoLabel.text = @"APP:3.0.7";
            self.localip.text = @"";
            self.vinLabel.text = @"";

            NSString * waiting = [[NSBundle mainBundle] pathForResource:@"red-waiting" ofType:@"gif"];
            NSURL * waitingurl = [NSURL fileURLWithPath:waiting];

            [self.statusImageView yh_setImage:waitingurl];
            
            [self.startButton setHidden:YES];
            
            AppDelegate *ape = (AppDelegate*)[[UIApplication sharedApplication] delegate];
            ape.state = 0;
        }];
    });
}
-(void)addSwapGesture {
    UISwipeGestureRecognizer * leftSwipteGesture = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(leftSwipteGesture)];
    leftSwipteGesture.direction = UISwipeGestureRecognizerDirectionLeft;
    [self.view addGestureRecognizer:leftSwipteGesture];
}
-(void)leftSwipteGesture {
    
    if(self.startButton.hidden == NO){
        UIStoryboard * storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
        ConnectionViewController * connectionView = [storyboard instantiateViewControllerWithIdentifier:@"ConnectionViewController"];
        [self.navigationController pushViewController:connectionView animated:YES];
    }
 
}

-(void)viewWillAppear:(BOOL)animated{
    
    self.videoexportbutton.hidden = NO;
    self.infoLabel.text = @"APP:3.0.7";
    self.localip.text = @"";
    self.vinLabel.text = @"";
    NSLog(@"首页刚弹出时");
    NSString * waiting = [[NSBundle mainBundle] pathForResource:@"red-waiting" ofType:@"gif"];
    NSURL * waitingurl = [NSURL fileURLWithPath:waiting];
    [self.statusImageView yh_setImage:waitingurl];
    
    [self.startButton setHidden:YES];
}
-(void)requestprivacy {
    [HTTPManager requestLocalNetworkAuthorization:^(BOOL isAuth){
        self->auth = isAuth;
        
        if(isAuth)
        {
            NSLog(@"request success");
            [self InitVehicleNetwork];
        }
        else{
            dispatch_async(dispatch_get_main_queue(), ^{
                UIAlertController * controller = [UIAlertController alertControllerWithTitle:@"Local Network Permission Required" message:@"To provide the best experience, please enable Local Network access for this app in your device settings." preferredStyle:UIAlertControllerStyleAlert];
                UIAlertAction * cancelaction = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleDefault handler:^(UIAlertAction * action){
                    [controller dismissViewControllerAnimated:YES completion:nil];
                }];
                UIAlertAction * yesAction = [UIAlertAction actionWithTitle:@"Open Settings" style:UIAlertActionStyleDefault handler:^(UIAlertAction * action){
                    
                    if([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:UIApplicationOpenSettingsURLString]]){
                        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:UIApplicationOpenSettingsURLString] options:@{} completionHandler:nil];

                    }else{
                        [controller dismissViewControllerAnimated:YES completion:nil];
                    }
                }];
                
                [controller addAction:cancelaction];
                [controller addAction:yesAction];
                [self presentViewController:controller animated:yesAction completion:nil];
            });
        }
    }];
    
}

-(void)startStartImageAnimation {
    static dispatch_source_t animation_t;

    //设置时间间隔
    NSTimeInterval period = 0.1f;
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    animation_t = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, queue);


    // 第一次会立刻执行，然后再间隔执行
    dispatch_source_set_timer(animation_t, dispatch_walltime(NULL, 0), period * NSEC_PER_SEC, 0);
    // 事件回调
    dispatch_source_set_event_handler(animation_t, ^{
        dispatch_async(dispatch_get_main_queue(), ^{
            CGAffineTransform t = self.startImageView.transform;
            [UIView animateWithDuration:0.1 delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
                self.startImageView.transform = CGAffineTransformRotate(t, M_PI / 26);
                
            } completion:^(BOOL finish){
           
            }];
        });
    });
        
    // 开启定时器
    if (animation_t) {
        dispatch_resume(animation_t);
    }
}

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender{

    if([segue.identifier isEqualToString:@"videoexport"]){
        
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"videoexport"];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
    
}
- (IBAction)exportSelectViewTap:(id)sender {
    [self.view addSubview:self.bgView];
    
    UIButton  * button = (UIButton *)sender;
    
    self.selectView = [[NSBundle mainBundle] loadNibNamed:@"exportVideoSelectView" owner:nil options:nil][0];
    self.selectView.frame = CGRectMake(button.frame.origin.x - 220 + 30, button.frame.origin.y - 60, 220, 60);
    
    UIButton * speedtetButton = [self.selectView viewWithTag:1];
    UIButton * racButton = [self.selectView viewWithTag:2];
    
    [speedtetButton addTarget:self action:@selector(exportspeedtest) forControlEvents:UIControlEventTouchUpInside];
    [racButton addTarget:self action:@selector(exportracingvideo) forControlEvents:UIControlEventTouchUpInside];
    
    [self.view addSubview:self.selectView];
}
-(void)bgViewTap {
    
    [self.bgView removeFromSuperview];
    [self.selectView removeFromSuperview];
}
-(void)exportspeedtest {
    
    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"fromHome"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    [[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"videoexport"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    UIStoryboard * storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    SpeedTestViewController * testViewController = [storyboard instantiateViewControllerWithIdentifier:@"SpeedTestViewController"];
    [self.navigationController pushViewController:testViewController animated:YES];
    
    
    [self.bgView removeFromSuperview];
    [self.selectView removeFromSuperview];
}
-(void)exportracingvideo {
    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"fromHome"];
    [[NSUserDefaults standardUserDefaults] synchronize];

    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"videoexport"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    UIStoryboard * storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    SpeedTestViewController * testViewController = [storyboard instantiateViewControllerWithIdentifier:@"SpeedTestViewController"];
    [self.navigationController pushViewController:testViewController animated:YES];
    
    
    [self.bgView removeFromSuperview];
    [self.selectView removeFromSuperview];
    
}
@end
