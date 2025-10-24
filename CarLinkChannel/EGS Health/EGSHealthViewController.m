//
//  EGSHealthViewController.m
//  CarLinkChannel
//
//  Created by job on 2023/5/8.
//

#import "EGSHealthViewController.h"

#import "AutoNetworkService.h"

@interface EGSHealthViewController ()<UITableViewDelegate,UITableViewDataSource>
{
//    ECUInteractive * interactive;
    NSArray * egsArray;
    NSArray * fillArray;
    AutoNetworkService *Network;
}
@property (weak, nonatomic) IBOutlet UITableView *tableView;

@end

@implementation EGSHealthViewController
-(void)didTapEscButton {
    [self.navigationController popViewControllerAnimated:YES];
}
- (void)viewDidLoad {
    [super viewDidLoad];
    self.tableView.tableHeaderView = [[UIView alloc] init];
    
    // table fooderview
    UIView * fooderView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, 40)];
    
    NSString * fooderText = @" Gray represent a healthy clutch condition.\r\n Yellow indicate a worn clutch condition.\r\n Red signify a imminent damage need of repair.";
    NSMutableAttributedString * mutableString = [[NSMutableAttributedString alloc] initWithString:fooderText];
    [mutableString addAttributes:@{NSForegroundColorAttributeName:[UIColor darkGrayColor],NSFontAttributeName:[UIFont systemFontOfSize:14]} range:NSMakeRange(0, fooderText.length)];
    
    NSRange serverRange = [fooderText rangeOfString:@"healthy clutch"];
    [mutableString addAttributes:@{NSForegroundColorAttributeName:[UIColor whiteColor]} range:serverRange];
    
    NSRange imminRange = [fooderText rangeOfString:@"worn clutch"];
    [mutableString addAttributes:@{NSForegroundColorAttributeName:[UIColor yellowColor]} range:imminRange];
 
    NSRange thirdRange = [fooderText rangeOfString:@"imminent damage"];
    [mutableString addAttributes:@{NSForegroundColorAttributeName:[UIColor redColor]} range:thirdRange];
    
    
    UILabel * fooderLabel = [[UILabel alloc] initWithFrame:CGRectMake(20, 20, [UIScreen mainScreen].bounds.size.width - 40, 60)];
    
    fooderLabel.numberOfLines = 0;
    fooderLabel.attributedText = mutableString;
    [fooderView addSubview:fooderLabel];
    
    self.tableView.tableFooterView = fooderView;
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[[UIImage imageNamed:@"escimg"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal] style:UIBarButtonItemStyleDone target:self action:@selector(didTapEscButton)];
    self.title = @"EGS Health";
    self.navigationController.navigationBar.tintColor = [UIColor whiteColor];
    self.navigationController.navigationBar.barTintColor = [UIColor blackColor];
//    self.navigationController.navigationBar.titleTextAttributes = @{NSForegroundColorAttributeName:[UIColor whiteColor]};
//    UINavigationBarAppearance * navibarAppearance = [[UINavigationBarAppearance alloc] init];
    NSDictionary * titleAttribute = @{NSForegroundColorAttributeName:[UIColor darkGrayColor]};
    self.navigationController.navigationBar.titleTextAttributes = titleAttribute;
    
    
    [self addSwapGesture];
    
    self->Network = [AutoNetworkService sharedInstance];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        NSDictionary *HealthData = [self->Network ReadTCUHealthData];
        [self HealthDataProcess:HealthData];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.tableView reloadData];
        });
    });
}

