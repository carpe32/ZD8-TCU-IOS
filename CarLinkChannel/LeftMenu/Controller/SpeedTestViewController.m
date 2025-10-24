//
//  SpeedTestViewController.m
//  CarLinkChannel
//
//  Created by job on 2023/4/24.
//

#import "SpeedTestViewController.h"
#import "NavigationView.h"
#import <AVFoundation/AVFoundation.h>
#import "SpeedView.h"
#import "SpeedTestInfoViewController.h"
#import "XTDebugControl.h"

@interface SpeedTestViewController ()<UITableViewDelegate,UITableViewDataSource,NavigationViewDelegate>
{
    UILabel * vehicleLabel;
    UILabel * ecuLabel;
    SpeedView * speedView;
    NSURL * outputUrl;
    NSString * smallString;
}
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (nonatomic,strong) UIView * bgView;
@property (nonatomic,strong) UIView * dialogView;
@property (nonatomic,strong) NSMutableArray * movies;
@property (nonatomic,strong) UIProgressView * progressView;
@property (nonatomic,strong) UILabel * waitLabel;
@property (weak, nonatomic) IBOutlet UIButton *testButton;
@property (nonatomic,strong) UIView * exportbgView;
@end

@implementation SpeedTestViewController

-(void)addNavigationView {
    
    [self.navigationController setNavigationBarHidden:YES];
    NavigationView *  naviView = (NavigationView*)[[NSBundle mainBundle] loadNibNamed:@"NavigationView" owner:self options:nil][0];
    naviView.frame = CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, 80);
    naviView.titLabel.text = @"0-100Km/h test";
    
    naviView.delegate = self;
    [self.view addSubview:naviView];

}
-(void)didTapEscButton {
    
    [self.navigationController popViewControllerAnimated:YES];
}
-(CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section{
    BOOL hidden = [[NSUserDefaults standardUserDefaults] boolForKey:@"videoexport"];
    if(hidden){
        return 70;
    }
    return 40;
}
-(UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section{
    
    UIView * sectionView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, 70)];
    
    BOOL hidden = [[NSUserDefaults standardUserDefaults] boolForKey:@"videoexport"];
    if(hidden){
         
        UILabel * videolabel30s = [[UILabel alloc] initWithFrame:CGRectMake(20, 0, 160, 30)];
        videolabel30s.font = [UIFont boldSystemFontOfSize:20];
        videolabel30s.textColor = [UIColor whiteColor];
        videolabel30s.text = @"30s Videos";
        
        [sectionView addSubview:videolabel30s];
        UILabel * historyLabel = [[UILabel alloc] initWithFrame:CGRectMake(20, 30, 60, 40)];
        historyLabel.text = @"History";
        historyLabel.textColor = [UIColor darkGrayColor];
        
        UIButton * emptyButton = [[UIButton alloc] initWithFrame:CGRectMake([UIScreen mainScreen].bounds.size.width - 200, 30, 160, 40)];
        [emptyButton setTitle:@"Delete History>" forState:UIControlStateNormal];
        emptyButton.titleLabel.textAlignment = NSTextAlignmentRight;
        [emptyButton setTitleColor:[UIColor darkGrayColor] forState:UIControlStateNormal];
        
        [emptyButton addTarget:self action:@selector(emptyButtonFunc:) forControlEvents:UIControlEventTouchUpInside];
        [sectionView addSubview:historyLabel];
        [sectionView addSubview:emptyButton];
    }else{
        sectionView.frame = CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, 40);
        
        UILabel * historyLabel = [[UILabel alloc] initWithFrame:CGRectMake(20, 0, 60, 40)];
        historyLabel.text = @"History";
        historyLabel.textColor = [UIColor darkGrayColor];
        
        UIButton * emptyButton = [[UIButton alloc] initWithFrame:CGRectMake([UIScreen mainScreen].bounds.size.width - 200, 0, 160, 40)];
        [emptyButton setTitle:@"Delet History>" forState:UIControlStateNormal];
        emptyButton.titleLabel.textAlignment = NSTextAlignmentRight;
        [emptyButton setTitleColor:[UIColor darkGrayColor] forState:UIControlStateNormal];
        
        [emptyButton addTarget:self action:@selector(emptyButtonFunc:) forControlEvents:UIControlEventTouchUpInside];
        [sectionView addSubview:historyLabel];
        [sectionView addSubview:emptyButton];
        
    }
    

    return sectionView;
}
-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    
    return self.movies.count;
}
-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    UITableViewCell * cell = [tableView dequeueReusableCellWithIdentifier:SPEED_TEST_CELL];
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    
    if(indexPath.row % 2 == 0){
        cell.backgroundColor = [UIColor blackColor];
    }else{
        cell.backgroundColor = [UIColor colorWithRed:56/255.0 green:56/255.0 blue:56/255.0 alpha:1.0];
    }
    NSDictionary * file = self.movies[indexPath.row];
    
    UILabel * FileNameLabel = [cell viewWithTag:100];
    FileNameLabel.text = [NSString stringWithFormat:@"%@",[file[@"fileName"] stringByReplacingOccurrencesOfString:@"_origin.mp4" withString:@""]];

    UILabel * durationLabel = [cell viewWithTag:200];

    NSString * durationStr = [NSString stringWithFormat:@"%@",file[@"duration"]];
    if([durationStr isEqualToString:smallString]){
        durationLabel.font = [UIFont boldSystemFontOfSize:17.0];
    }else{
        durationLabel.font = [UIFont systemFontOfSize:14.0];
    }
    durationLabel.text = durationStr;
    
    UIButton * exportButton = [cell viewWithTag:300];

    [exportButton addTarget:self action:@selector(exportButtonMethod:) forControlEvents:UIControlEventTouchUpInside];
    
    return cell;
}


