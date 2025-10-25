//
//  ConnectionViewController.m
//  CarLinkChannel
//
//  Created by job on 2023/3/27.
//

#import "ConnectionViewController.h"
#import "NavigationView.h"

#import "NetworkInterface.h"
#import "ActivationView.h"

#import "SoftwarePackageViewController.h"
#import "LeftMenuView.h"
#import "SpeedTestViewController.h"
#import "ConnectionPersenter.h"

#import "EcuInstallView.h"
#import "SSZipArchive.h"
#import "TCUAPIService.h"
#import "TCUAPIConfig.h"
#import "TCUVehicleService.h"

static const DDLogLevel ddLogLevel = DDLogLevelVerbose;
@interface ConnectionViewController()<NavigationViewDelegate,LeftMenuDelegate,FlashFeedbackDelegate>
{
    VersionManager *versionManager;
    dispatch_source_t animation_t_car;
    dispatch_source_t animation_t_internet;
    UIView * bgView;
    ActivationView * activationView;
    NSArray * cafdArray;
    UIButton * validButton;
    UITextField * textField;
    UITextView * infoTextView;
    NSMutableArray * svtArray;
    LeftMenuView * leftMenu;
    __block NSString * binaryName;
    ConnectionPersenter * persenter;


    
    EcuInstallView * installView;
    NSString * VehicleVin;
    NSArray *VehicleSvt;
    int serotype;
    NSString *LastflashFileName;
    NSDictionary *FlashpreparatoryDict;
    NSDictionary *FlashPersentDict;
    NSDictionary *FlashFinishDict;
    NSDictionary *FlashErrorCodeDict;
    NSInteger ProcessCount;
    NSArray *LoadCafd;
    NSString *AfterProcessPath;
}
@property (weak, nonatomic) IBOutlet UIImageView *graystatusimg1;
@property (weak, nonatomic) IBOutlet UIImageView *statusimg1;
@property (weak, nonatomic) IBOutlet UIImageView *graylineimg1;
@property (weak, nonatomic) IBOutlet UIImageView *lineimg1;
@property (weak, nonatomic) IBOutlet UIImageView *graylineimg2;
@property (weak, nonatomic) IBOutlet UIImageView *lineimg2;
@property (weak, nonatomic) IBOutlet UIImageView *graystatusimg2;
@property (weak, nonatomic) IBOutlet UIImageView *statusimg2;

@property (nonatomic, strong) UIView * carView;
@property (nonatomic, strong) UIView * lineView1;
@property (nonatomic, strong) UIView * lineView2;
@property (nonatomic, strong) UIView * internetView;

@property (weak, nonatomic) IBOutlet UIButton *activationButton;
@property (weak, nonatomic) IBOutlet UIButton *nextButton;

@property(nonatomic, strong) AutoNetworkService *AutoNetworkManager;
@end

@implementation ConnectionViewController

-(void)viewDidLoad{
    versionManager = [VersionManager sharedInstance];

    self.activationButton.enabled = NO;
    self.nextButton.enabled = NO;
    
    [self initStatusImage];
    [self startNetworkAnimation];
    
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[[UIImage imageNamed:@"leftMenu"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal] style:UIBarButtonItemStyleDone target:self action:@selector(didTapEscButton)];
    self.title = @"Connection";
    self.navigationController.navigationBar.tintColor = [UIColor whiteColor];
    self.navigationController.navigationBar.barTintColor = [UIColor blackColor];
    NSDictionary * titleAttribute = @{NSForegroundColorAttributeName:[UIColor darkGrayColor]};
    self.navigationController.navigationBar.titleTextAttributes = titleAttribute;
    cafdArray = [NSMutableArray array];
    
    persenter = [[ConnectionPersenter alloc] init];
    persenter.rootViewController = self;
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHidden:) name:UIKeyboardWillHideNotification object:nil];
    
    UITapGestureRecognizer * tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapViewTarget)];
    [self.view addGestureRecognizer:tap];
    [self addAllNotification];
//    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH,0), ^{
//        [self InitVehicleNetwork];
//        if([self checkEcuSupport:self->VehicleSvt])
//        {
//            [self CafdAndMidProcess];
//            [self DisplayCheckVehicleStatus];
//            [self checkLicenseAndSetButton];
//        }
//    });
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH,0), ^{
        [self InitVehicleNetwork];
        [self uploadVehicleInfoAndCheckSupport];  // 新方法
    });
    [self InitInstallView];
    [self storeMacrosInDictionary];
}


- (void)uploadVehicleInfoAndCheckSupport {
    
    // 1. 检查VIN和SVT是否已获取
    if (!self->VehicleVin || self->VehicleVin.length == 0) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self PrintInformationToDisplayLog:error_prefix :@"未能读取车辆VIN信息"];
        });
        return;
    }
    
    if (!self->VehicleSvt || self->VehicleSvt.count == 0) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self PrintInformationToDisplayLog:error_prefix :@"未能读取车辆SVT信息"];
        });
        return;
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [self PrintInformationToDisplayLog:info_prefix :@"正在上传车辆信息..."];
    });
    
    // 2. 调用新API上传车辆信息
    [self uploadVehicleInfoWithCompletion:^(BOOL success, NSString *binFileName, NSError *error) {
        
        if (!success || error) {
            // 上传失败
            dispatch_async(dispatch_get_main_queue(), ^{
                NSString *errorMsg = error ? error.localizedDescription : @"车辆信息上传失败";
                [self PrintInformationToDisplayLog:error_prefix :errorMsg];
            });
            return;
        }
        
        // 3. 检查车辆是否支持
        if ([self checkVehicleSupportWithBinFileName:binFileName]) {
            // 车辆支持
            dispatch_async(dispatch_get_main_queue(), ^{
                [self PrintInformationToDisplayLog:info_prefix :@"车辆支持刷写"];
            });
            
            // 4. 继续原有流程
            [self CafdAndMidProcess];
            [self DisplayCheckVehicleStatus];
            
            // 5. 检查激活状态
            [self checkActivationStatus];
            
        } else {
            // 车辆不支持
            dispatch_async(dispatch_get_main_queue(), ^{
                [self PrintInformationToDisplayLog:error_prefix :ECU_UNSUPPORTED];
            });
        }
    }];
}

//
//  ConnectionViewController+NewAPI.m
//  完整的车辆信息上传方法
//

#pragma mark - 上传车辆信息到服务器

/**
 * 调用 /api/users/VehicleMsg/info 上传车辆信息
 * 使用TCUAPIService的公开方法，不直接访问urlSession
 */
- (void)uploadVehicleInfoWithCompletion:(void(^)(BOOL success, NSString *binFileName, NSError *error))completion {

    // 1. 参数校验
    if (!self->VehicleVin || self->VehicleVin.length == 0) {
        NSError *error = [NSError errorWithDomain:@"TCUConnectionError"
                                             code:1001
                                         userInfo:@{NSLocalizedDescriptionKey: @"VIN为空"}];
        if (completion) completion(NO, nil, error);
        return;
    }
    
    if (!self->VehicleSvt || self->VehicleSvt.count == 0) {
        NSError *error = [NSError errorWithDomain:@"TCUConnectionError"
                                             code:1002
                                         userInfo:@{NSLocalizedDescriptionKey: @"SVT为空"}];
        if (completion) completion(NO, nil, error);
        return;
    }
    
    // 2. 转换SVT数组为字典 ✅ 关键修改
    NSDictionary *svtDict = [self convertSvtArrayToDictionary:self->VehicleSvt];
    
    DDLogInfo(@"[NewAPI] 准备上传车辆信息: VIN=%@, SVT=%@", self->VehicleVin, svtDict);
    
    // 3. 转换CAFD数组为字典（如果有）
    NSDictionary *cafdDict = @{};
    if (cafdArray && cafdArray.count > 0) {
        cafdDict = [self convertCafdArrayToDictionary:cafdArray];
    }
    
    // 4. 调用TCUAPIService的方法上传
    [[TCUVehicleService sharedService] uploadVehicleInfoWithVIN:self->VehicleVin
                                                        svt:svtDict
                                                       cafd:cafdDict
                                                 completion:^(BOOL success, NSString *binFileName, NSError *error) {
        
//        // 5. 处理响应
//        if (error) {
//            DDLogError(@"[NewAPI] 车辆信息上传失败: %@", error.localizedDescription);
//            
//            NSString *errorMessage = error.localizedDescription;
//            if (error.code == TCUErrorCodeSSLError) {
//                errorMessage = @"SSL证书未配置";
//            } else if (error.code == TCUErrorCodeNetworkError) {
//                errorMessage = @"网络连接失败，请检查网络";
//            }
//            
//            dispatch_async(dispatch_get_main_queue(), ^{
//                [self PrintInformationToDisplayLog:error_prefix :errorMessage];
//            });
//            
//            if (completion) completion(NO, nil, error);
//            return;
//        }
//        
//        if (success) {
//            DDLogInfo(@"[NewAPI] 车辆信息上传成功, BinFileName: %@", binFileName);
//            
//            dispatch_async(dispatch_get_main_queue(), ^{
//                [self PrintInformationToDisplayLog:info_prefix :@"车辆信息上传成功"];
//            });
//            
//            if (completion) completion(YES, binFileName, nil);
//        } else {
//            DDLogError(@"[NewAPI] API返回失败");
//            
//            dispatch_async(dispatch_get_main_queue(), ^{
//                [self PrintInformationToDisplayLog:error_prefix :@"服务器返回失败"];
//            });
//            
//            NSError *apiError = [NSError errorWithDomain:@"TCUAPIError"
//                                                    code:1003
//                                                userInfo:@{NSLocalizedDescriptionKey: @"服务器返回失败"}];
//            if (completion) completion(NO, nil, apiError);
//        }
    }];
}
#pragma mark - 检查激活状态

