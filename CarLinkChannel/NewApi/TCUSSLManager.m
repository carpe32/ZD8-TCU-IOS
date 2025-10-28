//
//  TCUSSLManager.m
//  ZD8-TCU
//
//  SSL证书管理器 - 修复版本
//

#import "TCUSSLManager.h"

// 日志宏
#define TCUSSLLog(fmt, ...) NSLog(@"[TCU-SSL] " fmt, ##__VA_ARGS__)
#define TCUSSLLogError(fmt, ...) NSLog(@"[TCU-SSL ERROR] " fmt, ##__VA_ARGS__)

@interface TCUSSLManager ()

@property (nonatomic, readwrite) SecCertificateRef certificate;
@property (nonatomic, readwrite) SecIdentityRef identity;

// 私有方法声明
- (void)logImportError:(OSStatus)status;
- (void)logCertificateInfo:(SecCertificateRef)certificate;

@end

@implementation TCUSSLManager

- (void)dealloc {
    [self clearCertificate];
}

#pragma mark - Certificate Loading

- (BOOL)loadCertificateFromP12:(NSString *)certName password:(NSString *)password {
    
    TCUSSLLog(@"========== 开始加载SSL证书 ==========");
    TCUSSLLog(@"证书文件: %@.p12", certName);
    
    // 1. 清除旧证书
    [self clearCertificate];
    
    // 2. 从Bundle加载.p12文件
    NSString *p12Path = [[NSBundle mainBundle] pathForResource:certName ofType:@"p12"];
    if (!p12Path) {
        TCUSSLLogError(@"❌ 未找到证书文件: %@.p12", certName);
        TCUSSLLogError(@"   请确认文件已添加到项目并包含在Target中");
        return NO;
    }
    
    TCUSSLLog(@"✓ 证书文件路径: %@", p12Path);
    
    // 3. 读取文件数据
    NSData *p12Data = [NSData dataWithContentsOfFile:p12Path];
    if (!p12Data || p12Data.length == 0) {
        TCUSSLLogError(@"❌ 无法读取证书文件或文件为空");
        return NO;
    }
    
    TCUSSLLog(@"✓ 证书文件大小: %lu bytes", (unsigned long)p12Data.length);
    
    // 4. 准备导入选项
    NSDictionary *options = @{
        (__bridge id)kSecImportExportPassphrase: password
    };
    
    // 5. 导入PKCS12数据
    CFArrayRef items = NULL;
    OSStatus status = SecPKCS12Import((__bridge CFDataRef)p12Data,
                                     (__bridge CFDictionaryRef)options,
                                     &items);
    
    if (status != errSecSuccess) {
        TCUSSLLogError(@"❌ 证书导入失败，错误码: %d", (int)status);
        [self logImportError:status];
        return NO;
    }
    
    TCUSSLLog(@"✓ PKCS12导入成功");
    
    // 6. 提取身份和证书
    if (!items || CFArrayGetCount(items) == 0) {
        TCUSSLLogError(@"❌ 证书文件中没有有效的身份信息");
        if (items) CFRelease(items);
        return NO;
    }
    
    CFDictionaryRef identityDict = CFArrayGetValueAtIndex(items, 0);
    
    // 提取身份（包含私钥）
    SecIdentityRef identity = (SecIdentityRef)CFDictionaryGetValue(identityDict,
                                                                    kSecImportItemIdentity);
    if (!identity) {
        TCUSSLLogError(@"❌ 无法从证书中提取身份信息");
        CFRelease(items);
        return NO;
    }
    
    TCUSSLLog(@"✓ 身份提取成功");
    
    // 提取证书
    SecCertificateRef certificate = NULL;
    status = SecIdentityCopyCertificate(identity, &certificate);
    if (status != errSecSuccess || !certificate) {
        TCUSSLLogError(@"❌ 无法从身份中提取证书");
        CFRelease(items);
        return NO;
    }
    
    TCUSSLLog(@"✓ 证书提取成功");
    
    // 7. 验证证书信息
    [self logCertificateInfo:certificate];
    
    // 8. 保存证书和身份
    _certificate = certificate; // SecIdentityCopyCertificate已增加引用计数
    _identity = identity;
    CFRetain(_identity); // 增加引用计数
    
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

- (NSURLCredential *)createCredential {
    if (![self isConfigured]) {
        TCUSSLLogError(@"❌ 证书未配置，无法创建凭据");
        return nil;
    }
    
    // ✅ 创建包含完整证书链的凭据
    NSURLCredential *credential = [NSURLCredential credentialWithIdentity:_identity
                                                             certificates:@[(__bridge id)_certificate]
                                                              persistence:NSURLCredentialPersistenceForSession];
    
    TCUSSLLog(@"✓ 创建SSL凭据成功");
    return credential;
}

#pragma mark - Private Helper Methods

- (void)logImportError:(OSStatus)status {
    switch (status) {
        case errSecAuthFailed:
            TCUSSLLogError(@"  错误: 认证失败 (errSecAuthFailed = -25293)");
            TCUSSLLogError(@"  原因: 密码错误");
            break;
            
        case errSecPkcs12VerifyFailure:
            TCUSSLLogError(@"  错误: PKCS12验证失败");
            TCUSSLLogError(@"  原因: 密码错误或文件损坏");
            break;
            
        case errSecDecode:
            TCUSSLLogError(@"  错误: 解码失败");
            TCUSSLLogError(@"  原因: 文件格式错误");
            break;
            
        default:
            TCUSSLLogError(@"  错误码: %d", (int)status);
            break;
    }
    
    TCUSSLLogError(@"💡 排查建议:");
    TCUSSLLogError(@"  1. 确认密码: Q1w2e3r4@#$");
    TCUSSLLogError(@"  2. 确认证书文件: CLIENT-IOS-001.p12");
    TCUSSLLogError(@"  3. 确认文件已添加到Target");
}

- (void)logCertificateInfo:(SecCertificateRef)certificate {
    if (!certificate) {
        return;
    }
    
    TCUSSLLog(@"========== 证书详细信息 ==========");
    
    // Subject (CN)
    CFStringRef certSummary = SecCertificateCopySubjectSummary(certificate);
    if (certSummary) {
        NSString *summary = (__bridge_transfer NSString *)certSummary;
        TCUSSLLog(@"✓ 证书CN: %@", summary);
        
        // 检查CN格式
        if ([summary hasPrefix:@"CLIENT-"]) {
            TCUSSLLog(@"✓ CN格式正确（符合服务器要求）");
        } else {
            TCUSSLLogError(@"⚠️ CN格式可能不符合服务器要求");
            TCUSSLLogError(@"  服务器要求CN以 CLIENT- 开头");
            TCUSSLLogError(@"  当前CN: %@", summary);
        }
    }
    
    // 证书数据大小
    CFDataRef certData = SecCertificateCopyData(certificate);
    if (certData) {
        TCUSSLLog(@"✓ 证书数据大小: %ld bytes", CFDataGetLength(certData));
        CFRelease(certData);
    }
    
    TCUSSLLog(@"=====================================");
}

@end
