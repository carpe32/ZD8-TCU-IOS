//
//  TuneContentViewController.m
//  CarLinkChannel
//
//  重构版：显示文件夹说明并下载文件
//

#import "TuneContentViewController.h"
#import "TCUVehicleService.h"
#import "KeyChainProcess.h"
#import "Constents.h"

@interface TuneContentViewController ()

@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UITextView *contentTextView;
@property (weak, nonatomic) IBOutlet UIButton *programmingButton;

/// 下载相关
@property (nonatomic, strong) NSData *downloadedFileData;
@property (nonatomic, strong) NSString *localFilePath;
@property (nonatomic, assign) BOOL isDownloading;
@property (nonatomic, assign) BOOL isDownloaded;

/// UI组件
@property (nonatomic, strong) UIView *bgView;
@property (nonatomic, strong) UIView *confirmView;
@property (nonatomic, strong) UIProgressView *progressView;
@property (nonatomic, strong) UILabel *progressLabel;

@end

@implementation TuneContentViewController

#pragma mark - Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self setupUI];
    [self loadContent];
    [self checkLocalFile];
}

#pragma mark - Setup

- (void)setupUI {
    // 导航栏
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc]
        initWithImage:[[UIImage imageNamed:@"escimg"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal]
        style:UIBarButtonItemStyleDone
        target:self
        action:@selector(didTapBackButton)];
    
    self.title = @"Tuning Notes";
    self.navigationController.navigationBar.tintColor = [UIColor whiteColor];
    self.navigationController.navigationBar.barTintColor = [UIColor blackColor];
    NSDictionary *titleAttribute = @{NSForegroundColorAttributeName: [UIColor darkGrayColor]};
    self.navigationController.navigationBar.titleTextAttributes = titleAttribute;
    
    // 标题和内容
    if (self.titleLabel) {
        self.titleLabel.text = self.selectedFolderName ?: @"";
    }
    
    if (self.contentTextView) {
        self.contentTextView.editable = NO;
        self.contentTextView.backgroundColor = [UIColor blackColor];
        self.contentTextView.textColor = [UIColor whiteColor];
        self.contentTextView.font = [UIFont systemFontOfSize:14];
    }
    
    // 添加右滑返回手势
    UISwipeGestureRecognizer *rightSwipe = [[UISwipeGestureRecognizer alloc]
        initWithTarget:self
        action:@selector(didTapBackButton)];
    rightSwipe.direction = UISwipeGestureRecognizerDirectionRight;
    [self.view addGestureRecognizer:rightSwipe];
}

- (void)loadContent {
    // 显示 DisplayContent
    if (self.displayContent && self.displayContent.length > 0) {
        self.contentTextView.text = self.displayContent;
    } else if (self.binFilePath) {
        // 兼容旧方式：从本地文件读取
        NSString *showFilePath = [self.binFilePath stringByAppendingPathComponent:SHOW_TXT];
        NSString *content = [NSString stringWithContentsOfFile:showFilePath
                                                      encoding:NSUTF8StringEncoding
                                                         error:nil];
        self.contentTextView.text = content ?: @"No description available.";
    } else {
        self.contentTextView.text = @"No description available.";
    }
}

- (void)checkLocalFile {
    // 检查本地是否已下载该文件
    NSString *documentsPath = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)[0];
    NSString *folderPath = [documentsPath stringByAppendingPathComponent:@"DownloadedFiles"];
    self.localFilePath = [folderPath stringByAppendingPathComponent:[NSString stringWithFormat:@"%@_%@.bin",
                                                                      self.vinString,
                                                                      self.selectedFolderName]];
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:self.localFilePath]) {
        self.isDownloaded = YES;
        NSLog(@"[TuneContent] ✅ 文件已下载: %@", self.localFilePath);
    } else {
        self.isDownloaded = NO;
        NSLog(@"[TuneContent] ⚠️ 文件未下载");
    }
}

#pragma mark - Actions