/**
 * 检查本地是否有License，判断是否需要激活
 */
- (void)checkActivationStatus {
    
    // 从KeyChain读取License
    NSDictionary *keyDic = [KeyChainProcess getFromKeychainForKey:@"License"];
    NSString *localLicense = keyDic[self->VehicleVin];
    
    if (localLicense && localLicense.length > 0) {
        // 本地有License，不需要激活
        DDLogInfo(@"[NewAPI] 本地已有License: %@", localLicense);
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [self PrintInformationToDisplayLog:info_prefix :@"车辆已激活"];
            
            // TODO: 可选 - 调用API验证License是否仍然有效
            // [self validateLicenseWithServer:localLicense];
            
            // 启用下一步按钮
            [self handleActivatedState];
        });
        
    } else {
        // 本地没有License，需要激活
        DDLogInfo(@"[NewAPI] 本地无License，需要激活");
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [self PrintInformationToDisplayLog:info_prefix :CAR_NOT_REGISTER_CONTENT];
            
            // 启用激活按钮
            [self handleNeedActivationState];
        });
    }
}
#pragma mark - 检查车辆是否支持

/**
 * 根据BinFileName判断车辆是否支持
 * @param binFileName 从API返回的BinFileName
 * @return YES=支持, NO=不支持
 */
- (BOOL)checkVehicleSupportWithBinFileName:(NSString *)binFileName {
    
    // 判断逻辑：
    // 1. binFileName为nil -> 不支持
    // 2. binFileName为空字符串 -> 不支持
    // 3. binFileName有值 -> 支持
    
    if (!binFileName || binFileName.length == 0) {
        DDLogInfo(@"[NewAPI] 车辆不支持: BinFileName为空");
        return NO;
    }
    
    DDLogInfo(@"[NewAPI] 车辆支持: BinFileName=%@", binFileName);
    
    // 保存binFileName供后续使用
    self->binaryName = binFileName;
    
    return YES;
}

#pragma mark - 辅助方法

/**
 * 将SVT数组转换为字符串格式
 * 格式示例: "SWFL_xxx,BTLD_yyy,HWEL_zzz"
 */
- (NSString *)convertSvtArrayToString:(NSArray *)svtArray {
    if (!svtArray || svtArray.count == 0) {
        return @"";
    }
    
    NSMutableArray *svtStrings = [NSMutableArray array];
    
    for (id item in svtArray) {
        if ([item isKindOfClass:[NSString class]]) {
            [svtStrings addObject:item];
        } else if ([item isKindOfClass:[NSDictionary class]]) {
            // 如果SVT是字典格式，需要提取关键字段
            NSDictionary *dict = (NSDictionary *)item;
            NSString *svtString = dict[@"svt"] ?: @"";
            if (svtString.length > 0) {
                [svtStrings addObject:svtString];
            }
        }
    }
    
    return [svtStrings componentsJoinedByString:@","];
}

/**
 * 将SVT数组转换为字典格式
 *
 * 输入示例: @[@"SWFL_00001234_002_156_007", @"BTLD_00005678_003_200_001", @"HWEL_000022AE"]
 * 输出示例: @{
 *     @"SWFL": @"SWFL_00001234_002_156_007",
 *     @"BTLD": @"BTLD_00005678_003_200_001",
 *     @"HWEL": @"HWEL_000022AE"
 * }
 */
- (NSDictionary *)convertSvtArrayToDictionary:(NSArray *)svtArray {
    if (!svtArray || svtArray.count == 0) {
        return @{};
    }
    
    NSMutableDictionary *svtDict = [NSMutableDictionary dictionary];
    NSMutableDictionary *keyCounters = [NSMutableDictionary dictionary];  // 记录每个key出现的次数
    
    for (id item in svtArray) {
        NSString *svtString = nil;
        
        if ([item isKindOfClass:[NSString class]]) {
            svtString = (NSString *)item;
        } else if ([item isKindOfClass:[NSDictionary class]]) {
            NSDictionary *dict = (NSDictionary *)item;
            svtString = dict[@"value"] ?: dict[@"svt"] ?: @"";
        }
        
        if (svtString && svtString.length > 0) {
            // 提取key和value
            // "SWFL_00001234_002_156_007" -> key="SWFL", value="00001234_002_156_007"
            NSArray *components = [svtString componentsSeparatedByString:@"_"];
            if (components.count > 1) {
                NSString *baseKey = components[0];  // "SWFL", "BTLD", "HWEL", "CAFD" 等
                
                // value是去掉第一个前缀后的部分
                NSMutableArray *valueComponents = [components mutableCopy];
                [valueComponents removeObjectAtIndex:0];  // 移除 "SWFL"
                NSString *value = [valueComponents componentsJoinedByString:@"_"];  // "00001234_002_156_007"
                
                // 检查这个key是否已经存在
                NSInteger count = [keyCounters[baseKey] integerValue];
                
                NSString *finalKey;
                if (count == 0) {
                    // 第一次出现，使用原始key
                    finalKey = baseKey;  // "SWFL"
                    keyCounters[baseKey] = @(1);
                } else {
                    // 第N次出现，使用带序号的key
                    finalKey = [NSString stringWithFormat:@"%@%ld", baseKey, (long)(count + 1)];  // "SWFL2", "SWFL3"...
                    keyCounters[baseKey] = @(count + 1);
                }
                
                svtDict[finalKey] = value;  // 去掉前缀的值
            }
        }
    }
    
    return [svtDict copy];
}

#pragma mark - 辅助方法（用于排序）

/**
 * 从key中提取前缀
 * "SWFL" -> "SWFL"
 * "SWFL2" -> "SWFL"
 * "BTLD3" -> "BTLD"
 */
- (NSString *)extractPrefix:(NSString *)key {
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"^([A-Z]+)"
                                                                            options:0
                                                                              error:nil];
    NSTextCheckingResult *match = [regex firstMatchInString:key
                                                    options:0
                                                      range:NSMakeRange(0, key.length)];
    
    if (match && match.range.location != NSNotFound) {
        return [key substringWithRange:match.range];
    }
    
    return key;
}

/**
 * 从key中提取序号
 * "SWFL" -> 0
 * "SWFL2" -> 2
 * "BTLD3" -> 3
 */
- (NSInteger)extractNumber:(NSString *)key {
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"(\\d+)$"
                                                                            options:0
                                                                              error:nil];
    NSTextCheckingResult *match = [regex firstMatchInString:key
                                                    options:0
                                                      range:NSMakeRange(0, key.length)];
    
    if (match && match.range.location != NSNotFound) {
        NSString *numberString = [key substringWithRange:match.range];
        return [numberString integerValue];
    }
    
    return 0;  // 没有序号，返回0（表示第一个）
}

/**
 * 将CAFD数组转换为字典格式
 *
 * 输入示例: @[@"CAFD_12345678_001_100_050", @"CAFD_FFFFFFFF_255_255_255"]
 * 输出示例: @{
 *     @"CAFD": @"CAFD_12345678_001_100_050"
 * }
 */
