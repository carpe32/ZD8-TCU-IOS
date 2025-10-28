//
//  TuneContentViewController.m
//  CarLinkChannel
//
//  重构版：每次重新下载，内存解压，AES解密，发送数据给刷写模块
//

#import "TuneContentViewController.h"
#import "TCUVehicleService.h"
#import "KeyChainProcess.h"
#import "Constents.h"
#import "SSZipArchive.h"
#import <CommonCrypto/CommonCryptor.h>
#import <CommonCrypto/CommonDigest.h>

@interface TuneContentViewController ()

@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UITextView *contentTextView;
@property (weak, nonatomic) IBOutlet UIButton *programmingButton;

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
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
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

#pragma mark - Actions

- (IBAction)programming:(id)sender {
    // 每次都重新下载，显示确认对话框
    [self showConfirmFlashDialog];
}

#pragma mark - Flash Confirmation & Download

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
    
    NSLog(@"[TuneContent] ✅ 用户确认刷写，开始下载...");
    
    [self dismissConfirmView];
    
    // 开始下载和处理流程
    [self startDownloadAndProcess];
}

#pragma mark - Download & Process

- (void)startDownloadAndProcess {
    
    NSLog(@"[TuneContent] 🚀 开始下载文件...");
    NSLog(@"  VIN: %@", self.vinString);
    NSLog(@"  Folder: %@", self.selectedFolderName);
    
    // 显示进度UI
    [self showProgressView];
    [self updateProgress:0.0 message:@"Downloading..."];
    
    // 获取 HWID 和 License
    NSString *hwid = @"IOS_Device";  // 如果需要HWID，请从KeyChain或其他地方获取
    NSDictionary *keyDic = [KeyChainProcess getFromKeychainForKey:@"License"];
    NSString *license = keyDic[self.vinString];
    
    if (!license || license.length == 0) {
        [self hideProgressView];
        [self showAlert:@"Error" message:@"No activation code found"];
        return;
    }
    
    // 获取 ProgramSha256 (需要从配置文件或代码中获取)
    NSString *programSha256 = @"08545f2b8a8c2aeb4eae01c7562cef8a5529662c2eb52dea54651ed646834d5b";  // TODO: 从配置文件读取
    
    // 调用下载API
    TCUVehicleService *service = [TCUVehicleService sharedService];
    [service downloadFileWithVIN:self.vinString
                            hwid:hwid
                         license:license
                    selectedFile:self.selectedFolderName
                   programSha256:programSha256
                      completion:^(BOOL success, NSData *fileData, NSError *error) {
        
        dispatch_async(dispatch_get_main_queue(), ^{
            
            if (!success || error) {
                [self hideProgressView];
                NSLog(@"[TuneContent] ❌ 下载失败: %@", error.localizedDescription);
                [self showAlert:@"Download Failed" message:error.localizedDescription ?: @"Unknown error"];
                return;
            }
            
            if (!fileData || fileData.length == 0) {
                [self hideProgressView];
                NSLog(@"[TuneContent] ❌ 下载的文件为空");
                [self showAlert:@"Download Failed" message:@"Downloaded file is empty"];
                return;
            }
            
            NSLog(@"[TuneContent] ✅ 下载成功: %lu bytes", (unsigned long)fileData.length);
            
            // 服务器返回的是已加密的 tune.bin 数据
            // 需要：1. 解密  2. 发送给刷写模块
            [self updateProgress:0.5 message:@"Decrypting..."];
            
            // 解密数据
            [self processDownloadedData:fileData];
        });
    }];
}

- (void)processDownloadedData:(NSData *)encryptedData {
    
    NSLog(@"[TuneContent] 🔓 开始解密数据...");
    
    // 服务器使用客户端密码加密: "WhatZd8Q1w2e3r4!@#$"
    NSString *clientPassword = @"WhatZd8Q1w2e3r4!@#$";
    
    // 解密数据
    NSData *decryptedData = [self aes256DecryptData:encryptedData withPassword:clientPassword];
    
    if (!decryptedData || decryptedData.length == 0) {
        [self hideProgressView];
        NSLog(@"[TuneContent] ❌ 解密失败");
        [self showAlert:@"Decryption Failed" message:@"Failed to decrypt file"];
        return;
    }
    
    NSLog(@"[TuneContent] ✅ 解密成功: %lu bytes", (unsigned long)decryptedData.length);
    [self updateProgress:0.9 message:@"Processing..."];
    
    // 验证数据中的VIN (0x04-0x14位置)
    if (decryptedData.length >= 0x15) {
        NSData *vinData = [decryptedData subdataWithRange:NSMakeRange(0x04, 17)];
        NSString *embeddedVin = [[NSString alloc] initWithData:vinData encoding:NSASCIIStringEncoding];
        NSLog(@"[TuneContent] 📝 嵌入的VIN: %@", embeddedVin);
        
        if (![embeddedVin isEqualToString:self.vinString]) {
            NSLog(@"[TuneContent] ⚠️ VIN不匹配: 期望=%@, 实际=%@", self.vinString, embeddedVin);
        }
    }
    
    // 发送通知给刷写模块
    [self updateProgress:1.0 message:@"Ready to flash!"];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self hideProgressView];
        [self sendFlashNotification:decryptedData];
    });
}

#pragma mark - AES Decryption

