//
//  SoftwarePackageViewController.m
//  CarLinkChannel
//
//  Created by job on 2023/3/29.
//

#import "SoftwarePackageViewController.h"
#import "informationView.h"
#import "SoftwareDownloadView.h"
#import "PackageDownloadInteractive.h"
#import "PackageDownPresenter.h"
#import "TuneContentViewController.h"
#import "NavigationView.h"

#import "NSData+Category.h"
#import "NetworkInterface.h"
#import "BINFileProcess.h"

@interface SoftwarePackageViewController()<UITableViewDelegate,UITableViewDataSource,NavigationViewDelegate>
{
    SoftwareDownloadView * softwareView;
    PackageDownPresenter * presenter;
    NSIndexPath * selectIndex;
}

@end

@implementation SoftwarePackageViewController
-(void)didTapEscButton {
    
    [self.navigationController popViewControllerAnimated:YES];
}
-(void)addNavigationView {
    
    [self.navigationController setNavigationBarHidden:YES];
    NavigationView *  naviView = (NavigationView*)[[NSBundle mainBundle] loadNibNamed:@"NavigationView" owner:self options:nil][0];
    naviView.frame = CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, 80);
    naviView.delegate = self;
    naviView.titLabel.text = @"Tuning Packages";
    
    [self.view addSubview:naviView];
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
-(void)viewDidLoad {
    NSFileManager * fm = [NSFileManager defaultManager];
    NSString * tempPath = NSTemporaryDirectory();
    NSArray * paths = [fm subpathsAtPath:tempPath];
    for (NSString * s in paths) {
        NSString * path = [tempPath stringByAppendingPathComponent:s];
        NSData * fileData = [NSData dataWithContentsOfFile:path];
        NSLog(@"path: %@  fileData.length: %ld",path,fileData.length);
    }
    
    NSLog(@"paths: %@",paths);

    informationView * inforView = [[informationView alloc] init];
    inforView = (informationView*)[[NSBundle mainBundle] loadNibNamed:@"informationView" owner:inforView options:nil][0];
    inforView.frame = CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, 105);

    UIView * v1 = [[UIView alloc] initWithFrame:CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, 120)];
    self.tableView.tableHeaderView = v1;
    [v1 addSubview:inforView];

    UILabel * vinLabel = [inforView viewWithTag:100];
    UILabel * nowLabel = [inforView viewWithTag:200];
    vinLabel.text = [NSString stringWithFormat:@"VIN:%@",self.vinString];
    
    UIView * v = [[UIView alloc] init];
    self.tableView.tableFooterView = v;
    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:@"cell"];
    presenter = [[PackageDownPresenter alloc] init];
    presenter.vinString = self.vinString;
    presenter.tableView = self.tableView;
    presenter.binaryName = self.binaryName;
    presenter.infoView = inforView;
    [presenter startFileHandler];
    
    nowLabel.text =  [self GetFileNameFormat:self.binaryName :self.vinString];
    if(self.binaryName.length <= 0){
        
        NSString * str = @"Please waiting next general release.";
        UIAlertAction * action = [UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:^(UIAlertAction * aciton){}];
        UIAlertController * controller = [UIAlertController alertControllerWithTitle:@"ECU Unsupported." message:str preferredStyle:UIAlertControllerStyleAlert];
        [controller addAction:action];
        
        [self presentViewController:controller animated:YES completion:nil];
    }
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[[UIImage imageNamed:@"escimg"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal] style:UIBarButtonItemStyleDone target:self action:@selector(didTapEscButton)];
    self.title = @"Tuning Packages";
    self.navigationController.navigationBar.tintColor = [UIColor whiteColor];
    self.navigationController.navigationBar.barTintColor = [UIColor blackColor];
    NSDictionary * titleAttribute = @{NSForegroundColorAttributeName:[UIColor darkGrayColor]};
    self.navigationController.navigationBar.titleTextAttributes = titleAttribute;
    
    [self addSwapGesture];
}

-(NSString *)GetFileNameFormat:(NSString *)fileName :(NSString *)Vin{
    NSString *filenameWithoutExtension = [fileName stringByDeletingPathExtension];
    NSString *Vinlast7Bytes = [Vin substringFromIndex:[Vin length] - 7];

    // 找到最后一个 "-" 的位置
    NSRange range = [filenameWithoutExtension rangeOfString:@"-" options:NSBackwardsSearch];
    NSString *resultString = nil;
    if (range.location != NSNotFound) {
        // 将原始字符串分为两部分
        NSString *firstPart = [filenameWithoutExtension substringToIndex:range.location];
        NSString *secondPart = [filenameWithoutExtension substringFromIndex:range.location];
        
        // 组合新的字符串
        resultString = [NSString stringWithFormat:@"%@%@-%@", firstPart, secondPart,Vinlast7Bytes];
    }

    return resultString;
}

