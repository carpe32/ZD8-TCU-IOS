//
//  FaultCodeViewController.m
//  CarLinkChannel
//
//  Created by job on 2023/5/8.
//

#import "FaultCodeViewController.h"
#import "FaultCodeTableViewCell.h"
#import "AutoNetworkService.h"

@interface FaultCodeViewController ()<UITableViewDelegate,UITableViewDataSource>
{
    NSMutableArray * dmeArray;
    NSMutableArray * egsArray;
    
    AutoNetworkService *Network;
    LoadingView *loadingview;
}
@property (weak, nonatomic) IBOutlet UITableView *tableView;
//@property (nonatomic,strong) ECUInteractive * interactive;
@property (strong, nonatomic) IBOutlet UIButton *ClearButton;

@end

@implementation FaultCodeViewController

- (void)viewDidLoad {
    Network = [AutoNetworkService sharedInstance];
    dmeArray = [NSMutableArray array];
    egsArray = [NSMutableArray array];
    [super viewDidLoad];
    self.ClearButton.enabled = NO;
    
    self.title = @"Vehicle Fault Code";
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[[UIImage imageNamed:@"escimg"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal] style:UIBarButtonItemStyleDone target:self action:@selector(didTapEscButton)];
    self.navigationController.navigationBar.tintColor = [UIColor whiteColor];
    self.navigationController.navigationBar.barTintColor = [UIColor blackColor];
    NSDictionary * titleAttribute = @{NSForegroundColorAttributeName:[UIColor darkGrayColor]};
    self.navigationController.navigationBar.titleTextAttributes = titleAttribute;
    [self addSwapGesture];
    [self loadFaultCodeEcu];
}

- (NSMutableArray<NSNumber *> *)convertNSDataToUInt32Array:(NSData *)data {
    // 创建一个用于存储结果的可变数组
    NSMutableArray<NSNumber *> *resultArray = [NSMutableArray array];
    
    // 获取NSData的字节指针
    const uint8_t *bytes = (const uint8_t *)[data bytes];
    NSUInteger length = [data length];

    // 遍历NSData，每四个字节组成一个uint32_t
    NSUInteger i = 0;
    for (; i + 4 <= length; i += 4) {
        uint32_t value = 0;
        
        // 按照大端顺序拼接每4个字节
        value |= (uint32_t)bytes[i] << 24;
        value |= (uint32_t)bytes[i + 1] << 16;
        value |= (uint32_t)bytes[i + 2] << 8;
        value |= (uint32_t)bytes[i + 3];
        
        // 将拼接好的uint32_t作为NSNumber存储到数组中
        [resultArray addObject:@(value)];
    }

    // 处理剩余的字节（如果有）
    if (i < length) {
        uint32_t value = 0;
        NSUInteger remainingBytes = length - i;

        // 按照大端顺序拼接剩余的字节
        for (NSUInteger j = 0; j < remainingBytes; j++) {
            value |= (uint32_t)bytes[i + j] << (8 * (remainingBytes - 1 - j));
        }

        // 将拼接好的剩余字节作为NSNumber存储到数组中
        [resultArray addObject:@(value)];
    }

    // 返回不可变的NSArray
    return [resultArray copy];
}

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
#pragma mark 收到故障码的通知 eme
-(void)recvdmenotification:(NSNotification *)notify {
//    NSDictionary * dataDict = notify.userInfo;
//    NSArray * dataArray = dataDict[@"data"];
//    [dmeArray addObjectsFromArray:dataArray];
//    dispatch_async(dispatch_get_main_queue(), ^{
//        [self.tableView reloadData];
//    });
    
}
#pragma mark egs
-(void)recvegsnotification:(NSNotification *)notify {
//    NSDictionary * dataDict = notify.userInfo;
//    NSArray * dataArray = dataDict[@"data"];
//    [egsArray addObjectsFromArray:dataArray];
//    dispatch_async(dispatch_get_main_queue(), ^{
//        [self.tableView reloadData];
//    });
    
}
-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    return (self->dmeArray.count == 0 ? 0 : 1) + (self->egsArray.count == 0 ? 0 : 1);
}
-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    if(section == 0){
        if(dmeArray.count <= 0){
            return egsArray.count;
        }
        return dmeArray.count;
    }
    if(section == 1){
        return egsArray.count;
    }
    return 0;
}
-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    FaultCodeTableViewCell * cell = [tableView dequeueReusableCellWithIdentifier:@"FaultCode Cell"];
    UIView * bgView = [cell viewWithTag:1000];
    UILabel * codeLabel = [cell viewWithTag:2000];
    UILabel * descriLabel = [cell viewWithTag:3000];
    UIView * line = [cell viewWithTag:4000];
    line.backgroundColor = [UIColor colorWithRed:110/255.0 green:110/255.0 blue:110/255.0 alpha:1.0];
    if(indexPath.row == 0){
        bgView.layer.cornerRadius = 6;
        bgView.layer.masksToBounds = YES;
        cell.topContant.constant = 6;
        cell.bottomConstant.constant = 0;
        
    }
    descriLabel.text = @"";
    if(indexPath.section == 0){
        if(indexPath.row >= dmeArray.count - 1){
            bgView.layer.cornerRadius = 6;
            bgView.layer.masksToBounds = YES;
            cell.topContant.constant = 0;
            cell.bottomConstant.constant = 6;
            line.backgroundColor = [UIColor clearColor];
        }else if(indexPath.row >= 1){
            bgView.layer.cornerRadius = 0;
            bgView.layer.masksToBounds = NO;
            cell.topContant.constant = 0;
            cell.bottomConstant.constant = 0;
        }

    }
    if(indexPath.section == 1){
        if(indexPath.row >= egsArray.count - 1){
            bgView.layer.cornerRadius = 6;
            bgView.layer.masksToBounds = YES;
            cell.topContant.constant = 0;
            cell.bottomConstant.constant = 6;
            line.backgroundColor = [UIColor clearColor];
        }else if(indexPath.row >= 1){
            bgView.layer.cornerRadius = 0;
            bgView.layer.masksToBounds = NO;
            cell.topContant.constant = 0;
            cell.bottomConstant.constant = 0;
        }
    }
    
    if(indexPath.section == 0){
        if(dmeArray.count <= 0){
            codeLabel.text = [self convertNumberToHexWithPadding:egsArray[indexPath.row]];
        }else{
            codeLabel.text = [self convertNumberToHexWithPadding:dmeArray[indexPath.row]];
        }
    }
    
    if(indexPath.section == 1){
        codeLabel.text = [self convertNumberToHexWithPadding:egsArray[indexPath.row]];
    }
    
    
    return cell;
}

