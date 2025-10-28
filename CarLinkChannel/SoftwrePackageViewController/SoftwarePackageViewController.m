//
//  SoftwarePackageViewController.m
//  CarLinkChannel
//
//  重构版：使用新API获取文件列表
//

#import "SoftwarePackageViewController.h"
#import "TCUVehicleService.h"
#import "TCUAPIResponse.h"
#import "KeyChainProcess.h"
#import "TuneContentViewController.h"
#import "informationView.h"

@interface SoftwarePackageViewController () <UITableViewDelegate, UITableViewDataSource>

@property (weak, nonatomic) IBOutlet UITableView *tableView;

/// 数据源
@property (nonatomic, strong) NSArray<TCUFolderInfo *> *folders;
@property (nonatomic, strong) NSString *license;

/// 加载状态
@property (nonatomic, assign) BOOL isLoading;
@property (nonatomic, strong) UIActivityIndicatorView *loadingIndicator;

/// Header View
@property (nonatomic, strong) informationView *infoView;

/// 刷新按钮
@property (nonatomic, strong) UIBarButtonItem *refreshButton;

@end

@implementation SoftwarePackageViewController

#pragma mark - Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self setupUI];
    [self setupHeaderView];
    [self loadFileList];
}

#pragma mark - UI Setup

- (void)setupUI {
    // 设置导航栏
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc]
        initWithImage:[[UIImage imageNamed:@"escimg"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal]
        style:UIBarButtonItemStyleDone
        target:self
        action:@selector(didTapBackButton)];
    
    // 添加右侧刷新/更新按钮
//    self.refreshButton = [[UIBarButtonItem alloc]
//        initWithTitle:@"Update"
//        style:UIBarButtonItemStylePlain
//        target:self
//        action:@selector(didTapUpdateButton)];
//    self.navigationItem.rightBarButtonItem = self.refreshButton;
    
    self.title = @"Tuning Packages";
    self.navigationController.navigationBar.tintColor = [UIColor whiteColor];
    self.navigationController.navigationBar.barTintColor = [UIColor blackColor];
    NSDictionary *titleAttribute = @{NSForegroundColorAttributeName: [UIColor darkGrayColor]};
    self.navigationController.navigationBar.titleTextAttributes = titleAttribute;
    
    // 配置TableView
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.tableFooterView = [[UIView alloc] init];
    self.tableView.backgroundColor = [UIColor blackColor];
    self.tableView.separatorColor = [UIColor darkGrayColor];
    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:@"FolderCell"];
    
    // 创建加载指示器
    self.loadingIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleLarge];
    self.loadingIndicator.center = self.view.center;
    self.loadingIndicator.color = [UIColor whiteColor];
    [self.view addSubview:self.loadingIndicator];
    
    // 添加右滑返回手势
    UISwipeGestureRecognizer *rightSwipe = [[UISwipeGestureRecognizer alloc]
        initWithTarget:self
        action:@selector(didTapBackButton)];
    rightSwipe.direction = UISwipeGestureRecognizerDirectionRight;
    [self.view addGestureRecognizer:rightSwipe];
}

#pragma mark - Header View Setup

- (void)setupHeaderView {
    
    // 创建容器
    UIView *headerContainer = [[UIView alloc] initWithFrame:CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, 120)];
    headerContainer.backgroundColor = [UIColor blackColor];
    headerContainer.tag = 999; // 方便后续访问
    
    // 创建内容视图（圆角背景卡片）
    CGFloat margin = 20;
    CGFloat contentWidth = [UIScreen mainScreen].bounds.size.width - (margin * 2);
    UIView *contentView = [[UIView alloc] initWithFrame:CGRectMake(margin, 20, contentWidth, 85)];
    contentView.backgroundColor = [UIColor colorWithRed:35/255.0 green:35/255.0 blue:35/255.0 alpha:1.0];
    contentView.layer.cornerRadius = 8;
    contentView.layer.borderWidth = 1;
    contentView.layer.borderColor = [UIColor colorWithRed:60/255.0 green:60/255.0 blue:60/255.0 alpha:1.0].CGColor;
    [headerContainer addSubview:contentView];
    
    // 添加图标（如果有 SoftwreLogo 图片）
    UIImageView *logoView = [[UIImageView alloc] initWithFrame:CGRectMake(15, 22.5, 40, 40)];
    logoView.image = [UIImage imageNamed:@"SoftwreLogo"];
    logoView.contentMode = UIViewContentModeScaleAspectFit;
    if (logoView.image) {
        [contentView addSubview:logoView];
    }
    
    // VIN 标签
    CGFloat labelX = logoView.image ? 65 : 15; // 如果有图标就留空间
    UILabel *vinLabel = [[UILabel alloc] initWithFrame:CGRectMake(labelX, 15, contentWidth - labelX - 15, 25)];
    vinLabel.text = [NSString stringWithFormat:@"VIN: %@", self.vinString ?: @"Unknown"];
    vinLabel.textColor = [UIColor whiteColor];
    vinLabel.font = [UIFont systemFontOfSize:14];
    vinLabel.tag = 100; // ✅ 设置 tag，方便后续访问
    [contentView addSubview:vinLabel];
    
    // 文件名标签
    UILabel *nowLabel = [[UILabel alloc] initWithFrame:CGRectMake(labelX, 45, contentWidth - labelX - 15, 25)];
    if (self.binaryName && self.binaryName.length > 0) {
        nowLabel.text = [self getFileNameFormat:self.binaryName withVIN:self.vinString];
    } else {
        nowLabel.text = @"Loading...";
    }
    nowLabel.textColor = [UIColor colorWithRed:61/255.0 green:117/255.0 blue:169/255.0 alpha:1.0];
    nowLabel.font = [UIFont boldSystemFontOfSize:15];
    nowLabel.tag = 200; // ✅ 设置 tag，方便后续访问
    nowLabel.adjustsFontSizeToFitWidth = YES;
    nowLabel.minimumScaleFactor = 0.8;
    [contentView addSubview:nowLabel];
    
    // 设置为 TableView 的 header
    self.tableView.tableHeaderView = headerContainer;
}

