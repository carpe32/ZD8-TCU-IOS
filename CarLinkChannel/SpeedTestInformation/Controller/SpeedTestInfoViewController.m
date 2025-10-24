//
//  SpeedTestInfoViewController.m
//  CarLinkChannel
//
//  Created by job on 2023/5/23.
//

#import "SpeedTestInfoViewController.h"


@interface SpeedTestInfoViewController ()<UITextFieldDelegate>
{
    NSArray * ecuArray1;
    NSArray * ecuArray2;
    NSArray * tcuArray1;
    NSArray * tcuArray2;
    NSString * ecuTuningString;
    NSString * tcuTuningString;
    int type;      // 1. ecu tuning    2.  tcu tuning
    int step;      // 1. 品牌           2.  阶数
//    ECUInteractive * ecuInteractive;
}
@property (nonatomic,strong) UILabel * vinLabel;
@property (nonatomic,strong) UILabel * brandLabel;
@property (nonatomic,strong) UILabel * vehicleLable;
@property (nonatomic,strong) UILabel * eduLabel;
@property (nonatomic,strong) UILabel * tcuLabel;
@property (nonatomic,strong) UIButton * vehicleButton;
@property (nonatomic,strong) UIButton * ecuButton;
@property (nonatomic,strong) UIButton * tcuButton;
@property (nonatomic,strong) UIView * bgView;
@property (nonatomic,strong) UIView * tcutingingView;
@property (nonatomic,strong) UITextField * vehicleField;
@end

@implementation SpeedTestInfoViewController


-(void)didTapEscButton {
    
    [self.navigationController popViewControllerAnimated:YES];
}
- (void)viewDidLoad {
    [super viewDidLoad];
    
    ecuTuningString = @"";
    tcuTuningString = @"";
    ecuArray1 = @[@"Original",@"ZD8",@"BM3",@"MHD"];
    ecuArray2 = @[@"Unknown",@"Stage 1",@"Stage 2",@"Stage 3",@"Stage 4",@"Stage 5"];
    
    tcuArray1 = @[@"Original",@"ZD8",@"XHP"];
    tcuArray2 = @[@"Unknown",@"Stage 1",@"Stage 2",@"Stage 3",@"Stage 4",@"Stage 5"];
    
    UIScrollView * scrollView = [self.view viewWithTag:666];
    
    UIView * v = [[NSBundle mainBundle] loadNibNamed:@"SpeedSetInformationView" owner:nil options:nil][0];
    v.frame = CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, 210);
    
    UIView * containerV = [[UIView alloc] initWithFrame:CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, 210)];
    [containerV addSubview:v];
    [scrollView addSubview:containerV];
    
    
    self.bgView = [[UIView alloc] initWithFrame:CGRectMake(0, [UIScreen mainScreen].bounds.size.height, [UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height)];
    self.bgView.backgroundColor = [UIColor blackColor];
    self.bgView.alpha = 0.4;
    [self.view addSubview:self.bgView];
    
    UITapGestureRecognizer * tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(bgViewTarget)];
    [self.bgView addGestureRecognizer:tap];
    
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[[UIImage imageNamed:@"escimg"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal] style:UIBarButtonItemStyleDone target:self action:@selector(didTapEscButton)];
    
    self.tcutingingView = [[NSBundle mainBundle] loadNibNamed:@"TcuTunningView" owner:nil options:nil][0];
    self.tcutingingView.frame = CGRectMake(0, [UIScreen mainScreen].bounds.size.height, [UIScreen mainScreen].bounds.size.width, 399);
    [self.view addSubview:self.tcutingingView];
    
    
    self.vinLabel = [v viewWithTag:1];
    self.brandLabel = [v viewWithTag:2];
    self.vehicleLable = [v viewWithTag:3];
    self.eduLabel = [v viewWithTag:4];
    self.tcuLabel = [v viewWithTag:5];
    self.vehicleButton = [v viewWithTag:6];
    self.ecuButton = [v viewWithTag:7];
    self.tcuButton = [v viewWithTag:8];
    
    self.vehicleField = [v viewWithTag:10];
    self.vehicleField.hidden = YES;
    self.vehicleField.delegate = self;
    