- (NSDictionary *)convertCafdArrayToDictionary:(NSArray *)cafdArray {
    if (!cafdArray || cafdArray.count == 0) {
        return @{};
    }
    
    NSMutableDictionary *cafdDict = [NSMutableDictionary dictionary];
    
    for (NSInteger i = 0; i < cafdArray.count; i++) {
        id item = cafdArray[i];
        NSString *cafdString = nil;
        
        if ([item isKindOfClass:[NSString class]]) {
            cafdString = (NSString *)item;
        } else if ([item isKindOfClass:[NSDictionary class]]) {
            NSDictionary *dict = (NSDictionary *)item;
            cafdString = dict[@"value"] ?: dict[@"cafd"] ?: @"";
        }
        
        if (cafdString && cafdString.length > 0) {
            // key格式: cafd1, cafd2, cafd3...
            NSString *key = [NSString stringWithFormat:@"cafd%ld", (long)(i + 1)];
            cafdDict[key] = cafdString;
        }
    }
    
    DDLogInfo(@"[NewAPI] CAFD转换: %ld项 -> %@", (long)cafdArray.count, cafdDict);
    
    return [cafdDict copy];
}
#pragma mark - 处理激活状态

/**
 * 处理已激活状态
 */
- (void)handleActivatedState {
    dispatch_async(dispatch_get_main_queue(), ^{
        // 禁用激活按钮
        self.activationButton.enabled = NO;
        
        // 启用下一步按钮
        self.nextButton.enabled = YES;
        
        // TODO: 可选 - 检查是否有新的Bin文件更新
        // [self CheckBinFile];
    });
}

/**
 * 处理需要激活状态
 */
- (void)handleNeedActivationState {
    dispatch_async(dispatch_get_main_queue(), ^{
        // 启用激活按钮
        self.activationButton.enabled = YES;
        
        // 禁用下一步按钮
        self.nextButton.enabled = NO;
    });
}


-(UIRectEdge)preferredScreenEdgesDeferringSystemGestures{
    return UIRectEdgeBottom;
}

-(void)InitInstallView{
    self->installView = [[EcuInstallView alloc] init];
    self->installView = [[NSBundle mainBundle] loadNibNamed:@"EcuInstallView" owner:self->installView options:nil][0];
    self->installView.frame = CGRectMake(0, 0, 325, 240);
    self->installView.center = CGPointMake([UIScreen mainScreen].bounds.size.width / 2, [UIScreen mainScreen].bounds.size.height / 2);
    self->bgView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height)];
    self->bgView.backgroundColor = [UIColor blackColor];
    self->bgView.alpha = 0.6;
}

-(void)AddInstallVIewToWindow{
    if([[UIDevice currentDevice].systemVersion floatValue] >= 15.0){
        NSSet<UIWindowScene *> *scenes =  [[UIApplication sharedApplication] connectedScenes];
        UIWindowScene * scene = [scenes allObjects].firstObject;
        [scene.keyWindow addSubview:self->bgView];
        [scene.keyWindow addSubview:self->installView];
        [self->installView initViewState];
        [self->installView beginLogoAnimation];
        [self->installView setNormalDescription];
    }else{
        
        UIWindow * window = [UIApplication sharedApplication].keyWindow;
        [window addSubview:self->bgView];
        [window addSubview:self->installView];
        [self->installView initViewState];
        [self->installView beginLogoAnimation];
        [self->installView setNormalDescription];
    }
}

-(void)addAllNotification{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(begininstallPackageNotify:) name:begin_start_install_notify_name object:nil];
    
}

-(void)begininstallPackageNotify:(NSNotification *)notify {
    ProcessCount = 0;
    AfterProcessPath = notify.userInfo[@"path"];
    self->LastflashFileName = [AfterProcessPath lastPathComponent];
    DDLogInfo(@"Handle File : %@" ,self->LastflashFileName);
    [self AddInstallVIewToWindow];
    
    NSDateFormatter * format = [[NSDateFormatter alloc] init];
    format.dateFormat = date_format;
    NSString * date_string = [format stringFromDate:[NSDate date]];
    
    NSString *viewString = [NSString stringWithFormat:@"Start flashing:  %@",date_string];
    [self PrintInformationToDisplayLog:info_prefix :viewString];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        if([self->LastflashFileName isEqual:@"ZD8 Recovery Tool"])
        {
            [self.AutoNetworkManager performRecoveryCafd:self->VehicleVin :self->VehicleSvt delegate:self];
        }
        else
        {
            [self.AutoNetworkManager performCarECUFlash:[self->AfterProcessPath stringByAppendingFormat:@"/%@",TUNE_BIN] :self->VehicleVin :self->VehicleSvt delegate:self];
        }
            
    });
}


-(void)RetryFlashProcess{
    self->LastflashFileName = [AfterProcessPath lastPathComponent];
    DDLogInfo(@"Handle File : %@" ,self->LastflashFileName);
    [self AddInstallVIewToWindow];
    
    NSDateFormatter * format = [[NSDateFormatter alloc] init];
    format.dateFormat = date_format;
    NSString * date_string = [format stringFromDate:[NSDate date]];
    
    NSString *viewString = [NSString stringWithFormat:@"Start flashing:  %@",date_string];
    [self PrintInformationToDisplayLog:info_prefix :viewString];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        if([self->LastflashFileName isEqual:@"ZD8 Recovery Tool"])
        {
            [self.AutoNetworkManager performRecoveryCafd:self->VehicleVin :self->VehicleSvt delegate:self];
        }
        else
        {
            [self.AutoNetworkManager performCarECUFlash:[self->AfterProcessPath stringByAppendingFormat:@"/%@",TUNE_BIN] :self->VehicleVin :self->VehicleSvt delegate:self];
        }
            
    });
}

-(void)RecoverCafdProcess{
    DDLogInfo(@"Server Recover Cafd");
    [self AddInstallVIewToWindow];
    NSDateFormatter * format = [[NSDateFormatter alloc] init];
    format.dateFormat = date_format;
    NSString * date_string = [format stringFromDate:[NSDate date]];
    
    NSString *viewString = [NSString stringWithFormat:@"Start flashing:  %@",date_string];
    [self PrintInformationToDisplayLog:info_prefix :viewString];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{

        [self.AutoNetworkManager ServerRecoveryCafd:self->VehicleVin :self->VehicleSvt :self->LoadCafd delegate:self];
    });
    
}