- (void)viewDidLoad {
    [super viewDidLoad];
    [self SetSpeedMsgView];
    
    BOOL hidden = [[NSUserDefaults standardUserDefaults] boolForKey:@"videoexport"];
    
    BOOL fromHome = [[NSUserDefaults standardUserDefaults] boolForKey:@"fromHome"];
    
    if(fromHome){
        if(hidden == YES){
            self.navigationController.title = @"Racing video record";
        }else{
            self.navigationController.title = @"0-100Km/h test";
        }
        self.testButton.enabled = NO;
    }else{
        if(hidden == YES){
            self.title = @"Racing video record";
            [self.testButton setTitle:@"Record" forState:UIControlStateNormal];
        }else{
            self.title = @"0-100Km/h test";
        }
    }
    
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(recvVideoCompositionProgressNotify:) name:recv_video_progress_notify_name object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(recvVideoCompositionDoneNotify:) name:recv_video_progress_done_notify_name object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(orientationDidChange) name:UIApplicationDidChangeStatusBarOrientationNotification object:nil];

    
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[[UIImage imageNamed:@"escimg"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal] style:UIBarButtonItemStyleDone target:self action:@selector(didTapEscButton)];

    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentDirectory = paths.firstObject;
    NSString * moviepath = [documentDirectory stringByAppendingPathComponent:@"Movie"];
    if(hidden){
        moviepath = [documentDirectory stringByAppendingPathComponent:@"Racing"];
    }
    
    
    NSFileManager * fm = [NSFileManager defaultManager];
    NSArray<NSString *> * files = [fm contentsOfDirectoryAtPath:moviepath error:nil];
    //处理部分不知名原因导致的文件名缺少秒数
    NSDateFormatter *formatterWithSeconds = [[NSDateFormatter alloc] init];
    formatterWithSeconds.dateFormat = @"dd-MM-yyyy HH:mm:ss";

    NSDateFormatter *formatterWithoutSeconds = [[NSDateFormatter alloc] init];
    formatterWithoutSeconds.dateFormat = @"dd-MM-yyyy HH:mm";
    NSError *error = nil;
    for (NSString *fileName in files) {
        if (![fileName hasSuffix:@"_origin.mp4"] && ![fileName hasSuffix:@".txt"]) {
            continue; // 跳过不符合后缀的文件
        }

        NSString *baseFileName;
        if([fileName hasSuffix:@"_origin.mp4"])
        {
            baseFileName = [fileName stringByReplacingOccurrencesOfString:@"_origin.mp4" withString:@""];
        }
        else if([fileName hasSuffix:@".txt"])
        {
            baseFileName = [fileName stringByDeletingPathExtension];
        }

        NSDate *date = [formatterWithSeconds dateFromString:baseFileName];
        if (!date) {
            date = [formatterWithoutSeconds dateFromString:baseFileName];
            if (date) {
                NSString *newFileName = [formatterWithSeconds stringFromDate:date];
                newFileName = [newFileName stringByAppendingPathExtension:[fileName pathExtension]];
                
                NSString *oldFilePath = [moviepath stringByAppendingPathComponent:fileName];
                NSString *newFilePath = [moviepath stringByAppendingPathComponent:newFileName];

                if (![fm moveItemAtPath:oldFilePath toPath:newFilePath error:&error]) {
                    NSLog(@"Could not rename file %@ to %@: %@", oldFilePath, newFilePath, error);
                }
            }
        }
    }
    
    //排序
    NSLog(@"排序前 files : %@",files);
    files = [files sortedArrayUsingComparator:^(id obj1,id obj2){
        NSString * str1 = (NSString *)obj1;
        NSString * str2 = (NSString *)obj2;
        return [str1 compare:str2];
    }];
    
    NSLog(@"排序后 files: %@",files);
    
    
    for (NSString * file in files) {// && [file hasSuffix:@"_completed.mp4"]
        if(![file hasSuffix:@"_origin.mp4"] && ![file hasSuffix:@".txt"]){
//        if([file hasSuffix:@"_completed.mp4"]){
            [fm removeItemAtPath:[moviepath stringByAppendingPathComponent:file] error:nil];
        }
    }
    
    self.bgView = [[UIView alloc] initWithFrame:CGRectMake(0, [UIScreen mainScreen].bounds.size.height, [UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height)];
    self.bgView.backgroundColor = [UIColor blackColor];
    self.bgView.alpha = 0.4;
    [self.view addSubview:self.bgView];
    
    UITapGestureRecognizer * tap  = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(bgViewTaped)];
    [self.bgView addGestureRecognizer:tap];
    
    self.dialogView = [[NSBundle mainBundle] loadNibNamed:@"EmptyHistoryView" owner:nil options:nil][0];
    self.dialogView.frame = CGRectMake(0, [UIScreen mainScreen].bounds.size.height, [UIScreen mainScreen].bounds.size.width, 260);
    [self.view addSubview:self.dialogView];
    
    UIButton * emptyDoneButton = [self.dialogView viewWithTag:10];
    [emptyDoneButton addTarget:self action:@selector(emptyDoneButtonFunc:) forControlEvents:UIControlEventTouchUpInside];
    UIButton * emptyCancelButton = [self.dialogView viewWithTag:20];
    [emptyCancelButton addTarget:self action:@selector(emptyCancelButtonFunc:) forControlEvents:UIControlEventTouchUpInside];
    
}

