//
//  UploadManager.m
//  TTS Tuning
//
//  Created by 刘润泽 on 2024/8/7.
//

#import "UploadManager.h"

@interface UploadManager()
{
    NSString *CafdLoaclPath;
    NSString *MidLocalPath;
    
    NSString *VinFileNameMid;
    NSString *VinFileNameCafd;
    BOOL InitMsgState;
}

@property(nonatomic, strong) FMServer *CafdServer;
@property(nonatomic, strong) FMServer *MidServer;
@property(nonatomic, strong) FMServer *LogServer;

@property(nonatomic, strong) FTPManager *ftpManagerCafd;
@property(nonatomic, strong) FTPManager *ftpManagerMid;
@property(nonatomic, strong) FTPManager *ftpManagerLog;


@end

@implementation UploadManager
static UploadManager *uploadManager = nil;
static dispatch_once_t onceToken;

//shard manager
+(instancetype)sharedInstance{

    dispatch_once(&onceToken, ^{
        uploadManager = [[self alloc] init];
        [uploadManager InitServer];
    });
    
    return uploadManager;
}
//initialize the ftp service for cafd and mid files
-(void)InitServer{
    InitMsgState = false;
    NSString *CafdURL = [NSString stringWithFormat:@"%@%@", FTP_HOST, FTP_CAFD_URL];
    // 创建服务器配置
    self.CafdServer = [FMServer serverWithDestination:CafdURL username:FTP_USER_NAME password:FTP_PASSWORD];
    self.CafdServer.port = FTP_PORT;
    
    NSString *MidURL = [NSString stringWithFormat:@"%@%@", FTP_HOST, FTP_MID_PATH];
    // 创建服务器配置
    self.MidServer = [FMServer serverWithDestination:MidURL username:FTP_USER_NAME password:FTP_PASSWORD];
    self.MidServer.port = FTP_PORT;
    
    NSString *LogURL = [NSString stringWithFormat:@"%@%@", FTP_HOST, @"/Log/TCU"];
    // 创建服务器配置
    self.LogServer = [FMServer serverWithDestination:LogURL username:FTP_USER_NAME password:FTP_PASSWORD];
    self.LogServer.port = FTP_PORT;
    
    self.ftpManagerCafd = [[FTPManager alloc] init];
    self.ftpManagerMid = [[FTPManager alloc] init];
    self.ftpManagerLog = [[FTPManager alloc] init];
}

-(BOOL)checkVehicleInfoFileAvailability:(NSString *)VehicleVin{
    BOOL result = true;
    NSString *cafdPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)[0] stringByAppendingPathComponent:@"UploadFiles/cafd/"];
    NSString *VinFilaname = [NSString stringWithFormat:@"%@.xml",VehicleVin];
    
    if(![self CheckServerHasFile:VinFilaname Server:self.CafdServer Manager:self.ftpManagerCafd]){
        if(![self fileExistsAtPath:cafdPath withFileName:VinFilaname]){
            result = false;
        }
    }
    return result;
}

-(void)CheckAndCreateLogFolder:(NSString *)Vin{
    if(![self CheckServerHasFile:Vin Server:self.LogServer Manager:self.ftpManagerLog])
    {
        [self.ftpManagerLog createNewFolder:Vin atServer:self.LogServer];
        NSString *LogURL = [NSString stringWithFormat:@"%@%@%@", FTP_HOST, @"/Log/TCU/",Vin];
        // 创建服务器配置
        self.LogServer = [FMServer serverWithDestination:LogURL username:FTP_USER_NAME password:FTP_PASSWORD];
        self.LogServer.port = FTP_PORT;
    }
    else
    {
        NSString *LogURL = [NSString stringWithFormat:@"%@%@%@", FTP_HOST, @"/Log/TCU/",Vin];
        // 创建服务器配置
        self.LogServer = [FMServer serverWithDestination:LogURL username:FTP_USER_NAME password:FTP_PASSWORD];
        self.LogServer.port = FTP_PORT;
    }
}
-(void)uploadLogFile:(NSString *)FilePath{
    [self.ftpManagerLog uploadFile:[NSURL fileURLWithPath:FilePath] toServer:self.LogServer];
}