-(void)didUpdateProgress:(NSString *)StepName Info:(NSString *)info
{
    ProcessCount++;
    dispatch_async(dispatch_get_main_queue(), ^{
        if(self->FlashpreparatoryDict[StepName])
        {
            [self->installView initViewState];
        }
        else if(self->FlashPersentDict[StepName])
        {
            [self->installView setCurrentPackageInstallCount];
        }
        else if(self->FlashFinishDict[StepName])
        {
            [self->installView setEcuFileDoneInstall];
        }
    });
}
-(void)didEncounterError:(NSString *)StepName ErrorInfo:(NSString *)info ErrorData:(NSData *)errorData ErrorFID:(uint8_t)FID
{
    __block uint32_t ErrorCode;
    ProcessCount++;
    DDLogInfo(@"%@ Error info: %@",StepName ,info);
    if([info isEqual: OperationTimeOut])
    {
        ErrorCode = (uint32_t)(((uint32_t)self->ProcessCount<<16) + (FID << 8)+ ProcessErrorTypeTimeOut);
    }
    else
    {
        uint8_t errorCode = 0;
        [errorData getBytes:&errorCode length:1];
        ErrorCode = (uint32_t)(((uint32_t)self->ProcessCount<<16) + (FID << 8) + errorCode);
    }
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{
        UploadManager *uploadManager = [UploadManager sharedInstance];
        [uploadManager uploadFlashErrorInformation:self->LastflashFileName :StepName :[NSString stringWithFormat:@"%ld", (long)self->ProcessCount] :info :errorData :FID];
    });
    
    bool RecoverBaseState = [self CheckVersion];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [self->bgView removeFromSuperview];
        [self->installView removeFromSuperview];
        
        if(RecoverBaseState)
        {
            [self appendFlashSuccessLogToTextView:self.svtTextView
                                         fileName:self->LastflashFileName
                                       dateFormat:date_format
                                       infoPrefix:info_prefix
                                       successTag:FAIL_FLASH_FILE_TITLE];
            dispatch_async(dispatch_get_main_queue(), ^{
                [self DisplayVersionInformation:self->VehicleSvt];
            });
            [PopWindow showFlashErrorAlertWithErrorCode:@"Failed" Code:ErrorCode info:@"REBASE" secondButtonTitle:@"Re-Flash" secondButtonBlock:^(UIAlertAction *action) {
                self->ProcessCount = 0;
                
                NSString *directory = [self->AfterProcessPath stringByDeletingLastPathComponent];
                self->AfterProcessPath = [directory stringByAppendingPathComponent:@"OBD Unlock - STEP 1"];
                
                [self RetryFlashProcess];
            }];
            return;
        }
        else if([info isEqual:OperationBasicDeficiency])
        {
            [PopWindow showFlashErrorAlertWithErrorCode:@"ERROR" Code:ErrorCode info:info];
        }
        else
            [PopWindow showFlashErrorAlertWithErrorCode:@"ERROR" Code:ErrorCode info:info secondButtonTitle:@"Re-Flash" secondButtonBlock:^(UIAlertAction *action) {
                self->ProcessCount = 0;
                [self RetryFlashProcess];
            }];

        [self appendFlashSuccessLogToTextView:self.svtTextView
                                     fileName:self->LastflashFileName
                                   dateFormat:date_format
                                   infoPrefix:info_prefix
                                   successTag:FAIL_FLASH_FILE_TITLE];
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
            self->VehicleSvt = [self.AutoNetworkManager ReadVehicleSvt];
            [self CafdAndMidProcess];
            dispatch_async(dispatch_get_main_queue(), ^{
                [self DisplayVersionInformation:self->VehicleSvt];
            });
        });
    });
}
- (void)appendFlashSuccessLogToTextView:(UITextView *)textView
                               fileName:(NSString *)fileName
                             dateFormat:(NSString *)dateFormat
                             infoPrefix:(NSString *)infoPrefix
                             successTag:(NSString *)highlightText {
    dispatch_async(dispatch_get_main_queue(), ^{
    // 当前时间字符串
        NSDateFormatter *format = [[NSDateFormatter alloc] init];
        format.dateFormat = dateFormat;
        NSString *dateString = [format stringFromDate:[NSDate date]];
        
        // 拼接内容
        NSString *content = [NSString stringWithFormat:@"\r\n%@%@\r\n%@ %@\r\n",
                             infoPrefix,
                             dateString,
                             fileName,
                             highlightText];
        
        // 设置富文本
        textView.attributedText = [self getTextViewAttributeString:content WithAttribute:highlightText];
        
        // 滚动到底部（如果需要）
        if (textView.contentSize.height > textView.frame.size.height) {
            [textView setContentOffset:CGPointMake(0, textView.contentSize.height - textView.frame.size.height) animated:YES];
        }
    });
}
-(void)DidGetFlashAllCount:(NSInteger)Count{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self->installView setPackageTotalMount:Count];
    });
}

-(void)processSuccess{
    DDLogInfo(@"%@ Success",self->LastflashFileName);
    self->ProcessCount = 0;
    self->VehicleSvt = [self.AutoNetworkManager ReadVehicleSvt];
    dispatch_async(dispatch_get_main_queue(), ^{
        [self->bgView removeFromSuperview];
        [self->installView removeFromSuperview];
        [PopWindow showAlertWithTitle:DONE_WRITE_TCP_TITLE message:DONE_WRITE_TCP_CONTENT buttonTitle:DONE_WRITE_ALLOW_TEXT];
        [self appendFlashSuccessLogToTextView:self.svtTextView
                                     fileName:self->LastflashFileName
                                   dateFormat:date_format
                                   infoPrefix:info_prefix
                                   successTag:WRITE_DONE_SUCC_CONTENT];

        [self DisplayVersionInformation:self->VehicleSvt];
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
            UploadManager *uploadManager = [UploadManager sharedInstance];
            [uploadManager uploadFlashCellName:self->LastflashFileName :YES];
            [self CafdAndMidProcess];
        });
    });
}

-(bool)CheckVersion{
    VehicleSvt = [self.AutoNetworkManager ReadVehicleSvt];
    bool state =  [versionManager isNeedFlashBase:VehicleSvt];

    return state;
}

-(void)addNavigationView {
    NavigationView * naviView = [[NavigationView alloc] init];
    naviView = (NavigationView*)[[NSBundle mainBundle] loadNibNamed:@"NavigationView" owner:naviView options:nil][0];
    naviView.frame = CGRectMake(0, 40, [UIScreen mainScreen].bounds.size.width, 80);
    naviView.delegate = self;
    
    [self.view addSubview:naviView];
    //    UIButton * leftButton = [naviView viewWithTag:100];
    UIButton * leftButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 40, 80, 80)];
    leftButton.backgroundColor = [UIColor darkGrayColor];
    [self.view addSubview:leftButton];
    [leftButton addTarget:self action:@selector(didTapEscButton) forControlEvents:UIControlEventTouchUpInside];
    
}