/**
 * 格式化文件名显示（与原代码保持一致）
 */
- (NSString *)getFileNameFormat:(NSString *)fileName withVIN:(NSString *)vin {
    
    if (!fileName || fileName.length == 0) {
        return @"";
    }
    
    NSString *filenameWithoutExtension = [fileName stringByDeletingPathExtension];
    
    if (!vin || vin.length < 7) {
        return filenameWithoutExtension;
    }
    
    NSString *vinLast7Bytes = [vin substringFromIndex:[vin length] - 7];
    
    // 找到最后一个 "-" 的位置
    NSRange range = [filenameWithoutExtension rangeOfString:@"-" options:NSBackwardsSearch];
    NSString *resultString = nil;
    
    if (range.location != NSNotFound) {
        // 将原始字符串分为两部分
        NSString *firstPart = [filenameWithoutExtension substringToIndex:range.location];
        NSString *secondPart = [filenameWithoutExtension substringFromIndex:range.location];
        
        // 组合新的字符串
        resultString = [NSString stringWithFormat:@"%@%@-%@", firstPart, secondPart, vinLast7Bytes];
    } else {
        resultString = filenameWithoutExtension;
    }
    
    return resultString;
}


/**
 * 更新 Header 中的文件名标签
 */
- (void)updateHeaderFileName {
    
    NSLog(@"[SoftwarePackage] 🔄 更新 Header 文件名");
    
    // 获取 header container
    UIView *headerContainer = self.tableView.tableHeaderView;
    if (!headerContainer) {
        NSLog(@"[SoftwarePackage] ⚠️ Header container 不存在");
        return;
    }
    
    // 通过 tag 获取 nowLabel
    // 需要遍历找到 contentView 中的 label
    UILabel *nowLabel = nil;
    for (UIView *subview in headerContainer.subviews) {
        UILabel *label = (UILabel *)[subview viewWithTag:200];
        if (label) {
            nowLabel = label;
            break;
        }
    }
    
    if (nowLabel) {
        if (self.binaryName && self.binaryName.length > 0) {
            nowLabel.text = [self getFileNameFormat:self.binaryName withVIN:self.vinString];
            NSLog(@"[SoftwarePackage] ✅ 更新文件名: %@", nowLabel.text);
        } else {
            nowLabel.text = @"No file selected";
        }
    } else {
        NSLog(@"[SoftwarePackage] ⚠️ 未找到 nowLabel");
    }
}

#pragma mark - Data Loading