-(void)SetSpeedMsgView{
    UIView * headerView = [[NSBundle mainBundle] loadNibNamed:@"SpeedTestHeaderView" owner:nil options:nil][0];
    headerView.frame = CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, 140);
    
    UITapGestureRecognizer * tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(goToSetttingInfo)];
    [headerView addGestureRecognizer:tapGesture];
    
    UIView * subView = [headerView viewWithTag:100];
    subView.layer.cornerRadius = 14;
    subView.layer.masksToBounds = true;
    
    self->vehicleLabel = [subView viewWithTag:102];
    self->ecuLabel = [subView viewWithTag:104];
    
    UIView * bgView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, 140)];
    [bgView addSubview:headerView];
    
    self.tableView.tableHeaderView = bgView;

    self.tableView.tableFooterView = [[UIView alloc] init];
}

-(void)goToSetttingInfo {
    UIStoryboard * storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    SpeedTestInfoViewController * testInfoViewController = [storyboard instantiateViewControllerWithIdentifier:@"SpeedTestInfoViewController"];
    [self.navigationController pushViewController:testInfoViewController animated:YES];
}
-(void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    NSString * vechicletype = [[NSUserDefaults standardUserDefaults] objectForKey:@"vehicleType"];
    NSString * ecutuning = [[NSUserDefaults standardUserDefaults] objectForKey:@"ecutuning"];
    NSString * tcutuning = [[NSUserDefaults standardUserDefaults] objectForKey:@"tcutuning"];
    
    if(vechicletype == nil){
        self->vehicleLabel.text = [NSString stringWithFormat:@"BMW 320i"];
    }else{
        self->vehicleLabel.text = [NSString stringWithFormat:@"BMW %@",vechicletype];
    }
    
    if(ecutuning == nil || [ecutuning containsString:@"Unknown"]){
        self->ecuLabel.text = [NSString stringWithFormat:@"ECU:ZD8"];
    }else{
        self->ecuLabel.text = [NSString stringWithFormat:@"ECU:%@",ecutuning];
    }
    
    if(tcutuning == nil || [tcutuning containsString:@"Unknown"]){
        self->ecuLabel.text = [NSString stringWithFormat:@"%@ TCU:Stock",self->ecuLabel.text];
    }else{
        self->ecuLabel.text = [NSString stringWithFormat:@"%@ TCU:%@",self->ecuLabel.text,tcutuning];
    }
    
    NSFileManager * fm = [NSFileManager defaultManager];
    NSString * documentPath = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)[0];
    NSString * moviePath = [documentPath stringByAppendingPathComponent:@"Movie"];
    
    BOOL hidden = [[NSUserDefaults standardUserDefaults] boolForKey:@"videoexport"];
    
    if(hidden){
        moviePath = [documentPath stringByAppendingPathComponent:@"Racing"];
    }
    
    
    if(![fm fileExistsAtPath:moviePath]){
        [fm createDirectoryAtPath:moviePath withIntermediateDirectories:YES attributes:nil error:nil];
    }
    
    NSArray<NSString *> * files = [fm contentsOfDirectoryAtPath:moviePath error:nil];
    NSMutableArray * mutableArray = [NSMutableArray array];
    for (NSString * fileName in files) {
        if([fileName hasSuffix:@"_origin.mp4"]){
            [mutableArray addObject:fileName];
        }
    }
    NSLog(@"筛选后mp4 files: %@",mutableArray);
    files = [mutableArray sortedArrayUsingComparator:^(id obj1,id obj2){
        NSString * str1 = (NSString *)obj1;
        NSString * str2 = (NSString *)obj2;
        str1 = [str1 stringByReplacingOccurrencesOfString:@"_origin.mp4" withString:@""];
        str2 = [str2 stringByReplacingOccurrencesOfString:@"_origin.mp4" withString:@""];
        
        NSDateFormatter * formatter = [[NSDateFormatter alloc] init];
//        formatter.dateFormat = @"dd-MM-yyyy HH:mm";
//        if(hidden){
            formatter.dateFormat = @"dd-MM-yyyy HH:mm:ss";
//        }
        NSDate * date1 = [formatter dateFromString:str1];
        NSDate * date2 = [formatter dateFromString:str2];
        
        NSComparisonResult result = [date1 compare:date2];
        if(result == NSOrderedAscending){
            return NSOrderedDescending;
        }else{
            return NSOrderedAscending;
        }
    }];
    NSLog(@"筛选后mp4 2 files: %@",files);

    CGFloat duration = 0;
    self.movies = [NSMutableArray array];
    for (NSString * file in files) {
            NSString * txtPath = [file stringByReplacingOccurrencesOfString:@"_origin.mp4" withString:@".txt"];
            NSString * documentPath = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)[0];
            NSString * moviePath = [documentPath stringByAppendingPathComponent:@"Movie"];
            if(hidden){
                moviePath = [documentPath stringByAppendingPathComponent:@"Racing"];
            }
            NSString * recoredFilePath = [moviePath stringByAppendingPathComponent:txtPath];
            if(![fm fileExistsAtPath:recoredFilePath]){
                continue;
            }
            NSFileHandle * fileHandler = [NSFileHandle fileHandleForReadingAtPath:recoredFilePath];
        NSData * tempData = fileHandler.availableData;

        NSString * tempstring = [[NSString alloc] initWithData:tempData encoding:NSUTF8StringEncoding];