-(void)LeftMenuShow{
    
    [self.view addSubview:[self leftMenu]];
    
    [UIView animateWithDuration:0.25 delay:0 options:UIViewAnimationOptionBeginFromCurrentState animations:^{
        self->leftMenu.frame = CGRectMake(0, 0, 300, [UIScreen mainScreen].bounds.size.height);
    } completion:nil];
    
    
}
-(LeftMenuView *)leftMenu{
    if(!leftMenu){
        //        leftMenu = [[LeftMenuView alloc] init];
        leftMenu = [[NSBundle mainBundle] loadNibNamed:@"LeftMenuView" owner:nil options:nil][0];
        leftMenu.frame = CGRectMake(-300, 0, 300, [UIScreen mainScreen].bounds.size.height);
        leftMenu.delegate = self;
    }
    return leftMenu;
}
+ (void)redirectNSLog {
    NSString *fileName = @"NSLog.log";
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentDirectory = paths.firstObject;
    NSString *saveFilePath = [documentDirectory stringByAppendingPathComponent:fileName];
    // 先删除已经存在的文件
    //    NSFileManager *defaultManager = [NSFileManager defaultManager];
    //    [defaultManager removeItemAtPath:saveFilePath error:nil];
    
    // 将log输入到文件
    freopen([saveFilePath cStringUsingEncoding:NSASCIIStringEncoding], "a+", stdout);
    freopen([saveFilePath cStringUsingEncoding:NSASCIIStringEncoding], "a+", stderr);
}
-(void)initStatusImage {
    self.statusimg1.hidden = YES;
    self.lineimg1.hidden = YES;
    self.lineimg2.hidden = YES;
    self.statusimg2.hidden = YES;
}
-(UIView *)carView{
    
    if(!_carView){
        CGRect frame = self.statusimg1.bounds;
        _carView = [[UIView alloc] initWithFrame:frame];
        _carView.backgroundColor = [UIColor blackColor];
    }
    return _carView;
}
-(UIView *)lineView1{
    
    if(!_lineView1){
        CGRect frame = self.lineimg1.bounds;
        _lineView1 = [[UIView alloc] initWithFrame:frame];
        _lineView1.backgroundColor = [UIColor blackColor];
    }
    return _lineView1;
}
-(UIView *)lineView2{
    if(!_lineView2){
        CGRect frame = self.lineimg2.bounds;
        _lineView2 = [[UIView alloc] initWithFrame:frame];
        _lineView2.backgroundColor = [UIColor blackColor];
    }
    return _lineView2;
}
-(UIView *)internetView{
    
    if(!_internetView){
        CGRect frame = self.statusimg2.bounds;
        _internetView = [[UIView alloc] initWithFrame:frame];
        _internetView.backgroundColor = [UIColor blackColor];
    }
    return _internetView;
}
-(void)startNetworkAnimation {
    [[HttpClient alloc] sendGetWithUrl:Connect_Internet doneBlock:^(id data){
        [self startCarAnimation];
        // 要在汽车动画结束后延迟0.5s再执行
        [self performSelector:@selector(startInternetAnimation) withObject:nil afterDelay:0.5];
    } errBlock:^(NSError * error){
        [self startCarAnimation];
    }];
}
-(void)startCarAnimation {
    
    
    [self.statusimg1 addSubview:self.carView];
    [self.lineimg1 addSubview:self.lineView1];
    
    __block CGRect frame = CGRectMake(self.statusimg1.frame.size.width, 0, 0, self.statusimg1.frame.size.height);
    __block CGRect frame1 = CGRectMake(self.lineimg1.frame.size.width, 0, 0, self.lineimg1.frame.size.height);
    
    self.carView.frame = frame;
    self.lineView1.frame = frame1;
    
    CGFloat width_line1 = self.lineimg1.frame.size.width;
    
    self.statusimg1.maskView = self.carView;
    self.lineimg1.maskView = self.lineView1;
    
    self.statusimg1.hidden = NO;
    self.lineimg1.hidden = NO;
    
    //设置时间间隔
    NSTimeInterval period = 0.005f;
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    animation_t_car = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, queue);
    
    // 第一次不会立刻执行，会等到间隔时间后再执行
    //    dispatch_time_t start = dispatch_time(DISPATCH_TIME_NOW, period * NSEC_PER_SEC);
    //    dispatch_source_set_timer(_timer, start, period * NSEC_PER_SEC, 0);
    // NSLog(@"---------> middle lineimg1.frame.size.width: %f",self.lineimg1.frame.size.width);
    // 第一次会立刻执行，然后再间隔执行
    dispatch_source_set_timer(animation_t_car, dispatch_walltime(NULL, 0), period * NSEC_PER_SEC, 0);
    // 事件回调
    dispatch_source_set_event_handler(animation_t_car, ^{
        dispatch_async(dispatch_get_main_queue(), ^{
            frame1 = CGRectMake(frame1.origin.x-1, 0, frame1.size.width + 1, frame1.size.height);
            if(frame1.size.width >= width_line1){
                frame = CGRectMake(frame.origin.x-1, 0, frame.size.width + 1, frame.size.height);
                if(frame.size.width >= self.statusimg1.frame.size.width){
                    if(self->animation_t_car){
                        dispatch_source_cancel(self->animation_t_car);
                        self->animation_t_car = nil;
                    }
                }else{
                    self.carView.frame = frame;
                }
            }else{
                self.lineView1.frame = frame1;
            }
            
        });
    });
    
    // 开启定时器
    if (animation_t_car) {
        dispatch_resume(animation_t_car);
    }
    
    // [[NSRunLoop currentRunLoop] addTimer:nil forMode:NSRunLoopCommonModes];
    [[NSRunLoop currentRunLoop] addPort:[NSPort port] forMode:NSDefaultRunLoopMode];
    //    [[NSRunLoop currentRunLoop] run];
}
-(void)startInternetAnimation {
    
    [self.statusimg2 addSubview:self.internetView];
    [self.lineimg2 addSubview:self.lineView2];
    
    __block CGRect frame = CGRectMake(0, 0, 0, self.lineimg2.frame.size.height);
    __block CGRect frame1 = CGRectMake(0, 0, 0, self.statusimg2.frame.size.height);
    
    self.internetView.frame = frame;
    self.lineView2.frame = frame1;
    
    
    self.statusimg2.maskView = self.internetView;
    self.lineimg2.maskView = self.lineView2;
    
    self.statusimg2.hidden = NO;
    self.lineimg2.hidden = NO;
    
    //设置时间间隔
    NSTimeInterval period = 0.005f;
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    animation_t_internet = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, queue);
    
    // 第一次不会立刻执行，会等到间隔时间后再执行
    //    dispatch_time_t start = dispatch_time(DISPATCH_TIME_NOW, period * NSEC_PER_SEC);
    //    dispatch_source_set_timer(_timer, start, period * NSEC_PER_SEC, 0);
    
    // 第一次会立刻执行，然后再间隔执行
    dispatch_source_set_timer(animation_t_internet, dispatch_walltime(NULL, 0), period * NSEC_PER_SEC, 0);
    // 事件回调
    dispatch_source_set_event_handler(animation_t_internet, ^{
        dispatch_async(dispatch_get_main_queue(), ^{
            frame = CGRectMake(0, 0, frame.size.width + 1, frame.size.height);
            if(frame.size.width >= self.lineimg2.frame.size.width){
                frame1 = CGRectMake(0, 0, frame1.size.width + 1, frame1.size.height);
                if(frame1.size.width >= self.statusimg2.frame.size.width){
                    if(self->animation_t_internet){
                        dispatch_source_cancel(self->animation_t_internet);
                        self->animation_t_internet = nil;
                    }
                }else{
                    self.internetView.frame = frame1;
                }
                
            }else{
                self.lineView2.frame = frame;
            }
            
        });
    });
    
    // 开启定时器
    if (animation_t_internet) {
        dispatch_resume(animation_t_internet);
    }
    [[NSRunLoop currentRunLoop] addPort:[NSPort port] forMode:NSDefaultRunLoopMode];
    //    [[NSRunLoop currentRunLoop] run];
}
#pragma mark 左滑视图代理方法
-(void)didTapCloseButton{
    [self->leftMenu removeFromSuperview];
    
}
-(void)didTapHomeButton{
    
}
-(void)didTapSpeedButton{
    
    [[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"videoexport"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    UIStoryboard * storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    SpeedTestViewController * speedViewController = [storyboard instantiateViewControllerWithIdentifier:@"SpeedTestViewController"];
    [self.navigationController pushViewController:speedViewController animated:YES];
}

-(void)addDisconnectNotify:(NSNotification *)notify {
    
    dispatch_async(dispatch_get_main_queue(), ^{
        
        [self->leftMenu removeFromSuperview];
        
    });
    
}



-(NSMutableAttributedString *)getTextViewAttributeString:(NSString *)mutableString WithAttribute:(NSString *)attriString{
    NSMutableAttributedString * muString = [[NSMutableAttributedString alloc] initWithAttributedString:self.svtTextView.attributedText];
    
    NSMutableAttributedString * mutableattribueString = [[NSMutableAttributedString alloc] initWithString:mutableString];
    [mutableattribueString addAttributes:@{NSForegroundColorAttributeName:[UIColor whiteColor],NSFontAttributeName:[UIFont systemFontOfSize:14]} range:NSMakeRange(0, mutableString.length)];
    if(attriString && attriString.length > 0){
        NSRange range = [mutableString rangeOfString:attriString];
        if(range.location != NSNotFound){
            if([attriString isEqualToString:WRITE_DONE_SUCC_CONTENT]){
                [mutableattribueString addAttributes:@{NSForegroundColorAttributeName:[UIColor greenColor]} range:range];
            }else{
                [mutableattribueString addAttributes:@{NSForegroundColorAttributeName:[UIColor redColor]} range:range];
            }
        }
    }
    
    [muString appendAttributedString:mutableattribueString];
    
    return muString;
}
-(BOOL)checkEcuSupport:(NSArray *)SvtArray {
    BOOL isexist = false;
    BOOL is5F6D_5F6E = false;
    BOOL isc7c = false;
    BOOL iscafd_255 = false;
    NSString * string_c7c = @"BTLD_00000C7C_012_058_000";
    NSArray * ecuarrays = @[@"00000C7C",@"00001DC6",@"0000280C",@"00001F6C",@"00005F6D",@"00005F6E",@"0000280D"];
    for (NSString * btldValue in SvtArray) {
        if([btldValue hasPrefix:btld_prefix]){
            for (NSString * ecuitem in ecuarrays) {
                NSString * ecuPrefix = [NSString stringWithFormat:@"%@_%@",btld_prefix,ecuitem];
                if([btldValue hasPrefix:ecuPrefix]){
                    if([ecuitem isEqualToString:@"00005F6D"] || [ecuitem isEqualToString:@"00005F6E"]){
                        is5F6D_5F6E = true;
                    }
                    isexist = true;
                }
            }
            if([btldValue isEqualToString:string_c7c]){
                isc7c = true;
            }
        }
        if([btldValue isEqualToString:CAFD_FFFF]){
            iscafd_255 = true;
        }
    }
    // 如果不支持的话，直接返回，不继续操作
    if(isexist == false){
        dispatch_async(dispatch_get_main_queue(), ^{
            NSDateFormatter * format = [[NSDateFormatter alloc] init];
            format.dateFormat = date_format;
            NSString * date_string = [format stringFromDate:[NSDate date]];
            NSString * content =  [NSString stringWithFormat:@"\r\n%@%@\r\n%@\r\n",info_prefix,date_string,ECU_UNSUPPORTED];
            self.svtTextView.attributedText = [self getTextViewAttributeString:content WithAttribute:@""];
            if(self.svtTextView.contentSize.height > self.svtTextView.frame.size.height){
                [self.svtTextView setContentOffset:CGPointMake(0, self.svtTextView.contentSize.height - self.svtTextView.frame.size.height) animated:YES];
            }
            
        });
        return false;
    }
    
    if(is5F6D_5F6E == true){
        
        dispatch_async(dispatch_get_main_queue(), ^{
            NSDateFormatter * format = [[NSDateFormatter alloc] init];
            format.dateFormat = date_format;
            NSString * date_string = [format stringFromDate:[NSDate date]];
            NSString * content = [NSString stringWithFormat:@"\r\n%@%@\r\n%@\r\n",info_prefix,date_string,TCU_UNLOCK_CONTENT];
            self.svtTextView.attributedText = [self getTextViewAttributeString:content WithAttribute:@"Unlock"];
            if(self.svtTextView.contentSize.height > self.svtTextView.frame.size.height){
                [self.svtTextView setContentOffset:CGPointMake(0, self.svtTextView.contentSize.height - self.svtTextView.frame.size.height) animated:YES];
            }
            
        });
    }
    if(isc7c == true){
        dispatch_async(dispatch_get_main_queue(), ^{
            NSDateFormatter * format = [[NSDateFormatter alloc] init];
            format.dateFormat = date_format;
            NSString * date_string = [format stringFromDate:[NSDate date]];
            //            self.svtTextView.text = [NSString stringWithFormat:@"%@\r\n%@%@\r\n%@\r\n",self.svtTextView.text,info_prefix,date_string,TCU_UNLOCK_CONTENT];
            NSString * content = [NSString stringWithFormat:@"\r\n%@%@\r\n%@\r\n",info_prefix,date_string,TCU_UPGRADE_CONTENT];
            self.svtTextView.attributedText = [self getTextViewAttributeString:content WithAttribute:@""];
            if(self.svtTextView.contentSize.height > self.svtTextView.frame.size.height){
                [self.svtTextView setContentOffset:CGPointMake(0, self.svtTextView.contentSize.height - self.svtTextView.frame.size.height) animated:YES];
            }
            
        });
    }
    if(iscafd_255 == true){
        dispatch_async(dispatch_get_main_queue(), ^{
            NSDateFormatter * format = [[NSDateFormatter alloc] init];
            format.dateFormat = date_format;
            NSString * date_string = [format stringFromDate:[NSDate date]];
            //            self.svtTextView.text = [NSString stringWithFormat:@"%@\r\n%@%@\r\n%@\r\n",self.svtTextView.text,info_prefix,date_string,CAFD_FILE_NOT_CORRECT];
            NSString * content = [NSString stringWithFormat:@"\r\n%@%@\r\n%@\r\n",info_prefix,date_string,CAFD_FILE_NOT_CORRECT];
            self.svtTextView.attributedText = [self getTextViewAttributeString:content WithAttribute:@""];
            if(self.svtTextView.contentSize.height > self.svtTextView.frame.size.height){
                [self.svtTextView setContentOffset:CGPointMake(0, self.svtTextView.contentSize.height - self.svtTextView.frame.size.height) animated:YES];
            }
            
        });
    }
    return isexist;
}


-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];

}
-(void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:animated];

}