- (void)loadFileList {
    
    // 1. 获取License
    NSDictionary *keyDic = [KeyChainProcess getFromKeychainForKey:@"License"];
    self.license = keyDic[self.vinString];
    
    if (!self.license || self.license.length == 0) {
        [self showError:@"No activation code found. Please activate first."];
        return;
    }
    
    // 2. 显示加载状态
    self.isLoading = YES;
    [self.loadingIndicator startAnimating];
    self.tableView.hidden = YES;
    
    NSLog(@"[SoftwarePackage] 🔄 开始加载文件列表...");
    NSLog(@"  VIN: %@", self.vinString);
    NSLog(@"  License: %@", self.license);
    
    // 3. 调用API获取文件列表
    TCUVehicleService *service = [TCUVehicleService sharedService];
    [service getFileListWithVIN:self.vinString
                        license:self.license
                     completion:^(NSArray<TCUFolderInfo *> *folders, NSError *error) {
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.loadingIndicator stopAnimating];
            self.isLoading = NO;
            self.tableView.hidden = NO;
            
            if (error) {
                NSLog(@"[SoftwarePackage] ❌ 加载失败: %@", error.localizedDescription);
                [self showError:error.localizedDescription];
                return;
            }
            
            if (!folders || folders.count == 0) {
                NSLog(@"[SoftwarePackage] ⚠️ 文件列表为空");
                [self showError:@"No tuning packages available"];
                return;
            }
            
            // 4. 更新数据源
            self.folders = folders;
            NSLog(@"[SoftwarePackage] ✅ 加载成功: %lu 个文件夹", (unsigned long)folders.count);
            
            [self.tableView reloadData];
        });
    }];
}

#pragma mark - Update/Refresh

/**
 * 点击 Update 按钮
 */
- (IBAction)didTapUpdateButton:(id)sender {
    NSLog(@"[SoftwarePackage] 🔄 用户点击更新按钮");
    
    [self performUpdate];
}
//- (void)didTapUpdateButton {
//    
//    NSLog(@"[SoftwarePackage] 🔄 用户点击更新按钮");
//    
//    // 显示确认对话框
//    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Update Files"
//                                                                   message:@"Check for latest files and update the list?"
//                                                            preferredStyle:UIAlertControllerStyleAlert];
//    
//    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"Cancel"
//                                                           style:UIAlertActionStyleCancel
//                                                         handler:nil];
//    
//    UIAlertAction *updateAction = [UIAlertAction actionWithTitle:@"Update"
//                                                           style:UIAlertActionStyleDefault
//                                                         handler:^(UIAlertAction *action) {
//        [self performUpdate];
//    }];
//    
//    [alert addAction:cancelAction];
//    [alert addAction:updateAction];
//    [self presentViewController:alert animated:YES completion:nil];
//}

/**
 * 执行更新流程
 */
- (void)performUpdate {
    
    NSLog(@"[SoftwarePackage] 🔄 开始更新流程...");
    
    // 1. 禁用按钮
    self.refreshButton.enabled = NO;
    
    // 2. 显示加载状态
    [self.loadingIndicator startAnimating];
    
    // 3. 获取 License
    NSDictionary *keyDic = [KeyChainProcess getFromKeychainForKey:@"License"];
    self.license = keyDic[self.vinString];
    
    if (!self.license || self.license.length == 0) {
        [self showUpdateError:@"No activation code found"];
        self.refreshButton.enabled = YES;
        [self.loadingIndicator stopAnimating];
        return;
    }
    
    // 4. 第一步：获取最新的 BinFileName
    TCUVehicleService *service = [TCUVehicleService sharedService];
    [service getFileStateWithVIN:self.vinString
                         license:self.license
                      completion:^(NSString *binFileName, NSError *error) {
        
        if (error) {
            NSLog(@"[SoftwarePackage] ❌ 获取文件状态失败: %@", error.localizedDescription);
            dispatch_async(dispatch_get_main_queue(), ^{
                [self showUpdateError:@"Failed to get file state"];
                self.refreshButton.enabled = YES;
                [self.loadingIndicator stopAnimating];
            });
            return;
        }
        
        NSLog(@"[SoftwarePackage] ✅ 获取到最新的 BinFileName: %@", binFileName);
        
        // 5. 更新 binaryName
        dispatch_async(dispatch_get_main_queue(), ^{
            self.binaryName = binFileName;
            
            // 6. 刷新 Header 中的文件名标签
            [self updateHeaderFileName];
            
            // 7. 第二步：重新获取文件列表
            [self reloadFileList];
        });
    }];
}

/**
 * 重新加载文件列表
 */