- (IBAction)programming:(id)sender {
    
    if (self.isDownloading) {
        [self showAlert:@"Downloading" message:@"Please wait for download to complete"];
        return;
    }
    
    if (self.isDownloaded) {
        // 文件已下载，直接刷写
        [self showConfirmFlashDialog];
    } else {
        // 需要先下载
        [self showDownloadDialog];
    }
}

#pragma mark - Download

- (void)showDownloadDialog {
    
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Download Required"
                                                                   message:@"This file needs to be downloaded first. Download now?"
                                                            preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"Cancel"
                                                           style:UIAlertActionStyleCancel
                                                         handler:nil];
    
    UIAlertAction *downloadAction = [UIAlertAction actionWithTitle:@"Download"
                                                             style:UIAlertActionStyleDefault
                                                           handler:^(UIAlertAction *action) {
        [self startDownload];
    }];
    
    [alert addAction:cancelAction];
    [alert addAction:downloadAction];
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)startDownload {
    
    NSLog(@"[TuneContent] 🔄 开始下载文件...");
    NSLog(@"  VIN: %@", self.vinString);
    NSLog(@"  Folder: %@", self.selectedFolderName);
    NSLog(@"  License: %@", self.license);
    
    // 显示下载进度UI
    [self showDownloadProgress];
    
    self.isDownloading = YES;
    
    // 调用下载API
    TCUVehicleService *service = [TCUVehicleService sharedService];
    [service downloadFileWithVIN:self.vinString
                            hwid:@"IOS_Device"
                         license:self.license
                    selectedFile:self.selectedFolderName
                   programSha256:@"" // 如果需要，可以计算APP的SHA256
                      completion:^(BOOL success, NSData *fileData, NSError *error) {
        
        dispatch_async(dispatch_get_main_queue(), ^{
            self.isDownloading = NO;
            [self hideDownloadProgress];
            
            if (error) {
                NSLog(@"[TuneContent] ❌ 下载失败: %@", error.localizedDescription);
                [self showAlert:@"Download Failed" message:error.localizedDescription];
                return;
            }
            
            if (!success || !fileData || fileData.length == 0) {
                NSLog(@"[TuneContent] ❌ 下载的文件为空");
                [self showAlert:@"Download Failed" message:@"Downloaded file is empty"];
                return;
            }
            
            // 保存文件到本地
            NSLog(@"[TuneContent] ✅ 下载成功: %lu bytes", (unsigned long)fileData.length);
            [self saveDownloadedFile:fileData];
        });
    }];
}

- (void)saveDownloadedFile:(NSData *)fileData {
    
    NSFileManager *fm = [NSFileManager defaultManager];
    
    // 创建目录
    NSString *folderPath = [self.localFilePath stringByDeletingLastPathComponent];
    if (![fm fileExistsAtPath:folderPath]) {
        NSError *error;
        [fm createDirectoryAtPath:folderPath withIntermediateDirectories:YES attributes:nil error:&error];
        if (error) {
            NSLog(@"[TuneContent] ❌ 创建目录失败: %@", error);
            return;
        }
    }
    
    // 保存文件
    NSError *error;
    BOOL success = [fileData writeToFile:self.localFilePath options:NSDataWritingAtomic error:&error];
    
    if (success) {
        NSLog(@"[TuneContent] ✅ 文件保存成功: %@", self.localFilePath);
        self.isDownloaded = YES;
        self.downloadedFileData = fileData;
        
        [self showAlert:@"Download Complete" message:@"File downloaded successfully. Ready to flash!"];
    } else {
        NSLog(@"[TuneContent] ❌ 文件保存失败: %@", error);
        [self showAlert:@"Save Failed" message:@"Failed to save file"];
    }
}

#pragma mark - Flash Confirmation

