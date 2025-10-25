//
//  TCUSSLManager.h
//  ZD8-TCU
//
//  SSL证书管理器
//

#import <Foundation/Foundation.h>
#import <Security/Security.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * SSL证书管理器
 * 负责加载和管理客户端SSL证书
 */
@interface TCUSSLManager : NSObject

#pragma mark - Properties

/**
 * 客户端证书
 */
@property (nonatomic, readonly, nullable) SecCertificateRef certificate;

/**
 * 客户端身份（证书+私钥）
 */
@property (nonatomic, readonly, nullable) SecIdentityRef identity;

#pragma mark - Methods

/**
 * 从.p12文件加载证书
 * @param certName 证书文件名（不含.p12后缀）
 * @param password 证书密码
 * @return YES表示加载成功，NO表示失败
 */
- (BOOL)loadCertificateFromP12:(NSString *)certName password:(NSString *)password;

/**
 * 检查证书是否已加载
 * @return YES表示证书已配置
 */
- (BOOL)isConfigured;

/**
 * 清除已加载的证书
 */
- (void)clearCertificate;

@end

NS_ASSUME_NONNULL_END