//upload cafd file
-(void)uploadCafdFile{
    NSString *CafdFilePath = [CafdLoaclPath stringByAppendingPathComponent:VinFileNameCafd];
    BOOL isSuccess = [self.ftpManagerCafd uploadFile:[NSURL fileURLWithPath:CafdFilePath] toServer:self.CafdServer];
    NSLog(@"上传文件结果: %d",isSuccess);
}
//download cafd file
-(BOOL)DownloadCafdFile{
    BOOL success = [self.ftpManagerCafd downloadFile:VinFileNameCafd toDirectory:[NSURL fileURLWithPath:CafdLoaclPath] fromServer:self.CafdServer];
    if (success) {
        NSLog(@"下载成功");
    } else {
        NSLog(@"下载失败");
    }
    
    return success;
}

-(void)printXmlContents:(NSString *)xmlPath {
    // 读取 XML 数据
    NSData *xmlData = [NSData dataWithContentsOfFile:xmlPath];
    NSError *error = nil;
    
    // 使用 GDataXMLDocument 解析 XML 数据
    GDataXMLDocument *xmlDoc = [[GDataXMLDocument alloc] initWithData:xmlData encoding:NSUTF8StringEncoding error:&error];
    
    // 错误处理：如果无法加载 XML 数据，打印错误并返回
    if (error) {
        NSLog(@"Error loading XML: %@", error.localizedDescription);
        return;
    }
    
    // 调用递归方法打印 XML 内容
    [self printXmlNode:xmlDoc.rootElement indentLevel:0];
}

-(void)printXmlNode:(GDataXMLElement *)node indentLevel:(int)level {
    // 打印节点名称
    NSMutableString *indentation = [NSMutableString stringWithCapacity:level];
    for (int i = 0; i < level; i++) {
        [indentation appendString:@"  "];  // 每一级缩进两个空格
    }
    
    // 打印当前节点的名称
    NSLog(@"%@%@", indentation, node.name);
    
    // 打印当前节点的所有属性
    for (GDataXMLNode *attribute in node.attributes) {
        NSLog(@"%@  %@: %@", indentation, attribute.name, attribute.stringValue);
    }
    
    // 递归遍历子节点
    for (GDataXMLElement *child in node.children) {
        [self printXmlNode:child indentLevel:level + 1];  // 递归调用，增加缩进级别
    }
}
//upload Mid file
-(void)uploadMidFile{
    static NSObject *lockObject = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        lockObject = [[NSObject alloc] init];
    });

    @synchronized(lockObject) {
        // 这段代码被锁住，其他线程在此之前会被阻塞
        NSLog(@"Executing synchronized code block");
        // 在这里添加你需要上锁的代码
        NSString *MidFilePath = [MidLocalPath stringByAppendingPathComponent:VinFileNameMid];
        BOOL isSuccess = [self.ftpManagerMid uploadFile:[NSURL fileURLWithPath:MidFilePath] toServer:self.MidServer];
        NSLog(@"上传文件结果: %d",isSuccess);
    }
}
//download mid file
-(void)DownloadMidFile{
    NSString *DownloadPath = [MidLocalPath stringByAppendingPathComponent:@"Download"];
    [self ensureDirectoryExists:DownloadPath];
    BOOL success = [self.ftpManagerMid downloadFile:VinFileNameMid toDirectory:[NSURL fileURLWithPath:DownloadPath] fromServer:self.MidServer];
    if (success) {
        NSLog(@"下载成功");
    } else {
        NSLog(@"下载失败");
    }
}