//
        
            [fileHandler seekToEndOfFile];
        
            // 这里要判断是否记录完成，是否记录了一定的数据值，有可能要录制过程中用户退出了，导致录制暂停，如果文件没有正常录制，那么这个文件是需要被删除
            if(fileHandler.offsetInFile<24){
                // 先删除纪录的txt文件
                [fm removeItemAtPath:txtPath error:nil];
                // 再删除纪录的mp4文件
                [fm removeItemAtPath:[moviePath stringByAppendingPathComponent:file] error:nil];
                [fileHandler closeFile];
                continue;
            }
        
        
            [fileHandler seekToFileOffset:fileHandler.offsetInFile-24];
            // 前三个字符存储的是分支 [1]  总共三人字符
            NSData * prefixData = [fileHandler readDataOfLength:24];
            NSString * prefixSero = [[NSString alloc] initWithData:prefixData encoding:NSUTF8StringEncoding];
            prefixSero = [prefixSero stringByReplacingOccurrencesOfString:@"[" withString:@""];
            prefixSero = [prefixSero stringByReplacingOccurrencesOfString:@"]" withString:@""];
            NSArray<NSString*> * stringSero = [prefixSero componentsSeparatedByString:@","];
           //   如果最末尾不是一个4个成员的数组，说明这段纪录是没有纪录完成就退出了，这种文件需要删除,否则会导致闪退
            if(stringSero.count < 4){
                // 先删除纪录的txt文件
                [fm removeItemAtPath:txtPath error:nil];
                // 再删除纪录的mp4文件
                [fm removeItemAtPath:[moviePath stringByAppendingPathComponent:file] error:nil];
                [fileHandler closeFile];
                continue;
            }
            CGFloat durationvalue = [stringSero[3] floatValue];
            if(duration == 0){
                duration = durationvalue;
            }else{
                if(duration > durationvalue){
                    duration = durationvalue;
                }
            }
            [fileHandler closeFile];