- (NSString *)convertNumberToHexWithPadding:(NSNumber *)number {
    // 获取 unsigned int 值
    uint32_t value = [number unsignedIntValue];
    
    // 将值转换为十六进制字符串，并补齐到8位
    NSString *hexString = [NSString stringWithFormat:@"%08X", value];
    
    return hexString;
}


-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{

    return 66;
}
-(CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section{
    return 40;
}
-(UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section{
        
    UIView * v = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 200, 40)];
    UILabel * headerLabel = [[UILabel alloc] initWithFrame:CGRectMake(20, 10, 100, 30)];
    headerLabel.textColor = [UIColor darkGrayColor];
    headerLabel.font = [UIFont systemFontOfSize:14.0];
    [v addSubview:headerLabel];
    if(section == 0){
        if(dmeArray.count <= 0){
            headerLabel.text = @"EGS";
        }else{
            headerLabel.text = @"DME";
        }
    }else if (section == 1){
        headerLabel.text = @"EGS";
    }
    [v addSubview:headerLabel];
    return v;
}
- (IBAction)clearFaultCode:(id)sender {
    
    [self AddBlackBackgroundToView];
    
    dmeArray = [dmeArray mutableCopy];  // 将 dmeArray 转换为可变数组
    egsArray = [egsArray mutableCopy];  // 将 dmeArray 转换为可变数组
    self.ClearButton.enabled = NO;
    [self->dmeArray removeAllObjects];
    [self->egsArray removeAllObjects];
    [self.tableView reloadData];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [self->Network ClearFaultForVehicle];
        sleep(5);
        
        [self RemoveBlackBackgroundFromView];
        [self loadFaultCodeEcu];
    });

}
-(void)loadFaultCodeEcu{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        //This part is read All Diagnose Code
//        NSArray<UDSMultipleResponse *> *DiagCodeArray = [self->Network ReadDiagnose];
//        for(UDSMultipleResponse *response in DiagCodeArray)
//        {
//            if(response.ECUID == 0x18)
//            {
//                NSData *TCUData = [response.Data subdataWithRange:NSMakeRange(1, response.Data.length - 1)];
//                self->egsArray =[self convertNSDataToUInt32Array:TCUData];
//            }
//            if(response.ECUID == 0x12)
//            {
//                NSData *DMEData = [response.Data subdataWithRange:NSMakeRange(1, response.Data.length - 1)];
//                self->dmeArray =[self convertNSDataToUInt32Array:DMEData];
//            }
//        }

        NSData *TCUData = [self->Network ReadOnlyDiagnose:0x18];
        TCUData = [TCUData subdataWithRange:NSMakeRange(1, TCUData.length - 1)];
        self->egsArray = [self convertNSDataToUInt32Array:TCUData];
        
        NSData *DMEData = [self->Network ReadOnlyDiagnose:0x12];
        DMEData = [DMEData subdataWithRange:NSMakeRange(1, DMEData.length - 1)];
        self->dmeArray = [self convertNSDataToUInt32Array:DMEData];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.tableView reloadData];
            self.ClearButton.enabled = YES;
        });
    });
}

-(void)AddBlackBackgroundToView{
    dispatch_async(dispatch_get_main_queue(), ^{
        self->loadingview = [[LoadingView alloc] initWithMessage:@"Operating, please wait ..."];
        self->loadingview.frame = self.view.frame;
        [self.view addSubview:self->loadingview];
    });
}

-(void)RemoveBlackBackgroundFromView{
    dispatch_async(dispatch_get_main_queue(), ^{
        for (UIView *subview in self.view.subviews) {
            if ([subview isKindOfClass:[LoadingView class]]) {
                [subview removeFromSuperview];
                break; // 找到并移除后跳出循环
            }
        }
    });
}

@end
