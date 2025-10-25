//
//  TCUSSLManager.m
//  ZD8-TCU
//
//  SSL证书管理器实现
//

#import "TCUSSLManager.h"

// 日志宏
#define TCUSSLLog(fmt, ...) NSLog(@"[TCU-SSL] " fmt, ##__VA_ARGS__)
#define TCUSSLLogError(fmt, ...) NSLog(@"[TCU-SSL ERROR] " fmt, ##__VA_ARGS__)

@interface TCUSSLManager ()

@property (nonatomic, assign) SecCertificateRef certificate;
@property (nonatomic, assign) SecIdentityRef identity;

@end

@implementation TCUSSLManager

#pragma mark - Lifecycle

- (instancetype)init {
    self = [super init];
    if (self) {
        _certificate = NULL;
        _identity = NULL;
    }
    return self;
}

- (void)dealloc {
    [self clearCertificate];
}

#pragma mark - Public Methods

- (BOOL)loadCertificateFromP12:(NSString *)certName password:(NSString *)password {
    
    TCUSSLLog(@"========== 开始加载SSL证书 ==========");
    TCUSSLLog(@"证书名称: %@", certName);
    TCUSSLLog(@"密码长度: %lu", (unsigned long)password.length);
    
    // 清除旧证书
    [self clearCertificate];
    
    // 1. 查找证书文件
    NSString *p12Path = [[NSBundle mainBundle] pathForResource:certName ofType:@"p12"];
    
    if (!p12Path) {
        TCUSSLLogError(@"❌ 找不到证书文件: %@.p12", certName);
        TCUSSLLogError(@"Bundle路径: %@", [[NSBundle mainBundle] bundlePath]);
        
        // 列出所有.p12文件
        NSArray *p12Files = [[NSBundle mainBundle] pathsForResourcesOfType:@"p12" inDirectory:nil];
        TCUSSLLogError(@"Bundle中的.p12文件数量: %lu", (unsigned long)p12Files.count);
        for (NSString *file in p12Files) {
            TCUSSLLogError(@"  - %@", [file lastPathComponent]);
        }
        
        return NO;
    }
    
    TCUSSLLog(@"✓ 找到证书文件: %@", p12Path);
    
    // 2. 读取证书数据
    NSData *p12Data = [NSData dataWithContentsOfFile:p12Path];
    if (!p12Data) {
        TCUSSLLogError(@"❌ 无法读取证书文件");
        return NO;
    }
    
    TCUSSLLog(@"✓ 证书数据大小: %lu bytes", (unsigned long)p12Data.length);
    
    // 打印文件头（用于验证文件格式）
    if (p12Data.length >= 4) {
        const unsigned char *bytes = [p12Data bytes];
        TCUSSLLog(@"✓ 文件头: %02X %02X %02X %02X", bytes[0], bytes[1], bytes[2], bytes[3]);
        // PKCS#12 文件通常以 30 82 开头
    }
    
    // 3. 准备导入选项
    NSDictionary *options = @{
        (__bridge id)kSecImportExportPassphrase: password
    };
    
    TCUSSLLog(@"开始导入证书...");
    
    // 4. 导入证书
    CFArrayRef items = NULL;
    OSStatus status = SecPKCS12Import((__bridge CFDataRef)p12Data,
                                     (__bridge CFDictionaryRef)options,
                                     &items);
    
    TCUSSLLog(@"导入状态: OSStatus=%d", (int)status);
    
    if (status != errSecSuccess) {
        TCUSSLLogError(@"❌ 证书导入失败: OSStatus=%d", (int)status);
        
        // 详细的错误信息
        [self logImportError:status];
        
        return NO;
    }
    
    TCUSSLLog(@"✓ 证书导入成功");
    
    // 5. 提取身份和证书
    if (!items || CFArrayGetCount(items) == 0) {
        TCUSSLLogError(@"❌ 导入结果为空");
        if (items) CFRelease(items);
        return NO;
    }
    
    TCUSSLLog(@"✓ 导入结果数量: %ld", (long)CFArrayGetCount(items));
    
    NSDictionary *identityDict = (__bridge NSDictionary *)CFArrayGetValueAtIndex(items, 0);
    
    // 提取身份
    SecIdentityRef identity = (__bridge SecIdentityRef)identityDict[(__bridge id)kSecImportItemIdentity];
    
    if (!identity) {
        TCUSSLLogError(@"❌ 无法提取身份");
        CFRelease(items);
        return NO;
    }
    
    TCUSSLLog(@"✓ 成功提取身份");
    
    // 提取证书
    SecCertificateRef certificate = NULL;
    OSStatus certStatus = SecIdentityCopyCertificate(identity, &certificate);
    
    if (certStatus != errSecSuccess || !certificate) {
        TCUSSLLogError(@"❌ 无法提取证书: OSStatus=%d", (int)certStatus);
        CFRelease(items);
        return NO;
    }
    
    TCUSSLLog(@"✓ 成功提取证书");
    
    // 6. 打印证书详细信息
    [self logCertificateInfo:certificate];
    
    // 7. 保存证书和身份
    _certificate = certificate; // SecIdentityCopyCertificate 已经增加了引用计数
    _identity = identity;
    CFRetain(_identity); // 增加引用计数，防止被释放
    
    // 释放导入结果
    CFRelease(items);
    
    TCUSSLLog(@"========== SSL证书加载完成 ==========");
    
    return YES;
}