//This method is used to read the ecu version information for the first time and upload it to the server
-(void)firstECUVersionUpload:(NSString *)Vin SvtInfo:(NSArray *)Svtinfo CafdInfo:(NSArray *)Cafdinfo{

    VinFileNameMid = [NSString stringWithFormat:@"%@.xml",Vin];
    VinFileNameCafd= [NSString stringWithFormat:@"%@.xml",Vin];
    //check and create File path
    NSString *cafdPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)[0] stringByAppendingPathComponent:@"UploadFiles/cafd/"];
    [self ensureDirectoryExists:cafdPath];
    NSString *MinPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)[0] stringByAppendingPathComponent:@"UploadFiles/min/"];
    [self ensureDirectoryExists:MinPath];
    
    CafdLoaclPath = cafdPath;
    MidLocalPath = MinPath;
    
    [self CafdProcess:Svtinfo :Cafdinfo];
    [self uploadCafdFile];
    [self MidProcess:Svtinfo];
    [self uploadMidFile];
    InitMsgState = true;
}
//Tihis method is used to ensure that the file path exists
-(void) ensureDirectoryExists:(NSString *)directoryPath{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    BOOL isDirectory = NO;
    if (![fileManager fileExistsAtPath:directoryPath isDirectory:&isDirectory] || !isDirectory) {
        NSError *error = nil;
        if ([fileManager createDirectoryAtPath:directoryPath withIntermediateDirectories:YES attributes:nil error:&error]) {
            NSLog(@"文件夹创建成功: %@", directoryPath);
        } else {
            NSLog(@"文件夹创建失败: %@", error.localizedDescription);
        }
    } else {
        NSLog(@"文件夹已存在: %@", directoryPath);
    }
}
//This method is used to process cafd file
-(void)CafdProcess:(NSArray*)Svt :(NSArray*)Cafd{
    NSString *CafdFilePath = [CafdLoaclPath stringByAppendingPathComponent:VinFileNameCafd];
    if([self CheckServerHasFile:VinFileNameCafd Server:self.CafdServer Manager:self.ftpManagerCafd] && [self ensureFileSize:VinFileNameCafd Server:self.CafdServer Manager:self.ftpManagerCafd])
    {
        //if server has cafd file
        [self DownloadCafdFile];
    }
    else
    {
        //if server hasn't cafd file
        if([self fileExistsAtPath:CafdLoaclPath withFileName:VinFileNameCafd])
        {
            //loacl has cafd file
        }
        else
        {
            [XmlProcess CreateGeneralXml:CafdFilePath];
        }
    }
    [XmlProcess AddSvtAndCafdInformationToCafd:CafdFilePath :Svt :Cafd];
}
//This method is used to process mid file
-(void)MidProcess:(NSArray *)Svt{
    NSString *MinFilePath = [MidLocalPath stringByAppendingPathComponent:VinFileNameMid];
    if([self CheckServerHasFile:VinFileNameMid Server:self.MidServer Manager:self.ftpManagerMid] && [self ensureFileSize:VinFileNameMid Server:self.MidServer Manager:self.ftpManagerMid])
    {
        // if server has mid file
        [self DownloadMidFile];
        [XmlProcess DownloadMidFileProess:MidLocalPath :VinFileNameMid];
    }
    else
    {
        //if server hasn't mid file
        if([self fileExistsAtPath:MidLocalPath withFileName:VinFileNameMid])
        {
            //local has mid file
            
        }
        else
        {
            //local hasn't mid file
            [XmlProcess CreateGeneralXml:MinFilePath];
        }
    }
    [XmlProcess AddSvtToMid:MinFilePath :Svt];
}

-(void)UploadMidFromServer{
    if([self ensureFileSize:VinFileNameMid Server:self.MidServer Manager:self.ftpManagerMid])
        [self DownloadMidFile];
    [XmlProcess DownloadMidFileProess:MidLocalPath :VinFileNameMid];
}

-(void)uploadFlashCellName:(NSString *)nameFile :(BOOL)State{
    
    NSString *MinFilePath = [MidLocalPath stringByAppendingPathComponent:VinFileNameMid];
    [XmlProcess AddOptionOrChangeStateToMid:MinFilePath :nameFile :State];
    [self uploadMidFile];
    
}

-(NSDictionary *)ReadFlashLastName{
    NSString *MinFilePath = [MidLocalPath stringByAppendingPathComponent:VinFileNameMid];
    return [XmlProcess ReadlastFlashFileName:MinFilePath];
}

-(void)uploadFlashErrorInformation:(NSString *)OptionName :(NSString *)info :(NSString *)index :(NSString *)processName :(NSData *)Data :(uint8_t)Fid{
    NSString *MinFilePath = [MidLocalPath stringByAppendingPathComponent:VinFileNameMid];
    [XmlProcess AddOptionErrorMessage:MinFilePath :OptionName :index :processName :Data :Fid];
    
    [self uploadMidFile];
}
-(void)UploadLicence:(NSString *)Code :(NSString *)level{
    NSString *MinFilePath = [MidLocalPath stringByAppendingPathComponent:VinFileNameMid];
    [XmlProcess AddLicenceinformation:MinFilePath :Code :level];
    [self uploadMidFile];
}

-(NSArray *)ReadServerCafd{
    if([self ensureFileSize:VinFileNameCafd Server:self.CafdServer Manager:self.ftpManagerCafd])
        [self DownloadCafdFile];
    NSString *CafdFilePath = [CafdLoaclPath stringByAppendingPathComponent:VinFileNameCafd];
    return [XmlProcess CheckCafdInfoFromFilePath:CafdFilePath];
}


//This method is used to check thether the server has the file
-(bool)CheckServerHasFile:(NSString *)fileName Server:(FMServer *)server Manager:(FTPManager *)Ftpmanager{
    
    NSArray *serverContents = [Ftpmanager contentsOfServer:server];
    
    for (NSDictionary *fileInfo in serverContents) {
        NSString *fileNames = [fileInfo objectForKey:(id)kCFFTPResourceName];
        if ([fileNames isEqualToString:fileName]) {
            NSLog(@"找到了文件");
            return true;
        }
    }
    return false;
}