-(void)InitVehicleNetwork{
    self.AutoNetworkManager = [AutoNetworkService sharedInstance];
    self->VehicleVin = [self.AutoNetworkManager ReadSaveVIN];
    DDLogInfo(@"VIN: %@",self->VehicleVin);
    dispatch_async(dispatch_get_main_queue(), ^{
        self.vinLabel.text = [NSString stringWithFormat:@"VIN: %@",self->VehicleVin];
    });
    self->VehicleSvt = [self.AutoNetworkManager ReadVehicleSvt];
    [self DisplayVersionInformation:self->VehicleSvt];
    serotype = [self getSeroTypeOnlyCheck];
    NSLog(@"sero:%d",serotype);
    DDLogInfo(@"sero : %d",serotype);
    [self.AutoNetworkManager SetVehicleClass:serotype];
    if(serotype!=4)
    {
        cafdArray = [self.AutoNetworkManager ReadCafd:serotype];
    }
}

-(void)CafdAndMidProcess {
    serotype = [self getSeroTypeOnlyCheck];
    NSLog(@"sero:%d",serotype);
    DDLogInfo(@"sero : %d",serotype);
    [self.AutoNetworkManager SetVehicleClass:serotype];
    NSArray *CafdArray;
    if(serotype!=4)
    {
        CafdArray = [self.AutoNetworkManager ReadCafd:serotype];
    }
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        UploadManager *uploadManager = [UploadManager sharedInstance];
        [uploadManager firstECUVersionUpload:self->VehicleVin SvtInfo:self->VehicleSvt CafdInfo:CafdArray];
        [uploadManager CheckAndCreateLogFolder:self->VehicleVin];
        DDFileLogger *fileLogger = [[DDFileLogger alloc] init];
        NSArray<NSString *> *logFilePaths = [fileLogger.logFileManager sortedLogFilePaths];
        NSString *zipFilePath = [NSTemporaryDirectory() stringByAppendingPathComponent:@"logs.zip"];
        // 压缩日志文件
        [SSZipArchive createZipFileAtPath:zipFilePath withFilesAtPaths:logFilePaths];
        [uploadManager uploadLogFile:zipFilePath];
    });
}

-(void)checkLicenseAndSetButton{
    NSDictionary *keyDic = [KeyChainProcess getFromKeychainForKey:@"License"];
    if (keyDic[VehicleVin])//本地有车架号，说明此车激活过本车
    {
        LicenseKeyManager *LicenseManager = [[LicenseKeyManager alloc] init];
        int CheckServer =   [LicenseManager checkVehicleActivationStatusWithVIN:VehicleVin];
        if(CheckServer == 1)//已激活
        {
            [self CheckBinFile];
        }
        else
        {
            dispatch_async(dispatch_get_main_queue(), ^{
                if(CheckServer == 2)
                    [self PrintInformationToDisplayLog:info_prefix :CAR_RECONDITIONING_CONTENT];
                else
                    [self PrintInformationToDisplayLog:info_prefix :CAR_NOT_REGISTER_CONTENT];
                self.activationButton.enabled = YES;
            });
        }
    }
    else
    {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self PrintInformationToDisplayLog:info_prefix :CAR_NOT_REGISTER_CONTENT];
            self.activationButton.enabled = YES;
        });
    }

}

-(void)CheckBinFile{
    NetworkInterface * interface = [NetworkInterface getInterface];
    [interface getUpdateBinFile:VehicleVin requestBlock:^(NSString *result) {
        UploadManager *uploadManager = [UploadManager sharedInstance];
        if(![result isEqual:@""])
        {
            [uploadManager SetBinStateAndFileName:@"1" :result];
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                [uploadManager uploadMidFile];
            });
        }

        MidSetBin *SetState = [uploadManager CheckWhetherSetBIN];
        if(SetState.status == ResponseXmlMidNeedSetFile)
        {
            self->binaryName = SetState.BINName;
            [self ButtonSet:YES];
        }
        else
        {
            NSPredicate *predicate = [NSPredicate predicateWithFormat:@"SELF CONTAINS %@", @"UNKW"];
            NSArray *filteredArray = [self->VehicleSvt filteredArrayUsingPredicate:predicate];
            if(filteredArray.count > 0){
                self->binaryName= [uploadManager CheckFirstDownloadBinFile];
                if(self->binaryName == nil)
                {
                    [self PrintInformationToDisplayLog:info_prefix :@"File write error. Please contact customer support."];
                }
                else
                {
                    [self ButtonSet:YES];
                }
            }
            else
            {
                BINFileProcess *BinFileHandle = [[BINFileProcess alloc] init];
                [BinFileHandle loadBinaryFile:self->VehicleVin :self->VehicleSvt :^(NSString * binaryFileName){
                    NSLog(@"binFile name :%@",binaryFileName);
                    self->binaryName = binaryFileName;
                    if([binaryFileName isEqual:@""])
                    {
                        [self PrintInformationToDisplayLog:info_prefix :@"File write error. Please contact customer support."];
                    }
                    else
                    {
                        [BinFileHandle RegisterVinAndBINNameToServer:self->VehicleVin BinName:self->binaryName];
                        [self ButtonSet:YES];
                    }
                }withErrorBlock:^(NSError * error){
                }];
            }
        }
        
    }
    withError:^(NSError *error) {
        // 错误时回调
        NSLog(@"发生错误：%@", error.localizedDescription);
    }];
}

-(void)ButtonSet:(BOOL)State{
    dispatch_async(dispatch_get_main_queue(), ^{
        if(State)
        {
            self.nextButton.enabled = YES;
            self.activationButton.enabled = NO;
            [self PrintInformationToDisplayLog:info_prefix :CONTINUE_TUNING];
        }
        else
        {
            self.nextButton.enabled = NO;
            self.activationButton.enabled = YES;
        }
    });
}