- (void)reloadFileList {
    
    NSLog(@"[SoftwarePackage] 🔄 重新加载文件列表...");
    
    TCUVehicleService *service = [TCUVehicleService sharedService];
    [service getFileListWithVIN:self.vinString
                        license:self.license
                     completion:^(NSArray<TCUFolderInfo *> *folders, NSError *error) {
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.loadingIndicator stopAnimating];
            self.refreshButton.enabled = YES;
            
            if (error) {
                NSLog(@"[SoftwarePackage] ❌ 重新加载列表失败: %@", error.localizedDescription);
                [self showUpdateError:@"Failed to reload file list"];
                return;
            }
            
            if (!folders || folders.count == 0) {
                NSLog(@"[SoftwarePackage] ⚠️ 文件列表为空");
                [self showUpdateError:@"No files available"];
                return;
            }
            
            // 更新数据源
            self.folders = folders;
            NSLog(@"[SoftwarePackage] ✅ 更新成功: %lu 个文件夹", (unsigned long)folders.count);
            
            // 刷新表格
            [self.tableView reloadData];
            
            // 显示成功提示
            [self showUpdateSuccess];
        });
    }];
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (self.isLoading) {
        return 0;
    }
    
    if (!self.folders || self.folders.count == 0) {
        tableView.separatorColor = [UIColor clearColor];
        return 1; // 显示空状态
    }
    
    tableView.separatorColor = [UIColor whiteColor];
    return self.folders.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"FolderCell" forIndexPath:indexPath];
    
    // 清空之前的accessoryView
    cell.accessoryView = nil;
    
    // 设置基础样式
    cell.backgroundColor = [UIColor clearColor];
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    cell.textLabel.textColor = [UIColor whiteColor];
    cell.textLabel.font = [UIFont systemFontOfSize:17];
    
    // 空状态
    if (!self.folders || self.folders.count == 0) {
        cell.textLabel.text = @"No tuning packages available";
        cell.textLabel.textAlignment = NSTextAlignmentCenter;
        cell.textLabel.textColor = [UIColor colorWithRed:52/255.0 green:97/255.0 blue:139/255.0 alpha:1.0];
        return cell;
    }
    
    // 正常数据
    TCUFolderInfo *folder = self.folders[indexPath.row];
    cell.textLabel.text = folder.folderName;
    cell.textLabel.textAlignment = NSTextAlignmentLeft;
    
    // 特殊处理：OBD Unlock - STEP 1 使用粗体
    if ([folder.folderName isEqualToString:@"OBD Unlock - STEP 1"]) {
        cell.textLabel.font = [UIFont boldSystemFontOfSize:17];
    }
    
    // 特殊处理：xHP Tuning style 系列显示为灰色（可能是未启用的）
    if ([folder.folderName isEqual:@"xHP Tuning style Stage 1"] ||
        [folder.folderName isEqual:@"xHP Tuning style Stage 2"] ||
        [folder.folderName isEqual:@"xHP Tuning style Stage 3"]) {
        cell.textLabel.textColor = [UIColor lightGrayColor];
    }
    
    // 添加右箭头
    UIImageView *arrowView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 11, 14)];
    arrowView.image = [UIImage imageNamed:@"rightallow"];
    arrowView.contentMode = UIViewContentModeScaleAspectFit;
    cell.accessoryView = arrowView;
    
    return cell;
}

#pragma mark - UITableViewDelegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 60;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    // 空状态不可点击
    if (!self.folders || self.folders.count == 0) {
        return;
    }
    
    // 获取选中的文件夹
    TCUFolderInfo *selectedFolder = self.folders[indexPath.row];
    
    NSLog(@"[SoftwarePackage] 📁 用户选择: %@", selectedFolder.folderName);
    
    // 跳转到下一个界面
    UIStoryboard *sb = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    TuneContentViewController *tuneController = [sb instantiateViewControllerWithIdentifier:@"TuneContentViewController"];
    
    // 传递数据
    tuneController.selectedFolderName = selectedFolder.folderName;
    tuneController.displayContent = selectedFolder.displayContent;
    tuneController.vinString = self.vinString;
    tuneController.license = self.license;
    
    [self.navigationController pushViewController:tuneController animated:YES];
}

#pragma mark - Actions

- (void)didTapBackButton {
    [self.navigationController popViewControllerAnimated:YES];
}

#pragma mark - Helper Methods

- (void)showError:(NSString *)message {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Error"
                                                                   message:message
                                                            preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"OK"
                                                       style:UIAlertActionStyleDefault
                                                     handler:^(UIAlertAction *action) {
        [self.navigationController popViewControllerAnimated:YES];
    }];
    [alert addAction:okAction];
    [self presentViewController:alert animated:YES completion:nil];
}

/**
 * 显示更新成功提示
 */
- (void)showUpdateSuccess {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Success"
                                                                   message:@"Files updated successfully!"
                                                            preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"OK"
                                                       style:UIAlertActionStyleDefault
                                                     handler:nil];
    [alert addAction:okAction];
    [self presentViewController:alert animated:YES completion:nil];
}

/**
 * 显示更新错误
 */
- (void)showUpdateError:(NSString *)message {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Update Failed"
                                                                   message:message
                                                            preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"OK"
                                                       style:UIAlertActionStyleDefault
                                                     handler:nil];
    [alert addAction:okAction];
    [self presentViewController:alert animated:YES completion:nil];
}

@end