-(void)addDisconnectNotify:(NSNotification *) notify {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.navigationController popToRootViewControllerAnimated:YES];
    });
}
-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    if(![presenter getFileExists]){
        tableView.separatorColor = [UIColor clearColor];
        return 1;
    }
    tableView.separatorColor = [UIColor whiteColor];
    return [presenter getRowCount];
}
-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 60;
}
-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    
    if(![presenter getFileExists]){
        UITableViewCell * cell = [[UITableViewCell alloc] init];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        cell.backgroundColor = [UIColor clearColor];
        cell.textLabel.textAlignment = NSTextAlignmentCenter;
        cell.textLabel.textColor = [UIColor colorWithRed:52/255.0 green:97/255.0 blue:139/255.0 alpha:1.0];
        cell.textLabel.text = @"NO map available,please download!";
        return cell;
    }
    
    UITableViewCell * cell = [tableView dequeueReusableCellWithIdentifier:@"cell" forIndexPath:indexPath];
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    cell.backgroundColor = [UIColor clearColor];
    UIImageView * iv = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 11, 14)];
    iv.image = [UIImage imageNamed:@"rightallow"];
    cell.accessoryView = iv;
    
    NSString * indextext = [presenter getRowString:indexPath];
    if([indextext isEqualToString:@"OBD Unlock - STEP 1"]){
        cell.textLabel.font = [UIFont boldSystemFontOfSize:17];
    }else{
        cell.textLabel.font = [UIFont systemFontOfSize:17];
    }
    cell.textLabel.text = indextext;
    cell.textLabel.textColor = [UIColor whiteColor];
    
    if([indextext isEqual:@"xHP Tuning style Stage 1"] ||[indextext isEqual:@"xHP Tuning style Stage 2"]||[indextext isEqual:@"xHP Tuning style Stage 3"])
    {
        cell.textLabel.textColor = [UIColor lightGrayColor];
    }
    return cell;
}
-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    if([presenter getFileExists]){
        selectIndex = indexPath;
        UIStoryboard * sb = [UIStoryboard storyboardWithName:@"Main" bundle:[NSBundle mainBundle]];
        TuneContentViewController * tuneController =   [sb instantiateViewControllerWithIdentifier:@"TuneContentViewController"];
        tuneController.binFilePath = [presenter getTunePath:indexPath];
        [self.navigationController pushViewController:tuneController animated:YES];
    }
}

- (IBAction)download:(id)sender {
    
    if(self.binaryName.length <= 0){
        NSString * str = @"Please waiting next general release.";
        UIAlertAction * action = [UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:^(UIAlertAction * aciton){}];
        UIAlertController * controller = [UIAlertController alertControllerWithTitle:@"ECU Unsupported." message:str preferredStyle:UIAlertControllerStyleAlert];
        [controller addAction:action];
        
        [self presentViewController:controller animated:YES completion:nil];
        return;
    }
    
    NetworkInterface * interface = [NetworkInterface getInterface];
    [interface getUpdateBinFile:self.vinString requestBlock:^(NSString *result) {
        UploadManager *uploadManager = [UploadManager sharedInstance];
        if(![result isEqual:@""])
        {
            [uploadManager SetBinStateAndFileName:@"1" :result];
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                [uploadManager uploadMidFile];
            });
            self->_binaryName = result;
        }
        else
        {
            MidSetBin *SetState = [uploadManager CheckWhetherSetBIN];
            if(SetState.status == ResponseXmlMidNeedSetFile)
            {
                self->_binaryName = SetState.BINName;
            }
            else
            {
                BINFileProcess *BinFileHandle = [[BINFileProcess alloc] init];
                [BinFileHandle loadBinaryFile:self.vinString :self.VehicleSvt :^(NSString * binaryFileName){
                    NSLog(@"binFile name :%@",binaryFileName);
                    self->_binaryName = binaryFileName;
                    [interface RegisterFileNameFormVin:self.vinString DownloadFileName:self->_binaryName];
                }withErrorBlock:^(NSError * error){
                }];
            }
        }
        
    }
    withError:^(NSError *error) {
    }];
    
    
    self->softwareView = (SoftwareDownloadView *)[[NSBundle mainBundle] loadNibNamed:@"SoftwareDownloadView" owner:self options:nil][0];
    self->softwareView.frame = CGRectMake(0, [UIScreen mainScreen].bounds.size.height, [UIScreen mainScreen].bounds.size.width, 230);
    [self.view addSubview:self->softwareView];
    [self->softwareView initView];
    self->softwareView.BinName = self->_binaryName;
    [UIView animateWithDuration:0.25 delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        self->softwareView.frame = CGRectMake(0, [UIScreen mainScreen].bounds.size.height - 230, [UIScreen mainScreen].bounds.size.width, 230);
    } completion:^(bool finish){
        self->presenter.downloadView = self->softwareView;
    }];
}

@end
