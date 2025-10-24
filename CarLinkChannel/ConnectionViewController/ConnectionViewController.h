//
//  ConnectionViewController.h
//  CarLinkChannel
//
//  Created by job on 2023/3/27.
//


#import <UIKit/UIKit.h>
#import "AutoNetworkService.h"
#import "BINFileProcess.h"
#import "PopWindow.h"
#import "VersionManager.h"
#import "KeyChainProcess.h"

NS_ASSUME_NONNULL_BEGIN

@interface ConnectionViewController : UIViewController
@property (weak, nonatomic) IBOutlet UILabel *vinLabel;
@property (weak, nonatomic) IBOutlet UITextView *svtTextView;

-(void)downloadCafdFile;
@end

typedef NS_ENUM(NSInteger, EcuProcessErrorType) {
    ProcessErrorTypeTimeOut = 0xFF,                                     //request Time out
    
    ProcessErrorTypeDiagnosticSessionControl = 0x01,                   // 诊断会话控制                                0x10,
    ProcessErrorTypeECUReset = 0x02,                                   // ECU复位                                    0x11,
    ProcessErrorTypeClearDiagnosticInformation = 0x03,                 // 清除故障码                                  0x14,
    ProcessErrorTypeReadDTCInformation = 0x04,                         // 读取故障码                                  0x19,
    ProcessErrorTypeReadDataByIdentifier = 0x05,                       // 读取数据标识符  0x22,
    ProcessErrorTypeReadMemoryByAddress = 0x06,                        // 读取存储的数据   0x23,
    ProcessErrorTypeReadECUIdentification = 0x07,                      // 读取ECU标识符  0x1A,
    ProcessErrorTypeSecurityAccess = 0x08,                             // 安全访问       0x27,
    ProcessErrorTypeCommunicationControl = 0x09,                       //通信控制（用于开关某个通信方式，比如禁用CAN）   0x28,

    ProcessErrorTypeWriteDataByIdentifier = 0x0A,                      // 写入数据标识符                               0x2E,
    ProcessErrorTypeRoutineControl = 0x0B,                             // 远程激活例程        0x31,
    ProcessErrorTypeRequestDownload = 0x0C,                            // 请求下载          0x34,
    ProcessErrorTypeRequestUpload = 0x0D,                               // 请求上传         0x35,
    ProcessErrorTypeTransferData = 0x0E,                                // 传输数据         0x36,
    ProcessErrorTypeRequestTransferExit = 0x0F,                         // 传输退出         0x37,
    ProcessErrorTypeRequestTesterPresent = 0x10,                        //保持                0x3E,
    ProcessErrorTypeDTCSettingControl = 0x11,                           //诊断码控制         0x85,
    ProcessErrorTypeBMWCustom1 = 0x12                                   //通过标识符读取数据     0xB1
};


NS_ASSUME_NONNULL_END