-(bool)ensureFileSize:(NSString *)fileName Server:(FMServer *)server Manager:(FTPManager *)Ftpmanager{
    NSArray *serverContents = [Ftpmanager contentsOfServer:server];
    
    for (NSDictionary *fileInfo in serverContents) {
        NSString *fileNames = [fileInfo objectForKey:(id)kCFFTPResourceName];
        if ([fileNames isEqualToString:fileName])
        {
            NSNumber *fileSize = [fileInfo objectForKey:(id)kCFFTPResourceSize];
            if ([fileSize integerValue] > 0) {
                return true;
            }
        }
    }
    return false;
}


-(MidSetBin *)CheckWhetherSetBIN{
    while(!InitMsgState)
    {
        usleep(200000);
    }
    NSString *MinFilePath = [MidLocalPath stringByAppendingPathComponent:VinFileNameMid];
    return [XmlProcess ReadWhetherSetBin:MinFilePath];
}

-(void)SetBinStateAndFileName:(NSString *)State :(NSString *)BinName{
    while(!InitMsgState)
    {
        usleep(200000);
    }
    NSString *MinFilePath = [MidLocalPath stringByAppendingPathComponent:VinFileNameMid];
    [XmlProcess WriteStateAndBinFileName:MinFilePath state:State binFileName:BinName];
}

-(NSString *)CheckFirstDownloadBinFile{
    while(!InitMsgState)
    {
        usleep(200000);
    }
    NSString *MinFilePath = [MidLocalPath stringByAppendingPathComponent:VinFileNameMid];
    return [XmlProcess ReadDownloadBinFile:MinFilePath];
}

- (BOOL)fileExistsAtPath:(NSString *)directoryPath withFileName:(NSString *)fileName {
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSString *fullFilePath = [directoryPath stringByAppendingPathComponent:fileName];
    
    BOOL isDirectory = NO;
    BOOL fileExists = [fileManager fileExistsAtPath:fullFilePath isDirectory:&isDirectory];
    
    // Ensure the path is a file and not a directory
    return fileExists && !isDirectory;
}

-(void)DownloadFlashFile:(NSString *)FileName{
    NSString *DownloadUrl = [NSString stringWithFormat:@"%@/%@",FILE_HOST,FileName];
    [self loadFileWithUrl:DownloadUrl];
}

-(void)SaveAndUploadDownloadFileName:(NSString *)filename{
    NSString *MinFilePath = [MidLocalPath stringByAppendingPathComponent:VinFileNameMid];
    [XmlProcess AddDownloadBinFileNameToMid:MinFilePath :filename];
    [self uploadMidFile];
}

-(void)loadFileWithUrl:(NSString * )fileUrl{
    NSURLRequest * request = [NSURLRequest requestWithURL:[NSURL URLWithString:fileUrl]];
    NSURLSessionDownloadTask * downTask = [[NSURLSession sharedSession] downloadTaskWithRequest:request completionHandler:^(NSURL * url,NSURLResponse * reponse,NSError * error){
        if(!error){
           
            NSString * filepath = url.path;
            NSFileManager * fm = [NSFileManager defaultManager];
            if([fm fileExistsAtPath:filepath]){
                NSLog(@"文件存在");
            }
            if([fm fileExistsAtPath:url.absoluteString]){
                NSLog(@"url文件存在");
            }

            NSData * fileData = [NSData dataWithContentsOfFile:[url path]];
            NSLog(@"现在 %@ 文件下载完成 ,url: %@ , path: %@ error: %@ filesize: %ld",fileUrl,url,url,error,fileData.length);
            
            if(self.delegate !=nil)
            {
                [self.delegate DownloadSuccess:filepath];
            }
        }else{
            NSLog(@"现在 %@ 文件下载失败,url: %@ , error: %@",fileUrl,url,error);
            if(self.delegate !=nil)
            {
                [self.delegate DownloadError];
            }
        }
    }];
    [downTask addObserver:self forKeyPath:@"progress.fractionCompleted" options:NSKeyValueObservingOptionNew context:(__bridge  void * _Nullable)(fileUrl)];
    [downTask resume];
}

-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context{
    if(self.delegate !=nil)
    {
        NSNumber * num = change[@"new"];
        [self.delegate ReceivePercent:num];
    }
}


@end