//          AVAsset * asset = [AVAsset assetWithURL:[NSURL fileURLWithPath:[moviePath stringByAppendingPathComponent:file]]];
////                   NSString * duration = [NSString stringWithFormat:@"%.3lfs",(double)asset.duration.value/(double)asset.duration.timescale];
////                   NSLog(@"timescale: %d",asset.duration.timescale);
//          NSLog(@"asset.duration.timescale: %d, timeduration: %lld",asset.duration.timescale,asset.duration.value);
            if(hidden){
//                NSString * durationStr = [NSString stringWithFormat:@"%.3fs",durationvalue];
//              //   因为Racing 模式带有秒数，所以需要去掉秒数
//                NSArray<NSString *> * filecomponents = [file componentsSeparatedByString:@"_"];
//
//                NSString *  file_name = [NSString stringWithFormat:@"%@_%@",[filecomponents[0] substringToIndex:filecomponents[0].length-3],filecomponents[1]];
                NSDictionary * movie = @{@"fileName":file,@"duration":@"30s"};
                [self.movies addObject:movie];
            }else{
                NSString * durationStr = [NSString stringWithFormat:@"%.3fs",durationvalue];
                NSDictionary * movie = @{@"fileName":file,@"duration":durationStr};
                [self.movies addObject:movie];
            }
 