-(void)HealthDataProcess:(NSDictionary *)OriginalData{
    NSData *HealthData = OriginalData[@"pressure"];
    self->egsArray = [self AddHealthDataFromVehicleData:HealthData];
    NSData *timeData = OriginalData[@"time"];
    self->fillArray = [self AddTimeFromVehicleData:timeData];
}
-(NSArray *)AddHealthDataFromVehicleData:(NSData *)data{
    NSUInteger length = [data length];
    uint16_t extractedValue;
    NSMutableArray *resultArray = [NSMutableArray array]; // 初始化数组
    for (NSUInteger i = 0; i < length; i += 2) {
        NSRange range = NSMakeRange(i, 2);
        [data getBytes:&extractedValue range:range];
        extractedValue = CFSwapInt16BigToHost(extractedValue);
        NSNumber *number = [NSNumber numberWithUnsignedShort:extractedValue];
        [resultArray addObject:number];
    }
    return resultArray;
}
-(NSArray *)AddTimeFromVehicleData:(NSData *)data{
    NSUInteger length = [data length];
    uint16_t extractedValue;
    NSMutableArray *resultArray = [NSMutableArray array]; // 初始化数组
    for (NSUInteger i = 0; i < length; i += 2) {
        NSRange range = NSMakeRange(i, 2);
        [data getBytes:&extractedValue range:range];
        extractedValue = CFSwapInt16BigToHost(extractedValue);
        NSNumber *number = [NSNumber numberWithUnsignedShort:extractedValue];
        [resultArray addObject:number];
    }
    return resultArray;
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
-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    int row1 = self->egsArray == nil  ? 0 : 1;
    int row2 = self->fillArray == nil ? 0: 1;
    return row1 + row2;
}
-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    UITableViewCell * cell = [tableView dequeueReusableCellWithIdentifier:@"EGS Health Cell"];
//    cell.selectionStyle =
    UILabel * titleLabel = [cell viewWithTag:100];
    
    UILabel * labelA = [cell viewWithTag:1000];
    UILabel * labelB = [cell viewWithTag:2000];
    UILabel * labelC = [cell viewWithTag:3000];
    UILabel * labelD = [cell viewWithTag:4000];
    UILabel * labelE = [cell viewWithTag:5000];
    labelA.text = @"a mbar";
    labelB.text = @"b mbar";
    labelC.text = @"c mbar";
    labelD.text = @"d mbar";
    labelE.text = @"e mbar";
        
    if(indexPath.row == 0){
        titleLabel.text = @"Clutch filling pressure";
        labelA.attributedText = [self getClutchFillString:self->egsArray[0]];
        labelB.attributedText = [self getClutchFillString:self->egsArray[1]];
        labelC.attributedText = [self getClutchFillString:self->egsArray[2]];
        labelD.attributedText = [self getClutchFillString:self->egsArray[3]];
        labelE.attributedText = [self getClutchFillString:self->egsArray[4]];
        
    }
    if(indexPath.row == 1){
        titleLabel.text = @"Fast filling time";
        labelA.attributedText = [self getClutchTime:self->fillArray[0]];
        labelB.attributedText = [self getClutchTime:self->fillArray[1]];
        labelC.attributedText = [self getClutchTime:self->fillArray[2]];
        labelD.attributedText = [self getClutchTime:self->fillArray[3]];
        labelE.attributedText = [self getClutchTime:self->fillArray[4]];
    }

    return cell;
}
-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    return 200;
}

- (IBAction)healthReturnmethod:(id)sender {
    [self.navigationController popViewControllerAnimated:YES];
}


-(NSAttributedString *)getClutchTime:(NSNumber *)filltime {
    
    return [self getClutchFillTime:filltime];
}

// 这里根据值计算出离合器加注时间
// 离合器如果是以ff开头
-(NSAttributedString *)getClutchFillTime:(NSNumber *)fillstring {
    uint16_t raw = [fillstring unsignedShortValue];
    int16_t OriValue = (int16_t)raw;

    NSString * valueText = [NSString stringWithFormat:@"%d.0 mbar",OriValue];
    NSAttributedString * attributeString ;
    if(OriValue >= 70 || OriValue <= -70){
        attributeString = [[NSAttributedString alloc] initWithString:valueText attributes:@{NSFontAttributeName:[UIFont systemFontOfSize:16],NSForegroundColorAttributeName:[UIColor redColor]}];
    }else if (OriValue >= 40 || OriValue <= -40){
        attributeString = [[NSAttributedString alloc] initWithString:valueText attributes:@{NSFontAttributeName:[UIFont systemFontOfSize:16],NSForegroundColorAttributeName:[UIColor yellowColor]}];
    }else{
        attributeString = [[NSAttributedString alloc] initWithString:valueText attributes:@{NSFontAttributeName:[UIFont systemFontOfSize:16],NSForegroundColorAttributeName:[UIColor darkGrayColor]}];
    }

    return attributeString;
}

-(NSAttributedString *)getClutchFillString:(NSNumber *)fillstring {
    return [self getClutchFillbar:fillstring];
}
// 这里是计算离合器加注压力
// 离合器如果是以ff开头
-(NSAttributedString *)getClutchFillbar:(NSNumber *)fillstring {

    uint16_t raw = [fillstring unsignedShortValue];
    int16_t OriValue = (int16_t)raw;

    NSString * valueText = [NSString stringWithFormat:@"%d.0 mbar",OriValue];
    NSAttributedString * attributeString ;
    
    if(OriValue > 700 || OriValue < -700){
        attributeString = [[NSAttributedString alloc] initWithString:valueText attributes:@{NSFontAttributeName:[UIFont systemFontOfSize:16],NSForegroundColorAttributeName:[UIColor redColor]}];
    }else if (OriValue > 400 || OriValue < -400){
        attributeString = [[NSAttributedString alloc] initWithString:valueText attributes:@{NSFontAttributeName:[UIFont systemFontOfSize:16],NSForegroundColorAttributeName:[UIColor yellowColor]}];
    }else{
        attributeString = [[NSAttributedString alloc] initWithString:valueText attributes:@{NSFontAttributeName:[UIFont systemFontOfSize:16],NSForegroundColorAttributeName:[UIColor darkGrayColor]}];
    }
    
    return attributeString;
}


@end