-(void)DisplayCheckVehicleStatus{
    [self PrintInformationToDisplayLog:info_prefix :READ_DATA_FROM_REMOTE_CONTENT];
    [self PrintInformationToDisplayLog:info_prefix :WAIT_SERVER_DATA_CONTENT];
}

-(void)PrintInformationToDisplayLog:(NSString *)prefix :(NSString *)Conten{
    dispatch_async(dispatch_get_main_queue(), ^{
        NSDateFormatter * format = [[NSDateFormatter alloc] init];
        format.dateFormat = date_format;
        NSString * date_string = [format stringFromDate:[NSDate date]];
        NSString * content  = [NSString stringWithFormat:@"\r\n%@%@\r\n%@\r\n",prefix,date_string,Conten];
        self.svtTextView.attributedText = [self getTextViewAttributeString:content WithAttribute:@""];
        if(self.svtTextView.contentSize.height > self.svtTextView.frame.size.height){
            [self.svtTextView setContentOffset:CGPointMake(0, self.svtTextView.contentSize.height - self.svtTextView.frame.size.height) animated:YES];
        }
    });
}

-(void)DisplayVersionInformation:(NSArray *)SvtMsg{
    NSString * svtString = @"";
    NSMutableArray * svtarray = [NSMutableArray array];
    for (NSString * item in SvtMsg) {
        [svtarray addObject:item];
        svtString = [svtString stringByAppendingFormat:@"%@\n",item];
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{
        NSDateFormatter * format = [[NSDateFormatter alloc] init];
        format.dateFormat = date_format;
        NSString * date_string = [format stringFromDate:[NSDate date]];
        NSString * content = [NSString stringWithFormat:@"%@%@ \r\n%@",info_prefix,date_string,svtString];
        self.svtTextView.attributedText = [self getTextViewAttributeString:content WithAttribute:@""];
        if(self.svtTextView.contentSize.height > self.svtTextView.frame.size.height){
            [self.svtTextView setContentOffset:CGPointMake(0, self.svtTextView.contentSize.height - self.svtTextView.frame.size.height) animated:YES];
        }
        NSLog(@"svtString: %@",svtString);
    });
}

-(int)getSeroTypeOnlyCheck {
    int  serolevle = 0;
     for (NSString * item in VehicleSvt) {
         // 第一个分支
         if([item hasPrefix:HWEL_22A] || [item hasPrefix:HWEL_22B]){
             serolevle = 1;
             // 第二个分支
         }else if([item hasPrefix:HWEL_BBD]){
             serolevle = 2;
             // 第三个分支
         }else if([item hasPrefix:HWEL_22AE]){
             serolevle = 3;
             // 第四个分支
         }else if([item hasPrefix:HWEL_1F6A]){
             serolevle = 4;
             // 分五个分支
         }else if([item hasPrefix:HWEL_4326] || [item hasPrefix:HWEL_435F] || [item hasPrefix:BTLD_5F6D] || [item hasPrefix:BTLD_5F6E]){
             serolevle = 5;
             // 第六个分支
         }else if ([item hasPrefix:HWEL_22E9]){
             serolevle = 6;
         }
     }
     return serolevle;
}

-(void)tapViewTarget {
    if(self->activationView){
        for (UIView * view in self->activationView.subviews) {
            if([view isKindOfClass:[UITextField class]]){
                [view resignFirstResponder];
            }
        }
    }
    
}
#pragma mark 激活按钮和下一步按钮响应事件
- (IBAction)activationButtonTarget:(id)sender {
    
    self->bgView = [[UIView alloc] initWithFrame:[UIScreen mainScreen].bounds];
    self->bgView.backgroundColor = [UIColor blackColor];
    self->bgView.alpha = 0.6;
    [self.view addSubview:self->bgView];
    UITapGestureRecognizer * dismissTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(dismissActivityView)];
    [self->bgView addGestureRecognizer:dismissTap];
    
    if(self->activationView == nil){
        self->activationView = [[ActivationView alloc] init];
        
        self->activationView = (ActivationView *)[[NSBundle mainBundle] loadNibNamed:@"ActivationView" owner:self->activationView options:nil][0];
        self->activationView.frame = CGRectMake(0, [UIScreen mainScreen].bounds.size.height, [UIScreen mainScreen].bounds.size.width, 360);
        infoTextView = [self->activationView viewWithTag:1000];
        validButton = [self->activationView viewWithTag:10];
        textField = [self->activationView viewWithTag:100];
        NSString *holderText = @"Enter Active Key Here";
        NSMutableAttributedString *placeholder = [[NSMutableAttributedString alloc]initWithString:holderText];
        [placeholder addAttribute:NSForegroundColorAttributeName
                          value:[UIColor redColor]
                          range:NSMakeRange(0, holderText.length)];
        [placeholder addAttribute:NSFontAttributeName
                          value:[UIFont systemFontOfSize:14]
                          range:NSMakeRange(0, holderText.length)];
        textField.attributedPlaceholder = placeholder;
        
        
        infoTextView.attributedText = [self getActivityAttrybuteString];
        [validButton addTarget:self action:@selector(ValidFunction) forControlEvents:UIControlEventTouchUpInside];
    }
    
    [self.view addSubview:activationView];
    
    // 重要：通知视图开始显示
    [self->activationView showView];
    
    [UIView animateWithDuration:0.25 delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        
            self->activationView.frame = CGRectMake(0, [UIScreen mainScreen].bounds.size.height - 360, [UIScreen mainScreen].bounds.size.width, 360);
        
        } completion:^(bool finish){
          
            
    }];
    
}
-(NSMutableAttributedString *)getActivityAttrybuteString {
    
    NSString * txtString = @"";
    
    txtString = [@"VIN:" stringByAppendingString:self->VehicleVin];
    txtString = [txtString stringByAppendingString:@"\r\n"];
    txtString = [txtString stringByAppendingString:@"\r\n"];
    for (NSString * item in self->svtArray) {
       NSString * item1 = [item stringByReplacingOccurrencesOfString:@" " withString:@""];
        item1 = [item1 stringByReplacingOccurrencesOfString:@"\n" withString:@""];
        item1 = [item1 stringByReplacingOccurrencesOfString:@"\r" withString:@""];
        if(item1.length <= 0)continue;
        NSRange range = [item1 rangeOfString:@"_"];
        if(range.location == NSNotFound || item1.length < range.location + range.length)continue;
        NSString * keyString = [item1 substringToIndex:range.location];
        NSString * valueString = [item1 substringFromIndex:range.location+1];
        NSString * tempString = [NSString stringWithFormat:@"%@:%@",keyString,valueString];
        
        txtString = [txtString stringByAppendingString:tempString];
        txtString = [txtString stringByAppendingString:@"\r\n"];
    }
    txtString = [txtString stringByAppendingString:@"\r\n"];
    txtString = [txtString stringByAppendingString:@"ZD8 ECU(DME):"];
    txtString = [txtString stringByAppendingString:@"Support "];
    txtString = [txtString stringByAppendingString:@"\r\n"];
    
    txtString = [txtString stringByAppendingString:@"ZD8 TCU(EGS):"];
    txtString = [txtString stringByAppendingString:@"Support  "];
    txtString = [txtString stringByAppendingString:@"\r\n"];
    
    NSMutableAttributedString * mutableString = [[NSMutableAttributedString alloc] initWithString:txtString];
    [mutableString addAttributes:@{NSForegroundColorAttributeName:[UIColor whiteColor],NSFontAttributeName:[UIFont systemFontOfSize:14]} range:NSMakeRange(0, txtString.length)];
    NSRange range = [txtString rangeOfString:@"Support "];
    [mutableString addAttributes:@{NSForegroundColorAttributeName:[UIColor greenColor]} range:range];
    
    range = [txtString rangeOfString:@"Support  "];
    [mutableString addAttributes:@{NSForegroundColorAttributeName:[UIColor greenColor]} range:range];

    
    return mutableString;
}

- (IBAction)nextButtonTarget:(id)sender {
    if(self->binaryName.length <= 0)return;

    UIStoryboard * storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    SoftwarePackageViewController * controller = [storyboard instantiateViewControllerWithIdentifier:@"SoftwarePackageViewController"];
    controller.binaryName = self->binaryName;
    controller.vinString = self->VehicleVin;
    controller.VehicleSvt = self->VehicleSvt;
    [self.navigationController pushViewController:controller  animated:YES];
}


