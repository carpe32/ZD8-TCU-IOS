//
//  TuneContentViewController.m
//  CarLinkChannel
//
//  Created by job on 2023/3/31.
//

#import "TuneContentViewController.h"
#import "NavigationView.h"

@interface TuneContentViewController()<NavigationViewDelegate>
@property(nonatomic,strong) UIView * bgView;
@property(nonatomic,strong) UIView * popView;
@end

@implementation TuneContentViewController
-(void)didTapEscButton {
    
    [self.navigationController popViewControllerAnimated:YES];
}
-(void)addSwapGesture {
    UISwipeGestureRecognizer * leftSwipteGesture = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(leftSwipteGesture)];
    leftSwipteGesture.direction = UISwipeGestureRecognizerDirectionLeft;
    [self.view addGestureRecognizer:leftSwipteGesture];
    
    UISwipeGestureRecognizer * rightSwitpeGesture = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(rightSwipteGesture)];
    rightSwitpeGesture.direction = UISwipeGestureRecognizerDirectionRight;
    [self.view addGestureRecognizer:rightSwitpeGesture];
}
-(void)leftSwipteGesture {
}
-(void)rightSwipteGesture {
    [self.navigationController popViewControllerAnimated:YES];
}
-(void)addNavigationView {
    
    [self.navigationController setNavigationBarHidden:YES];
    NavigationView *  naviView = (NavigationView*)[[NSBundle mainBundle] loadNibNamed:@"NavigationView" owner:self options:nil][0];
    naviView.frame = CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, 80);
    naviView.delegate = self;
    naviView.titLabel.text = @"Tuning Notes";
    
    [self.view addSubview:naviView];
}
-(void)viewDidLoad{

    self.titleLabel.text = [[self.binFilePath componentsSeparatedByString:@"/"] lastObject];
    self.contentTextView.text = [NSString stringWithContentsOfFile:[self.binFilePath stringByAppendingFormat:@"/%@",SHOW_TXT] encoding:NSUTF8StringEncoding error:nil];
//    [self addNavigationView];
    
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[[UIImage imageNamed:@"escimg"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal] style:UIBarButtonItemStyleDone target:self action:@selector(didTapEscButton)];
    self.title = @"Tuning Notes";
    self.navigationController.navigationBar.tintColor = [UIColor whiteColor];
    self.navigationController.navigationBar.barTintColor = [UIColor blackColor];
//    self.navigationController.navigationBar.titleTextAttributes = @{NSForegroundColorAttributeName:[UIColor whiteColor]};
//    UINavigationBarAppearance * navibarAppearance = [[UINavigationBarAppearance alloc] init];
    NSDictionary * titleAttribute = @{NSForegroundColorAttributeName:[UIColor darkGrayColor]};
    self.navigationController.navigationBar.titleTextAttributes = titleAttribute;
    
    [self addSwapGesture];
}

- (IBAction)programming:(id)sender {
    
    if(self.bgView){
        [self.bgView removeFromSuperview];
    }
    
    self.bgView = [[UIView alloc] initWithFrame:[UIScreen mainScreen].bounds];
    self.bgView.backgroundColor = [UIColor blackColor];
    self.bgView.alpha = 0.6;

    [self.view addSubview:self.bgView];
    
    UITapGestureRecognizer *  tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(dismissPopView)];
    [self.bgView addGestureRecognizer:tap];
    
    if(self.popView){
        [self.popView removeFromSuperview];
    }
    
    self.popView = [[NSBundle mainBundle] loadNibNamed:@"WarnPopView" owner:nil options:nil][0];
    self.popView.frame = CGRectMake(0, [UIScreen mainScreen].bounds.size.height - 510, [UIScreen mainScreen].bounds.size.width, 520);
    
    UIButton * okButton = [self.popView viewWithTag:100];
    [okButton addTarget:self action:@selector(okButtonMethod) forControlEvents:UIControlEventTouchUpInside];
    
    [self.view addSubview:self.popView];
}

-(void)dismissPopView {
    
    [self.bgView removeFromSuperview];
    [self.popView removeFromSuperview];
    
}
-(void)okButtonMethod {
    NSString *fileName = [self.binFilePath lastPathComponent];
    //synchronous data
//    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{
        UploadManager *uploadManager = [UploadManager sharedInstance];
        [uploadManager uploadFlashCellName:fileName :NO];
//    });
    NSArray<UIViewController *> * controllers = self.navigationController.viewControllers;
    UIViewController * subViewController = [controllers objectAtIndex:1];
    [self.navigationController popToViewController:subViewController animated:YES];
    
    NSDictionary * dataDict = @{@"path":self.binFilePath};
    [[NSNotificationCenter defaultCenter] postNotificationName:begin_start_install_notify_name object:nil userInfo:dataDict];
}

@end