//        }
    }
    smallString = [NSString stringWithFormat:@"%.3fs",duration];
    // 这里判断是否是0-100km/h 测试模式，如果是就加上最好的结果值
    if(hidden == false){
        self->vehicleLabel.text = [NSString stringWithFormat:@"%@  Best Results: %@",self->vehicleLabel.text,smallString];
    }
    [self.tableView reloadData];
}
-(void)emptyButtonFunc:(UIButton *) button {
    
    self.bgView.frame = CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height);
    [UIView animateWithDuration:0.26 animations:^{
        self.dialogView.frame = CGRectMake(0, [UIScreen mainScreen].bounds.size.height - 260, [UIScreen mainScreen].bounds.size.width, 260);
        } completion:^(BOOL finish){
            
    }];
    
}
-(void)bgViewTaped {
    self.bgView.frame = CGRectMake(0, [UIScreen mainScreen].bounds.size.height, [UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height);
    [UIView animateWithDuration:0.26 animations:^{
        self.dialogView.frame = CGRectMake(0, [UIScreen mainScreen].bounds.size.height, [UIScreen mainScreen].bounds.size.width, 260);
    } completion:^(BOOL finish){
        
    }];
}

-(void)emptyDoneButtonFunc:(UIButton *) button {
    
    
    NSFileManager * fm = [NSFileManager defaultManager];
    NSString * documentPath = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)[0];
    NSString * moviePath = [documentPath stringByAppendingPathComponent:@"Movie"];
    
    BOOL hidden = [[NSUserDefaults standardUserDefaults] boolForKey:@"videoexport"];
    if(hidden){
        moviePath = [documentPath stringByAppendingPathComponent:@"Racing"];
    }
    
    NSArray<NSString *> * files = [fm contentsOfDirectoryAtPath:moviePath error:nil];
    for (NSString * file in files) {
        NSString * filePath = [moviePath stringByAppendingPathComponent:file];
        [fm removeItemAtPath:filePath error:nil];
    }
    
    self.movies = @[].mutableCopy;
    [self.tableView reloadData];
    
    self.bgView.frame = CGRectMake(0, [UIScreen mainScreen].bounds.size.height, [UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height);
    [UIView animateWithDuration:0.26 animations:^{
        self.dialogView.frame = CGRectMake(0, [UIScreen mainScreen].bounds.size.height, [UIScreen mainScreen].bounds.size.width, 260);
    } completion:^(BOOL finish){
        
    }];
}
-(void)emptyCancelButtonFunc:(UIButton *) button {
    
    self.bgView.frame = CGRectMake(0, [UIScreen mainScreen].bounds.size.height, [UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height);
    [UIView animateWithDuration:0.26 animations:^{
        self.dialogView.frame = CGRectMake(0, [UIScreen mainScreen].bounds.size.height, [UIScreen mainScreen].bounds.size.width, 260);
    } completion:^(BOOL finish){
        
    }];
}
-(void)exportButtonMethod:(UIButton *) button {

    
    UITableViewCell * cell = (UITableViewCell *)button.superview.superview;
    NSIndexPath * indexPath = [self.tableView indexPathForCell:cell];
    NSDictionary * file = self.movies[indexPath.row];
    NSString * fileName = file[@"fileName"];
    
    NSString * completedFile = [fileName stringByReplacingOccurrencesOfString:@"_origin" withString:@"_completed"];
    NSString * documentPath = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)[0];
    NSString * moviePath = [documentPath stringByAppendingPathComponent:@"Movie"];
    BOOL hidden = [[NSUserDefaults standardUserDefaults] boolForKey:@"videoexport"];
    if(hidden){
        moviePath = [documentPath stringByAppendingPathComponent:@"Racing"];
    }
    NSString * filePath = [moviePath stringByAppendingPathComponent:completedFile];
    
    NSFileManager * fm = [NSFileManager defaultManager];
    if([fm fileExistsAtPath:filePath]){

        NSArray *urls = @[[NSURL fileURLWithPath:filePath]];
        UIActivityViewController *activityVC = [[UIActivityViewController alloc] initWithActivityItems:urls applicationActivities:nil];
        NSArray *cludeActivitys = @[UIActivityTypeMail];
        activityVC.excludedActivityTypes = cludeActivitys;
        if ([activityVC respondsToSelector:@selector(popoverPresentationController)]) {        activityVC.popoverPresentationController.sourceView = [UIApplication sharedApplication].keyWindow;
            activityVC.popoverPresentationController.sourceRect = CGRectMake(0, [UIScreen mainScreen].bounds.size.height, [UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height);
        }
        [self presentViewController:activityVC animated:YES completion:nil];
    }else{
        
        self.exportbgView = [[UIView alloc] initWithFrame:[UIScreen mainScreen].bounds];
        self.exportbgView.backgroundColor = [UIColor blackColor];
        self.exportbgView.alpha = 0.6;
        [self.view addSubview:self.exportbgView];
      
        self.waitLabel =[[UILabel alloc] initWithFrame:CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, 60)];
        self.waitLabel.font = [UIFont systemFontOfSize:16];
        self.waitLabel.textColor = [UIColor whiteColor];
        self.waitLabel.textAlignment = NSTextAlignmentCenter;
        
        if(hidden){
            self.waitLabel.text = @"Video Exporting... Please waiting 30s";
        }else{
            self.waitLabel.text = @"Video Exporting... Please waiting 40s";
        }
        self.waitLabel.center = CGPointMake([UIScreen mainScreen].bounds.size.width / 2, [UIScreen mainScreen].bounds.size.height / 2);
    //        [self.view addSubview:bgView];
        [self.view addSubview:self.waitLabel];
        
        self.progressView = [[UIProgressView alloc] initWithFrame:CGRectMake(100, 100, [UIScreen mainScreen].bounds.size.width - 200, 20)];
        self.progressView.center = CGPointMake([UIScreen mainScreen].bounds.size.width / 2, [UIScreen mainScreen].bounds.size.height / 2 + 50);
        self.progressView.progress = 0.2;
        [self.view addSubview:self.progressView];
        
        NSString *path = [filePath stringByReplacingOccurrencesOfString:@"_completed" withString:@"_origin"];
        if(speedView){
            [speedView removesignal];
            speedView = nil;
        }
        speedView = [[SpeedView alloc] init];
        [speedView addVideoMarkVideoPath:path WithCompletionHandler:^(NSURL * url,int code){
            self->outputUrl = url;
        }];
        
       [speedView addAllVideoSegmentsWithOriginVideoName:path.lastPathComponent];
    }

    
}
-(void)orientationDidChange{
    
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id <UIViewControllerTransitionCoordinator>)coordinator{
    
  //  NSLog(@"size.width: %f,size.height: %f,coordinator: %p",size.width,size.height,coordinator);
    [self.tableView reloadData];
}
-(void)addTimeLabelNotify:(NSNotification *) notify {
  //  NSURL * assetUrl = notify.userInfo[@"url"];
    
   // [self performSelector:@selector(addTimelabel:) withObject:assetUrl afterDelay:5];
}
-(void)addTimelabel:(NSURL *)fileUrl {
    
    if(speedView){
        [speedView removesignal];
        speedView = nil;
    }
    speedView = [[SpeedView alloc] init];
    
    [speedView addTimerLabelWithCompleteAssetUrl:fileUrl];
}
// 收到视频合成进度通知
-(void)recvVideoCompositionProgressNotify:(NSNotification *) notify {
    NSDictionary * data = notify.userInfo;
//    double progress_ct = [data[progress_count] doubleValue];
    float progress_video = [data[prgress_video] floatValue];
    
    float progress = progress_video;
    dispatch_async(dispatch_get_main_queue(), ^{
//        self.progressView.progress = progress;
        [self.progressView setProgress:progress animated:YES];
    });
    
}
- (void)video:(NSString *)videoPath didFinishSavingWithError:(NSError *)error contextInfo:(void *)contextInfo{
    
    NSFileManager * fm = [NSFileManager defaultManager];
    if([fm fileExistsAtPath:videoPath]){
        [fm removeItemAtPath:videoPath error:nil];
    }
    NSLog(@"视频保存到相册: %@ ",error);
}
// 收到视频合成完毕通知
-(void)recvVideoCompositionDoneNotify:(NSNotification *) notify {
    
    NSDictionary * data = notify.userInfo;
//    double progress_ct = [data[progress_count] doubleValue];
    float progress_video = [data[prgress_video] floatValue];
    
    float progress = progress_video;
    dispatch_async(dispatch_get_main_queue(), ^{
        
        NSString * videoPath = [self->outputUrl.absoluteString stringByReplacingOccurrencesOfString:@"file://" withString:@""];
        videoPath = [videoPath stringByReplacingOccurrencesOfString:@"%20" withString:@" "];
        
        NSString * documentPath = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)[0];
        NSString * moviePath = [documentPath stringByAppendingPathComponent:@"Movie"];
        BOOL hidden = [[NSUserDefaults standardUserDefaults] boolForKey:@"videoexport"];
        if(hidden){
            moviePath = [documentPath stringByAppendingPathComponent:@"Racing"];
        }
        
        int fileName = (int)random();
        NSString * filePath = [moviePath stringByAppendingFormat:@"/%d.mp4",fileName];
        
        NSFileManager * fm = [NSFileManager defaultManager];
        if([fm fileExistsAtPath:filePath]){
            [fm removeItemAtPath:filePath error:nil];
        }
        [fm copyItemAtPath:videoPath toPath:filePath error:nil];
        
        UISaveVideoAtPathToSavedPhotosAlbum(filePath, self, @selector(video:didFinishSavingWithError:contextInfo:), nil);
        [self.exportbgView  removeFromSuperview];
//        self.progressView.progress = progress;
//        [bgView removeFromSuperview];
        [self.waitLabel removeFromSuperview];
        [self.progressView removeFromSuperview];
        [self.progressView setProgress:progress animated:YES];
        NSArray *urls = @[self->outputUrl];
        UIActivityViewController *activityVC = [[UIActivityViewController alloc] initWithActivityItems:urls applicationActivities:nil];
        NSArray *cludeActivitys = @[UIActivityTypeMail];
        activityVC.excludedActivityTypes = cludeActivitys;
        if ([activityVC respondsToSelector:@selector(popoverPresentationController)]) {        activityVC.popoverPresentationController.sourceView = [UIApplication sharedApplication].keyWindow;
            activityVC.popoverPresentationController.sourceRect = CGRectMake(0, [UIScreen mainScreen].bounds.size.height, [UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height);
        }
        [self presentViewController:activityVC animated:YES completion:^{
            // 合成成功后清理磁盘文件
            NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
            NSString *documentDirectory = paths.firstObject;
        //    NSString *saveFilePath = [documentDirectory stringByAppendingPathComponent:fileName];
            NSString * moviepath = [documentDirectory stringByAppendingPathComponent:@"Movie"];
            BOOL hidden = [[NSUserDefaults standardUserDefaults] boolForKey:@"videoexport"];
            if(hidden){
                moviepath = [documentDirectory stringByAppendingPathComponent:@"Racing"];
            }
            NSFileManager * fm = [NSFileManager defaultManager];
            NSArray<NSString *> * files = [fm contentsOfDirectoryAtPath:moviepath error:nil];

            for (NSString * file in files) {// && [file hasSuffix:@"_completed.mp4"]
                if(![file hasSuffix:@"_origin.mp4"] && ![file hasSuffix:@".txt"] && ![file hasSuffix:@"_completed.mp4"]){
        //        if([file hasSuffix:@"_completed.mp4"]){
                    [fm removeItemAtPath:[moviepath stringByAppendingPathComponent:file] error:nil];
                }
            }
        }];
    });
    
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