- (void)showConfirmFlashDialog {
    
    // 创建背景遮罩
    if (self.bgView) {
        [self.bgView removeFromSuperview];
    }
    
    self.bgView = [[UIView alloc] initWithFrame:[UIScreen mainScreen].bounds];
    self.bgView.backgroundColor = [UIColor blackColor];
    self.bgView.alpha = 0.6;
    [self.view addSubview:self.bgView];
    
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc]
        initWithTarget:self
        action:@selector(dismissConfirmView)];
    [self.bgView addGestureRecognizer:tap];
    
    // 创建确认视图
    if (self.confirmView) {
        [self.confirmView removeFromSuperview];
    }
    
    self.confirmView = [[NSBundle mainBundle] loadNibNamed:@"WarnPopView" owner:nil options:nil][0];
    if (self.confirmView) {
        self.confirmView.frame = CGRectMake(0,
                                            [UIScreen mainScreen].bounds.size.height - 510,
                                            [UIScreen mainScreen].bounds.size.width,
                                            520);
        
        UIButton *okButton = [self.confirmView viewWithTag:100];
        [okButton addTarget:self action:@selector(confirmFlash) forControlEvents:UIControlEventTouchUpInside];
        
        [self.view addSubview:self.confirmView];
    }
}

- (void)dismissConfirmView {
    [self.bgView removeFromSuperview];
    [self.confirmView removeFromSuperview];
}

- (void)confirmFlash {
    
    NSLog(@"[TuneContent] ✅ 用户确认刷写");
    
    [self dismissConfirmView];
    
    // 发送通知，开始刷写
    NSDictionary *dataDict = @{
        @"path": self.localFilePath ?: self.binFilePath
    };
    [[NSNotificationCenter defaultCenter] postNotificationName:begin_start_install_notify_name
                                                        object:nil
                                                      userInfo:dataDict];
    
    // 返回到上一级
    NSArray<UIViewController *> *controllers = self.navigationController.viewControllers;
    if (controllers.count > 1) {
        UIViewController *previousVC = controllers[1];
        [self.navigationController popToViewController:previousVC animated:YES];
    } else {
        [self.navigationController popViewControllerAnimated:YES];
    }
}

#pragma mark - Download Progress UI

- (void)showDownloadProgress {
    
    // 创建进度视图
    UIView *progressContainer = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 280, 100)];
    progressContainer.center = self.view.center;
    progressContainer.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.9];
    progressContainer.layer.cornerRadius = 10;
    progressContainer.tag = 9999;
    
    // 标题
    UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 20, 280, 30)];
    titleLabel.text = @"Downloading...";
    titleLabel.textAlignment = NSTextAlignmentCenter;
    titleLabel.textColor = [UIColor whiteColor];
    titleLabel.font = [UIFont boldSystemFontOfSize:16];
    [progressContainer addSubview:titleLabel];
    
    // 进度条
    self.progressView = [[UIProgressView alloc] initWithFrame:CGRectMake(20, 60, 240, 10)];
    self.progressView.progressTintColor = [UIColor colorWithRed:61/255.0 green:117/255.0 blue:169/255.0 alpha:1.0];
    [progressContainer addSubview:self.progressView];
    
    // 进度文字
    self.progressLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 75, 280, 20)];
    self.progressLabel.text = @"0%";
    self.progressLabel.textAlignment = NSTextAlignmentCenter;
    self.progressLabel.textColor = [UIColor lightGrayColor];
    self.progressLabel.font = [UIFont systemFontOfSize:12];
    [progressContainer addSubview:self.progressLabel];
    
    [self.view addSubview:progressContainer];
}

- (void)hideDownloadProgress {
    UIView *progressContainer = [self.view viewWithTag:9999];
    [progressContainer removeFromSuperview];
}

- (void)updateDownloadProgress:(CGFloat)progress {
    dispatch_async(dispatch_get_main_queue(), ^{
        self.progressView.progress = progress;
        self.progressLabel.text = [NSString stringWithFormat:@"%.0f%%", progress * 100];
    });
}

#pragma mark - Helper Methods

- (void)didTapBackButton {
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)showAlert:(NSString *)title message:(NSString *)message {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:title
                                                                   message:message
                                                            preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"OK"
                                                       style:UIAlertActionStyleDefault
                                                     handler:nil];
    [alert addAction:okAction];
    [self presentViewController:alert animated:YES completion:nil];
}

@end