- (BOOL)isConfigured {
    return (_certificate != NULL && _identity != NULL);
}

- (void)clearCertificate {
    if (_certificate) {
        CFRelease(_certificate);
        _certificate = NULL;
    }
    
    if (_identity) {
        CFRelease(_identity);
        _identity = NULL;
    }
    
    TCUSSLLog(@"✓ 证书已清除");
}

#pragma mark - Private Helper Methods

- (void)logImportError:(OSStatus)status {
    switch (status) {
        case errSecAuthFailed:
            TCUSSLLogError(@"  错误类型: 认证失败 (errSecAuthFailed = -25293)");
            TCUSSLLogError(@"  可能原因: 密码错误");
            break;
            
        case errSecPkcs12VerifyFailure:
            TCUSSLLogError(@"  错误类型: PKCS12验证失败");
            TCUSSLLogError(@"  可能原因: 密码错误或文件损坏");
            break;
            
        case errSecDecode:
            TCUSSLLogError(@"  错误类型: 解码失败 (errSecDecode)");
            TCUSSLLogError(@"  可能原因: 文件格式错误，可能不是有效的.p12文件");
            break;
            
        case errSecParam:
            TCUSSLLogError(@"  错误类型: 参数错误 (errSecParam)");
            TCUSSLLogError(@"  可能原因: 传入的参数无效");
            break;
            
        case errSecUnimplemented:
            TCUSSLLogError(@"  错误类型: 功能未实现 (errSecUnimplemented)");
            break;
            
        case errSecIO:
            TCUSSLLogError(@"  错误类型: I/O错误 (errSecIO)");
            TCUSSLLogError(@"  可能原因: 文件读取失败");
            break;
            
        default:
            TCUSSLLogError(@"  错误类型: 未知错误 (code=%d)", (int)status);
            break;
    }
    
    TCUSSLLogError(@"💡 排查建议:");
    TCUSSLLogError(@"  1. 确认密码是否正确");
    TCUSSLLogError(@"  2. 确认证书文件是否完整");
    TCUSSLLogError(@"  3. 尝试重新生成证书");
    TCUSSLLogError(@"  4. 确认证书格式为PKCS#12 (.p12)");
}

- (void)logCertificateInfo:(SecCertificateRef)certificate {
    if (!certificate) {
        return;
    }
    
    TCUSSLLog(@"========== 证书详细信息 ==========");
    
    // 1. Subject (CN)
    CFStringRef certSummary = SecCertificateCopySubjectSummary(certificate);
    if (certSummary) {
        NSString *summary = (__bridge_transfer NSString *)certSummary;
        TCUSSLLog(@"✓ 证书 CN (Subject): %@", summary);
        
        // 检查CN格式
        if ([summary hasPrefix:@"CLIENT-"]) {
            TCUSSLLog(@"✓ CN格式正确（符合服务器要求）");
        } else {
            TCUSSLLogError(@"⚠️ CN格式可能不符合服务器要求");
            TCUSSLLogError(@"  服务器要求CN以 CLIENT- 开头");
            TCUSSLLogError(@"  当前CN: %@", summary);
        }
    }
    
    // 2. 证书数据
    CFDataRef certData = SecCertificateCopyData(certificate);
    if (certData) {
        NSData *data = (__bridge_transfer NSData *)certData;
        TCUSSLLog(@"✓ 证书数据大小: %lu bytes", (unsigned long)data.length);
    }
    
    // 3. 尝试获取更多信息（需要使用私有API或解析证书数据）
    // 这里只打印基础信息
    
    TCUSSLLog(@"====================================");
}

#pragma mark - Debug Methods

- (void)printBundleCertificates {
    TCUSSLLog(@"========== Bundle中的证书文件 ==========");
    
    NSString *bundlePath = [[NSBundle mainBundle] bundlePath];
    TCUSSLLog(@"Bundle路径: %@", bundlePath);
    
    NSArray *p12Files = [[NSBundle mainBundle] pathsForResourcesOfType:@"p12" inDirectory:nil];
    
    if (p12Files.count == 0) {
        TCUSSLLogError(@"❌ Bundle中没有找到.p12文件");
        TCUSSLLogError(@"请确认:");
        TCUSSLLogError(@"  1. 证书文件已添加到项目");
        TCUSSLLogError(@"  2. 勾选了Target");
        TCUSSLLogError(@"  3. 在Copy Bundle Resources中");
    } else {
        TCUSSLLog(@"✓ 找到 %lu 个.p12文件:", (unsigned long)p12Files.count);
        
        for (NSString *file in p12Files) {
            NSString *fileName = [file lastPathComponent];
            NSData *data = [NSData dataWithContentsOfFile:file];
            
            TCUSSLLog(@"  - %@", fileName);
            TCUSSLLog(@"    路径: %@", file);
            TCUSSLLog(@"    大小: %lu bytes", (unsigned long)data.length);
            
            if (data.length >= 4) {
                const unsigned char *bytes = [data bytes];
                TCUSSLLog(@"    文件头: %02X %02X %02X %02X", bytes[0], bytes[1], bytes[2], bytes[3]);
            }
        }
    }
    
    TCUSSLLog(@"==========================================");
}

@end