/**
 * AES-256 解密
 * 对应服务器端的 EncryptForClient 方法
 * 算法: AES-256-CBC
 * Key: SHA256(clientPassword) - 32字节
 * IV: Key的前16字节
 */
- (NSData *)aes256DecryptData:(NSData *)encryptedData withPassword:(NSString *)password {
    
    if (!encryptedData || encryptedData.length == 0 || !password) {
        return nil;
    }
    
    // 1. 使用 SHA256 生成 32 字节密钥
    const char *cstr = [password cStringUsingEncoding:NSUTF8StringEncoding];
    unsigned char digest[CC_SHA256_DIGEST_LENGTH];
    CC_SHA256(cstr, (CC_LONG)strlen(cstr), digest);
    
    NSData *keyData = [NSData dataWithBytes:digest length:CC_SHA256_DIGEST_LENGTH];
    
    // 2. IV 使用 Key 的前 16 字节
    NSData *ivData = [keyData subdataWithRange:NSMakeRange(0, kCCBlockSizeAES128)];
    
    NSLog(@"[TuneContent] 🔑 密钥长度: %lu bytes", (unsigned long)keyData.length);
    NSLog(@"[TuneContent] 🔑 IV长度: %lu bytes", (unsigned long)ivData.length);
    
    // 3. 准备解密
    NSUInteger dataLength = encryptedData.length;
    size_t bufferSize = dataLength + kCCBlockSizeAES128;
    void *buffer = malloc(bufferSize);
    
    size_t numBytesDecrypted = 0;
    
    // 4. 执行解密
    // 算法: kCCAlgorithmAES (AES-256)
    // 模式: CBC (通过 kCCOptionPKCS7Padding 隐含)
    // Padding: PKCS7
    CCCryptorStatus cryptStatus = CCCrypt(kCCDecrypt,                    // 解密操作
                                          kCCAlgorithmAES,                // AES算法
                                          kCCOptionPKCS7Padding,          // PKCS7填充
                                          keyData.bytes,                  // 密钥
                                          keyData.length,                 // 密钥长度 (32字节 = AES-256)
                                          ivData.bytes,                   // IV
                                          encryptedData.bytes,            // 输入数据
                                          dataLength,                     // 输入数据长度
                                          buffer,                         // 输出缓冲区
                                          bufferSize,                     // 输出缓冲区大小
                                          &numBytesDecrypted);            // 实际解密字节数
    
    if (cryptStatus == kCCSuccess) {
        NSLog(@"[TuneContent] ✅ AES解密成功: %zu bytes", numBytesDecrypted);
        NSData *decryptedData = [NSData dataWithBytesNoCopy:buffer length:numBytesDecrypted];
        return decryptedData;
    } else {
        NSLog(@"[TuneContent] ❌ AES解密失败: CCCryptorStatus=%d", cryptStatus);
        free(buffer);
        return nil;
    }
}

#pragma mark - Send Flash Notification

- (void)sendFlashNotification:(NSData *)decryptedData {
    
    NSLog(@"[TuneContent] 📤 发送刷写通知: %@", begin_start_install_notify_name);
    NSLog(@"  数据大小: %lu bytes", (unsigned long)decryptedData.length);
    NSLog(@"  文件夹: %@", self.selectedFolderName);
    NSLog(@"  VIN: %@", self.vinString);
    
    // 构建通知数据
    NSDictionary *dataDict = @{
        @"data": decryptedData,                         // 解密后的数据
        @"folderName": self.selectedFolderName ?: @"", // 文件夹名称
        @"vin": self.vinString ?: @"",                 // VIN
        @"fileName": self.selectedFolderName                        // 文件名
    };
    
    // 发送通知
    [[NSNotificationCenter defaultCenter] postNotificationName:begin_start_install_notify_name
                                                        object:nil
                                                      userInfo:dataDict];
    
    // 提示用户
    [self showAlert:@"Flashing Started"
            message:@"Programming process has been initiated. Please wait..."];
}

#pragma mark - Progress View

- (void)showProgressView {
    
    if (!self.progressView) {
        // 创建进度条
        self.progressView = [[UIProgressView alloc] initWithProgressViewStyle:UIProgressViewStyleDefault];
        self.progressView.frame = CGRectMake(40, self.view.center.y - 10, self.view.bounds.size.width - 80, 4);
        self.progressView.progressTintColor = [UIColor systemBlueColor];
        self.progressView.trackTintColor = [UIColor darkGrayColor];
        
        // 创建进度标签
        self.progressLabel = [[UILabel alloc] initWithFrame:CGRectMake(40, CGRectGetMaxY(self.progressView.frame) + 10, self.view.bounds.size.width - 80, 30)];
        self.progressLabel.textAlignment = NSTextAlignmentCenter;
        self.progressLabel.textColor = [UIColor whiteColor];
        self.progressLabel.font = [UIFont systemFontOfSize:14];
    }
    
    self.progressView.progress = 0.0;
    [self.view addSubview:self.progressView];
    [self.view addSubview:self.progressLabel];
}

- (void)updateProgress:(float)progress message:(NSString *)message {
    
    self.progressView.progress = progress;
    self.progressLabel.text = message;
}

- (void)hideProgressView {
    
    [self.progressView removeFromSuperview];
    [self.progressLabel removeFromSuperview];
}

#pragma mark - Navigation

- (void)didTapBackButton {
    [self.navigationController popViewControllerAnimated:YES];
}

#pragma mark - Alert Helper

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