#pragma mark 底部弹出的激活视图
-(void)ValidFunction{
    NSString * code = [textField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    NetworkInterface * interface = [NetworkInterface getInterface];
    [interface ValidWithVin:self->VehicleVin Code:code returnBlock:^(Boolean result){
        if(result){
            NSDictionary *VehicleDictionary = @{
                self->VehicleVin: code,
            };
            [KeyChainProcess Updatechain:VehicleDictionary forKey:@"License"];
            [self->textField resignFirstResponder];
            [UIView animateWithDuration:0.25 delay:0.25 options:UIViewAnimationOptionCurveEaseInOut animations:^{
                self->activationView.frame = CGRectMake(0, [UIScreen mainScreen].bounds.size.height, [UIScreen mainScreen].bounds.size.width, 360);
            } completion:^(BOOL finish){
                
                UIAlertController * controller = [UIAlertController alertControllerWithTitle:@"" message:ACTIVATION_SUCCESS_CONTENT preferredStyle:UIAlertControllerStyleAlert];
                UIAlertAction * action = [UIAlertAction actionWithTitle:@"Done" style:UIAlertActionStyleDefault handler:^(UIAlertAction * action){}];
                [controller addAction:action];
                [self presentViewController:controller animated:YES completion:nil];
                
                NSDateFormatter * format = [[NSDateFormatter alloc] init];
                format.dateFormat = date_format;
                NSString * date_string = [format stringFromDate:[NSDate date]];
                NSString * content = [NSString stringWithFormat:@"\r\n%@ %@\r\n%@",info_prefix,date_string,ACTIVATION_SUCCESS_CONTENT];
                self.svtTextView.attributedText = [self getTextViewAttributeString:content WithAttribute:@""];
                if(self.svtTextView.contentSize.height > self.svtTextView.frame.size.height){
                    [self.svtTextView setContentOffset:CGPointMake(0, self.svtTextView.contentSize.height - self.svtTextView.frame.size.height) animated:YES];
                }
                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH,0), ^{
                    [self CheckBinFile];
                });
                
                self.activationButton.enabled = NO;
                self.nextButton.enabled = YES;
                [self->bgView removeFromSuperview];
                [self->activationView removeFromSuperview];
                self->bgView = nil;
                self->activationView = nil;

            }];
        
        }else{
            [self->textField resignFirstResponder];
            [UIView animateWithDuration:0.25 delay:0.25 options:UIViewAnimationOptionCurveEaseInOut animations:^{
                self->activationView.frame = CGRectMake(0, [UIScreen mainScreen].bounds.size.height, [UIScreen mainScreen].bounds.size.width, 360);
            } completion:^(BOOL finish){
                [self->bgView removeFromSuperview];
                [self->activationView removeFromSuperview];
            }];

            UIAlertController * controller = [UIAlertController alertControllerWithTitle:@"" message:@"Invalid Active Key." preferredStyle:UIAlertControllerStyleAlert];
            UIAlertAction * action = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * aciton){
                [controller dismissViewControllerAnimated:YES completion:nil];
            }];
            [controller addAction:action];
            [self presentViewController:controller animated:YES completion:nil];
        }
    } withError:^(NSError * error){
        [self->textField resignFirstResponder];
        [UIView animateWithDuration:0.25 delay:0.25 options:UIViewAnimationOptionCurveEaseInOut animations:^{
            self->activationView.frame = CGRectMake(0, [UIScreen mainScreen].bounds.size.height, [UIScreen mainScreen].bounds.size.width, 360);
        } completion:^(BOOL finish){
            [self->bgView removeFromSuperview];
            [self->activationView removeFromSuperview];
        }];

        UIAlertController * controller = [UIAlertController alertControllerWithTitle:@"" message:@"Network cannot connection." preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction * action = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * aciton){
            [controller dismissViewControllerAnimated:YES completion:nil];
        }];
        [controller addAction:action];
        [self presentViewController:controller animated:YES completion:nil];
    }];
    
    
}

#pragma mark 退出背景视图层
-(void)dismissActivityView {
    if(self->activationView.frame.origin.y + self->activationView.frame.size.height < [UIScreen mainScreen].bounds.size.height){
        [self->textField resignFirstResponder];
 
    }else{
        [UIView animateWithDuration:0.25 delay:0.25 options:UIViewAnimationOptionCurveEaseInOut animations:^{
            self->activationView.frame = CGRectMake(0, [UIScreen mainScreen].bounds.size.height, [UIScreen mainScreen].bounds.size.width, 360);
        } completion:^(BOOL finish){
            [self->bgView removeFromSuperview];
            [self->activationView removeFromSuperview];
        }];
    }

}

#pragma mark 键盘相关事件

-(void)keyboardWillShow:(NSNotification *)notify {
    
    NSDictionary * userInfo = notify.userInfo;
    CGFloat duration = [userInfo[@"UIKeyboardAnimationDurationUserInfoKey"] floatValue];
    CGRect beginFrame = [userInfo[@"UIKeyboardFrameBeginUserInfoKey"] CGRectValue];
    CGRect endFrame = [userInfo[@"UIKeyboardFrameEndUserInfoKey"] CGRectValue];
    
    CGRect activiewFrame = CGRectMake(0, activationView.frame.origin.y - endFrame.size.height, activationView.frame.size.width, activationView.frame.size.height);
    
    [UIView animateWithDuration:duration animations:^{
           self->activationView.frame = activiewFrame;
        } completion:^(BOOL finish){
        
    }];
    
}
-(void)keyboardWillHidden:(NSNotification *)notify {
    
    NSDictionary * userInfo = notify.userInfo;
    CGFloat duration = [userInfo[@"UIKeyboardAnimationDurationUserInfoKey"] floatValue];
    CGRect beginFrame = [userInfo[@"UIKeyboardFrameBeginUserInfoKey"] CGRectValue];
    CGRect endFrame = [userInfo[@"UIKeyboardFrameEndUserInfoKey"] CGRectValue];
    
    
    CGRect activiewFrame = CGRectMake(0, activationView.frame.origin.y + endFrame.size.height, activationView.frame.size.width, activationView.frame.size.height);
    [UIView animateWithDuration:duration animations:^{
        self->activationView.frame = activiewFrame;
        } completion:^(BOOL finish){
        
    }];
}

-(void)didTapEscButton {
    [persenter addLeftView];
    NSLog(@"--------> leftButton click");
}

-(void)storeMacrosInDictionary{
    FlashpreparatoryDict = @{
        OperationTypeWriteProgrammingINFO : @(1),
        OperationSetDTCState : @(2),
        OperationSetRoutineControl : @(3),
        OperationResetEcu : @(4),
        OperationChangeSession : @(5),
        OperationWriteDataByIdentifier : @(6),
        OperationSetCommunication : @(7),
    };
    FlashPersentDict = @{
        OperationSendFileToEcu : @(1),
    };
    FlashFinishDict= @{
        OperationHoldSession : @(1),
        OperationExitTransfer : @(2),
        OperationSecurityProcess : @(3),
        OperationSecurityStep1 : @(4),
        OperationWriteCafd : @(5),
        OperationClearDiagnosticInformation : @(6),
        OperationBMWCustom1 : @(7),
    };
    
    FlashErrorCodeDict  = @{
        OperationTypeWriteProgrammingINFO   : @(ProcessErrorTypeRequestDownload),
        OperationSetDTCState                : @(ProcessErrorTypeDTCSettingControl),
        OperationSetRoutineControl          : @(ProcessErrorTypeRoutineControl),
        OperationResetEcu                   : @(ProcessErrorTypeECUReset),
        OperationChangeSession              : @(ProcessErrorTypeDiagnosticSessionControl),
        OperationWriteDataByIdentifier      : @(ProcessErrorTypeWriteDataByIdentifier),
        OperationSetCommunication           : @(ProcessErrorTypeCommunicationControl),
        OperationSendFileToEcu              : @(ProcessErrorTypeTransferData),
        OperationHoldSession                : @(ProcessErrorTypeTransferData),
        OperationExitTransfer               : @(ProcessErrorTypeRequestTransferExit),
        OperationSecurityProcess            : @(ProcessErrorTypeSecurityAccess),
        OperationSecurityStep1              : @(ProcessErrorTypeSecurityAccess),
        OperationWriteCafd                  : @(ProcessErrorTypeWriteDataByIdentifier),
        OperationClearDiagnosticInformation : @(ProcessErrorTypeClearDiagnosticInformation),
        OperationBMWCustom1                 : @(ProcessErrorTypeBMWCustom1),
    };
}

@end