//    ecuInteractive = [ECUInteractive loadInteractive];
//    self.vinString = ecuInteractive.vin;
    self.vinLabel.text = self.vinString;
    
    // 这里从userdefault 里面读取
    NSString * vechicletype = [[NSUserDefaults standardUserDefaults] objectForKey:@"vehicleType"];
    NSString * ecutuning = [[NSUserDefaults standardUserDefaults] objectForKey:@"ecutuning"];
    NSString * tcutuning = [[NSUserDefaults standardUserDefaults] objectForKey:@"tcutuning"];
    if(vechicletype == nil){
        self.vehicleLable.text = @"Edit";
    }else{
        self.vehicleLable.text = vechicletype;
    }
    if(ecutuning == nil){
        self.eduLabel.text = @"";
    }else{
        self.eduLabel.text = ecutuning;
    }
    
    if(tcutuning == nil){
        self.tcuLabel.text = @"";
    }else{
        self.tcuLabel.text = tcutuning;
    }
    UITapGestureRecognizer * tap_view = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(viewTapped)];
    [self.view addGestureRecognizer:tap_view];
    
//    self.view.layer.cornerRadius = 6;
//    self.view.layer.masksToBounds = YES;
    
    [self.vehicleButton addTarget:self action:@selector(editVehiceButtonFunc:) forControlEvents:UIControlEventTouchUpInside];
    [self.ecuButton addTarget:self action:@selector(EcuTuningButtonFunc:) forControlEvents:UIControlEventTouchUpInside];
    [self.tcuButton addTarget:self action:@selector(TcuTuningButtonFunc:) forControlEvents:UIControlEventTouchUpInside];
    UIButton * cancelButton = [self.tcutingingView viewWithTag:166];
    
    [cancelButton addTarget:self action:@selector(informationViewcancelButtonFunc:) forControlEvents:UIControlEventTouchUpInside];
    UIButton * doneButton = [self.tcutingingView viewWithTag:1666];
    
    [doneButton addTarget:self action:@selector(informationViewdoneButtonFunc:) forControlEvents:UIControlEventTouchUpInside];
}
-(void)viewTapped {
    [self.vehicleField resignFirstResponder];
//    [self editVehiceButtonFunc:self.vehicleButton];
    self.vehicleButton.selected = false;
    self.vehicleLable.hidden = NO;
    self.vehicleField.hidden = YES;
    [self.vehicleField resignFirstResponder];
    if(self.vehicleField.text.length > 0){
        self.vehicleLable.text = self.vehicleField.text;
        [[NSUserDefaults standardUserDefaults] setObject:self.vehicleField.text forKey:@"vehicleType"];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
}
-(void)editVehiceButtonFunc:(UIButton *) button {
    button.selected = !button.selected;
    if(button.selected == true){
        self.vehicleLable.hidden = YES;
        self.vehicleField.hidden = NO;
        [self.vehicleField becomeFirstResponder];
        if(![_vehicleLable.text isEqualToString:@"Edit"]){
            self.vehicleField.text = _vehicleLable.text;
        }else{
            self.vehicleField.text = @"";
        }
        
    }else{
        self.vehicleLable.hidden = NO;
        self.vehicleField.hidden = YES;
        [self.vehicleField resignFirstResponder];
        if(self.vehicleField.text.length > 0){
            self.vehicleLable.text = self.vehicleField.text;
            [[NSUserDefaults standardUserDefaults] setObject:self.vehicleField.text forKey:@"vehicleType"];
            [[NSUserDefaults standardUserDefaults] synchronize];
        }
    }
    
}

-(void)EcuTuningButtonFunc:(UIButton *) button {
    self->type = 1;
    self->step = 1;

    UIScrollView * scrollView = [self.tcutingingView viewWithTag:666];
    for (UIView * view  in scrollView.subviews) {
        [view removeFromSuperview];
    }
    scrollView.contentOffset = CGPointZero;
    
    for (int i = 0; i<ecuArray1.count;i++) {
        
        UIButton * button = [[UIButton alloc] initWithFrame:CGRectMake(0, i * 60, scrollView.frame.size.width, 60)];
        button.tag = 1000 + i;
        [button setBackgroundColor:[UIColor clearColor]];
        [button setTitle:ecuArray1[i] forState:UIControlStateNormal];
        [button setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [button addTarget:self action:@selector(ecuButtonTarget:) forControlEvents:UIControlEventTouchUpInside];
        [scrollView addSubview:button];
    }
    scrollView.contentSize = CGSizeMake(scrollView.frame.size.width, ecuArray1.count * 60);
    
    UILabel * titleLabel = [self.tcutingingView viewWithTag:222];
    titleLabel.text = @"ECU Tuning";

    self.bgView.frame = CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height);
    [UIView animateWithDuration:0.26 animations:^{
        self.tcutingingView.frame = CGRectMake(0, [UIScreen mainScreen].bounds.size.height - 390, [UIScreen mainScreen].bounds.size.width, 399);
    } completion:^(bool finish){
     
    }];
}

-(void)TcuTuningButtonFunc:(UIButton *) button {
    
    self->type = 2;
    self->step = 1;
    UIScrollView * scrollView = [self.tcutingingView viewWithTag:666];
    for (UIView * view  in scrollView.subviews) {
        [view removeFromSuperview];
    }
    scrollView.contentOffset = CGPointZero;
    
    for (int i = 0; i<tcuArray1.count;i++) {
        
        UIButton * button = [[UIButton alloc] initWithFrame:CGRectMake(0, i * 60, scrollView.frame.size.width, 60)];
        button.tag = 1000 + i;
        [button setBackgroundColor:[UIColor clearColor]];
        [button setTitle:tcuArray1[i] forState:UIControlStateNormal];
        [button setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [button addTarget:self action:@selector(tcuButtonTarget:) forControlEvents:UIControlEventTouchUpInside];
        [scrollView addSubview:button];
    }
    scrollView.contentSize = CGSizeMake(scrollView.frame.size.width, tcuArray1.count * 60);
    
    UILabel * titleLabel = [self.tcutingingView viewWithTag:222];
    titleLabel.text = @"TCU Tuning";
    
    self.bgView.frame = CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height);
    [UIView animateWithDuration:0.26 animations:^{
        self.tcutingingView.frame = CGRectMake(0, [UIScreen mainScreen].bounds.size.height - 390, [UIScreen mainScreen].bounds.size.width, 399);
    } completion:^(bool finish){
 
    }];
}
- (IBAction)cancelButtonMethod:(id)sender {
    [self.navigationController popViewControllerAnimated:YES];
}

- (IBAction)doneButtonMethod:(id)sender {
    
  //  NSDictionary * data = @{@"vehicle":@"",@"ecu":@"",@"tcu":@""};
    
    
    [self.navigationController popViewControllerAnimated:YES];
}
- (void)textFieldDidEndEditing:(UITextField *)textField{
    if(self.vehicleField == textField){
        if(self.vehicleField.text.length > 0){
            self.vehicleLable.text = self.vehicleField.text;
            [[NSUserDefaults standardUserDefaults] setObject:self.vehicleField.text forKey:@"vehicleType"];
            [[NSUserDefaults standardUserDefaults] synchronize];
        }
    }
    
}
- (BOOL)textFieldShouldReturn:(UITextField *)textField{
    if(self.vehicleField == textField){
        if(self.vehicleField.text.length > 0){
            self.vehicleLable.text = self.vehicleField.text;
            [[NSUserDefaults standardUserDefaults] setObject:self.vehicleField.text forKey:@"vehicleType"];
            [[NSUserDefaults standardUserDefaults] synchronize];
        }
    }
    
    
    return YES;
}

-(void)informationViewcancelButtonFunc:(UIButton *) button {
    
    self.bgView.frame = CGRectMake(0, [UIScreen mainScreen].bounds.size.height, [UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height);
    [UIView animateWithDuration:0.26 animations:^{
        self.tcutingingView.frame = CGRectMake(0, [UIScreen mainScreen].bounds.size.height, [UIScreen mainScreen].bounds.size.width, 399);
    } completion:^(bool finish){
        
        
        
    }];
}

-(void)informationViewdoneButtonFunc:(UIButton *) button {
    
    if(step == 0){
        if(type == 1){
            if(self->ecuTuningString.length <= 0){
                return;
            }
        }else if (type == 2){
            if(self->tcuTuningString.length <= 0){
                return;
            }
        }
        step = 1;
    }else if (step == 1){
        if(type == 1){
            if(self->ecuTuningString.length <= 0){
                return;
            }
        }else if (type == 2){
            if(self->tcuTuningString.length <= 0){
                return;
            }
        }
        step = 2;
    }else if (step == 2){
        step = 0;
        if(type == 1){
            [[NSUserDefaults standardUserDefaults] setObject:self->ecuTuningString forKey:@"ecutuning"];
            [[NSUserDefaults standardUserDefaults] synchronize];
        }else if (type == 2){
            [[NSUserDefaults standardUserDefaults] setObject:self->tcuTuningString forKey:@"tcutuning"];
            [[NSUserDefaults standardUserDefaults] synchronize];
        }
        if(type == 1){
            self.eduLabel.text = self->ecuTuningString;
        }else if (type == 2){
            self.tcuLabel.text = self->tcuTuningString;
        }
        self.bgView.frame = CGRectMake(0, [UIScreen mainScreen].bounds.size.height, [UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height);
        [UIView animateWithDuration:0.26 animations:^{
            self.tcutingingView.frame = CGRectMake(0, [UIScreen mainScreen].bounds.size.height, [UIScreen mainScreen].bounds.size.width, 399);
        } completion:^(BOOL finish){
            
            
        }];
        
        
        return;
    }
    UIScrollView * scrollView = [self.tcutingingView viewWithTag:666];
    for (UIView * view  in scrollView.subviews) {
        [view removeFromSuperview];
    }
    scrollView.contentOffset = CGPointZero;
    if(step == 1){
        
        if(type == 1){
            for (int i = 0; i<ecuArray1.count;i++) {
                
                UIButton * button = [[UIButton alloc] initWithFrame:CGRectMake(0, i * 60, scrollView.frame.size.width, 60)];
                button.tag = 1000 + i;
                [button setBackgroundColor:[UIColor clearColor]];
                [button setTitle:ecuArray1[i] forState:UIControlStateNormal];
                [button setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
                [button addTarget:self action:@selector(ecuButtonTarget:) forControlEvents:UIControlEventTouchUpInside];
                [scrollView addSubview:button];
            }
            scrollView.contentSize = CGSizeMake(scrollView.frame.size.width, ecuArray1.count * 60);
        }else if (type == 2){
            for (int i = 0; i<tcuArray1.count;i++) {
                
                UIButton * button = [[UIButton alloc] initWithFrame:CGRectMake(0, i * 60, scrollView.frame.size.width, 60)];
                button.tag = 1000 + i;
                [button setBackgroundColor:[UIColor clearColor]];
                [button setTitle:tcuArray1[i] forState:UIControlStateNormal];
                [button setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
                [button addTarget:self action:@selector(tcuButtonTarget:) forControlEvents:UIControlEventTouchUpInside];
                [scrollView addSubview:button];
            }
            scrollView.contentSize = CGSizeMake(scrollView.frame.size.width, tcuArray1.count * 60);
        }
        
    }else if (step == 2){
        
        if(type == 1){
            
            if([self->ecuTuningString isEqualToString:@"Original"]){
                [[NSUserDefaults standardUserDefaults] setObject:self->ecuTuningString forKey:@"ecutuning"];
                [[NSUserDefaults standardUserDefaults] synchronize];
                self.eduLabel.text = self->ecuTuningString;
    
                self.bgView.frame = CGRectMake(0, [UIScreen mainScreen].bounds.size.height, [UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height);
                [UIView animateWithDuration:0.26 animations:^{
                    self.tcutingingView.frame = CGRectMake(0, [UIScreen mainScreen].bounds.size.height, [UIScreen mainScreen].bounds.size.width, 399);
                } completion:^(BOOL finish){
                    
                    
                }];
                return;
            }

            // ecu 所有品牌只到二阶
            int endindex = 2;
            for (int i = 0; i<=endindex;i++) {
                
                UIButton * button = [[UIButton alloc] initWithFrame:CGRectMake(0, i * 60, scrollView.frame.size.width, 60)];
                button.tag = 2000 + i;
                [button setBackgroundColor:[UIColor clearColor]];
                [button setTitle:ecuArray2[i] forState:UIControlStateNormal];
                [button setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
                [button addTarget:self action:@selector(ecuButtonTarget:) forControlEvents:UIControlEventTouchUpInside];
                [scrollView addSubview:button];
            }
            scrollView.contentSize = CGSizeMake(scrollView.frame.size.width, 3 * 60);
        }else if (type == 2){
            
            if([self->tcuTuningString isEqualToString:@"Original"]){
                [[NSUserDefaults standardUserDefaults] setObject:self->tcuTuningString forKey:@"tcutuning"];
                [[NSUserDefaults standardUserDefaults] synchronize];
       
                self.tcuLabel.text = self->tcuTuningString;
          
                self.bgView.frame = CGRectMake(0, [UIScreen mainScreen].bounds.size.height, [UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height);
                [UIView animateWithDuration:0.26 animations:^{
                    self.tcutingingView.frame = CGRectMake(0, [UIScreen mainScreen].bounds.size.height, [UIScreen mainScreen].bounds.size.width, 399);
                } completion:^(BOOL finish){
                    
                    
                }];
                return;
            }
            
            int endindex = (int)tcuArray2.count-1;
            if(![self->tcuTuningString isEqualToString:@"ZD8"]){
                endindex = 3;
            }
            for (int i = 0; i<=endindex;i++) {
                
                UIButton * button = [[UIButton alloc] initWithFrame:CGRectMake(0, i * 60, scrollView.frame.size.width, 60)];
                button.tag = 2000 + i;
                [button setBackgroundColor:[UIColor clearColor]];
                [button setTitle:tcuArray2[i] forState:UIControlStateNormal];
                [button setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
                [button addTarget:self action:@selector(tcuButtonTarget:) forControlEvents:UIControlEventTouchUpInside];
                [scrollView addSubview:button];
            }
            scrollView.contentSize = CGSizeMake(scrollView.frame.size.width, (endindex + 1) * 60);
            
            
        }
        

    }
    
//    self.bgView.frame = CGRectMake(0, [UIScreen mainScreen].bounds.size.height, [UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height);
//    [UIView animateWithDuration:0.26 animations:^{
//        self.tcutingingView.frame = CGRectMake(0, [UIScreen mainScreen].bounds.size.height, [UIScreen mainScreen].bounds.size.width, 399);
//    } completion:^(bool finish){
//
//    }];
    
    
}

-(void)ecuButtonTarget:(UIButton *) button {
    int index = button.tag % 1000;
    if(step == 1){
        UIScrollView * scrollView = [self.tcutingingView viewWithTag:666];
        for (UIView * view  in scrollView.subviews) {
            [view removeFromSuperview];
        }
        scrollView.contentOffset = CGPointZero;
        self-> ecuTuningString = ecuArray1[index];
        if([self->ecuTuningString isEqualToString:@"Original"]){
            [[NSUserDefaults standardUserDefaults] setObject:self->ecuTuningString forKey:@"ecutuning"];
            [[NSUserDefaults standardUserDefaults] synchronize];
            self.eduLabel.text = self->ecuTuningString;
            UIScrollView * scrollView = [self.tcutingingView viewWithTag:666];
            for (UIView * view  in scrollView.subviews) {
                [view removeFromSuperview];
            }
            scrollView.contentOffset = CGPointZero;
            self.bgView.frame = CGRectMake(0, [UIScreen mainScreen].bounds.size.height, [UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height);
            [UIView animateWithDuration:0.26 animations:^{
                self.tcutingingView.frame = CGRectMake(0, [UIScreen mainScreen].bounds.size.height, [UIScreen mainScreen].bounds.size.width, 399);
            } completion:^(BOOL finish){
                
                
            }];
            step = 0;
            return;
        }
        int endindex = 2;
        for (int i = 0; i<=endindex;i++) {
                
            UIButton * button = [[UIButton alloc] initWithFrame:CGRectMake(0, i * 60, scrollView.frame.size.width, 60)];
            button.tag = 2000 + i;
            [button setBackgroundColor:[UIColor clearColor]];
            [button setTitle:ecuArray2[i] forState:UIControlStateNormal];
            [button setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
            [button addTarget:self action:@selector(ecuButtonTarget:) forControlEvents:UIControlEventTouchUpInside];
            [scrollView addSubview:button];
        }
        scrollView.contentSize = CGSizeMake(scrollView.frame.size.width, 3 * 60);

        step = 2;
    }else if (step == 2){
            self-> ecuTuningString = [NSString stringWithFormat:@"%@ %@",self->ecuTuningString,ecuArray2[index]];
            [[NSUserDefaults standardUserDefaults] setObject:self->ecuTuningString forKey:@"ecutuning"];
            [[NSUserDefaults standardUserDefaults] synchronize];

            self.eduLabel.text = self->ecuTuningString;
        
            UIScrollView * scrollView = [self.tcutingingView viewWithTag:666];
            for (UIView * view  in scrollView.subviews) {
                [view removeFromSuperview];
            }
            scrollView.contentOffset = CGPointZero;
            self.bgView.frame = CGRectMake(0, [UIScreen mainScreen].bounds.size.height, [UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height);
            [UIView animateWithDuration:0.26 animations:^{
                self.tcutingingView.frame = CGRectMake(0, [UIScreen mainScreen].bounds.size.height, [UIScreen mainScreen].bounds.size.width, 399);
            } completion:^(BOOL finish){
                
                
            }];
            step = 0;
    }

}
-(void)tcuButtonTarget:(UIButton *) button {
    
    int index = button.tag % 1000;
    if(step == 1){
        UIScrollView * scrollView = [self.tcutingingView viewWithTag:666];
        for (UIView * view  in scrollView.subviews) {
            [view removeFromSuperview];
        }
        scrollView.contentOffset = CGPointZero;
            self-> tcuTuningString = tcuArray1[index];
        if([self->tcuTuningString isEqualToString:@"Original"]){
            
            [[NSUserDefaults standardUserDefaults] setObject:self->tcuTuningString forKey:@"tcutuning"];
            [[NSUserDefaults standardUserDefaults] synchronize];
            self.tcuLabel.text = self->tcuTuningString;
            UIScrollView * scrollView = [self.tcutingingView viewWithTag:666];
            for (UIView * view  in scrollView.subviews) {
                [view removeFromSuperview];
            }
            self.bgView.frame = CGRectMake(0, [UIScreen mainScreen].bounds.size.height, [UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height);
            [UIView animateWithDuration:0.26 animations:^{
                self.tcutingingView.frame = CGRectMake(0, [UIScreen mainScreen].bounds.size.height, [UIScreen mainScreen].bounds.size.width, 399);
            } completion:^(BOOL finish){
                
                
            }];
            step = 0;
            return;
        }
            int endindex = (int)tcuArray2.count-1;
            if(![self->tcuTuningString isEqualToString:@"ZD8"]){
                endindex = 3;
            }
            for (int i = 0; i<=endindex;i++) {
                
                UIButton * button = [[UIButton alloc] initWithFrame:CGRectMake(0, i * 60, scrollView.frame.size.width, 60)];
                button.tag = 2000 + i;
                [button setBackgroundColor:[UIColor clearColor]];
                [button setTitle:tcuArray2[i] forState:UIControlStateNormal];
                [button setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
                [button addTarget:self action:@selector(tcuButtonTarget:) forControlEvents:UIControlEventTouchUpInside];
                [scrollView addSubview:button];
            }
            scrollView.contentSize = CGSizeMake(scrollView.frame.size.width, (endindex + 1) * 60);
        step = 2;
    }else if (step == 2){
            self-> tcuTuningString = [NSString stringWithFormat:@"%@ %@",self->tcuTuningString,tcuArray2[index]];
            [[NSUserDefaults standardUserDefaults] setObject:self->tcuTuningString forKey:@"tcutuning"];
            [[NSUserDefaults standardUserDefaults] synchronize];
            self.tcuLabel.text = self->tcuTuningString;
        UIScrollView * scrollView = [self.tcutingingView viewWithTag:666];
        for (UIView * view  in scrollView.subviews) {
            [view removeFromSuperview];
        }
        scrollView.contentOffset = CGPointZero;
        self.bgView.frame = CGRectMake(0, [UIScreen mainScreen].bounds.size.height, [UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height);
        [UIView animateWithDuration:0.26 animations:^{
            self.tcutingingView.frame = CGRectMake(0, [UIScreen mainScreen].bounds.size.height, [UIScreen mainScreen].bounds.size.width, 399);
        } completion:^(BOOL finish){
            
            
        }];
        step = 0;
    }

    
    
    
}
-(void)bgViewTarget{
    
    [UIView animateWithDuration:0.26 animations:^{
        self.tcutingingView.frame = CGRectMake(0, [UIScreen mainScreen].bounds.size.height, [UIScreen mainScreen].bounds.size.width, 399);
    } completion:^(BOOL finish){
        
        self.bgView.frame = CGRectMake(0, [UIScreen mainScreen].bounds.size.height, [UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height);
    }];
    
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
