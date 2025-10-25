//
//  TCUAPIUsageExample.m
//  ZD8-TCU 新API使用示例
//
//  Created on 2025/10/24.
//  演示如何使用新的API层
//

#import "TCUAPIService.h"
#import "TCUAPIConfig.h"

/**
 * 这个文件仅用于演示，不是实际的ViewController
 * 展示了如何在你的代码中调用新API
 */

#pragma mark - 示例1: 初始化和配置SSL

void example_setupSSL(void) {
    // 在AppDelegate或首次使用前配置SSL
    TCUAPIService *api = [TCUAPIService sharedService];
    
    BOOL success = [api setupSSLWithCertName:CLIENT_CERT_FILENAME
                                    password:CLIENT_CERT_PASSWORD];
    
    if (success) {
        NSLog(@"✅ SSL配置成功，可以开始使用API");
    } else {
        NSLog(@"❌ SSL配置失败，请检查证书文件");
    }
}

#pragma mark - 示例2: 验证激活码

void example_validateLicense(void) {
    NSString *vin = @"WBA12345678901234";
    NSString *license = @"ABC-123-XYZ";
    NSString *hwid = [TCUAPIService getDeviceHWID];
    
    [[TCUAPIService sharedService] validateLicenseWithVIN:vin
                                                   license:license
                                                      hwid:hwid
                                                completion:^(TCULicenseValidateResponse *response, NSError *error) {
        
        if (error) {
            NSLog(@"❌ 激活验证失败: %@", error.localizedDescription);
            return;
        }
        
        if (response.isSuccess) {
            if (response.isActivated) {
                NSLog(@"✅ 车辆已激活");
                NSLog(@"激活时间: %@", response.activatedAt);
                NSLog(@"剩余激活次数: %ld", (long)response.remainingActivations);
                
                // 继续后续流程...
            } else {
                NSLog(@"⚠️ 车辆未激活");
            }
        } else {
            NSLog(@"❌ 验证失败: %@", response.message);
        }
    }];
}

#pragma mark - 示例3: 获取文件列表

void example_fetchFileList(void) {
    NSString *vin = @"WBA12345678901234";
    NSString *license = @"ABC-123-XYZ";
    NSString *appSha256 = [TCUAPIService calculateAppSHA256];
    
    [[TCUAPIService sharedService] fetchFileListWithVIN:vin
                                                 license:license
                                           programSha256:appSha256
                                              completion:^(TCUFileListResponse *response, NSError *error) {
        
        if (error) {
            NSLog(@"❌ 获取文件列表失败: %@", error.localizedDescription);
            return;
        }
        
        if (response.isSuccess) {
            NSLog(@"✅ 获取到 %ld 个文件夹", (long)response.folders.count);
            
            for (TCUFolderInfo *folder in response.folders) {
                NSLog(@"📁 %@ - %@", folder.folderName, folder.displayContent);
            }
            
            // 可以用这些数据更新UI（例如UITableView）
            
        } else {
            NSLog(@"❌ 获取失败: %@", response.message);
        }
    }];
}

#pragma mark - 示例4: 下载文件

void example_downloadFile(void) {
    NSString *vin = @"WBA12345678901234";
    NSString *license = @"ABC-123-XYZ";
    NSString *folderName = @"Stage 1";  // 从文件列表中选择的
    NSString *appSha256 = [TCUAPIService calculateAppSHA256];
    
    [[TCUAPIService sharedService] downloadFileWithVIN:vin
                                                license:license
                                             folderName:folderName
                                          programSha256:appSha256
                                          progressBlock:^(CGFloat progress) {
        
        // 更新下载进度UI
        NSLog(@"⬇️ 下载进度: %.1f%%", progress * 100);
        
        dispatch_async(dispatch_get_main_queue(), ^{
            // 更新进度条
            // self.progressView.progress = progress;
        });
        
    } completion:^(NSData *fileData, NSString *fileName, NSError *error) {
        
        if (error) {
            NSLog(@"❌ 下载失败: %@", error.localizedDescription);
            return;
        }
        
        NSLog(@"✅ 下载完成: %@ (%.2f MB)", fileName, fileData.length / 1024.0 / 1024.0);
        
        // 保存文件到本地
        NSString *documentsPath = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,
                                                                      NSUserDomainMask,
                                                                      YES).firstObject;
        NSString *filePath = [documentsPath stringByAppendingPathComponent:fileName];
        
        BOOL success = [fileData writeToFile:filePath atomically:YES];
        if (success) {
            NSLog(@"💾 文件已保存: %@", filePath);
            // 继续处理文件...
        }
    }];
}

#pragma mark - 示例5: 完整流程

void example_completeFlow(void) {
    // 第一步: 验证激活
    NSString *vin = @"WBA12345678901234";
    NSString *license = @"ABC-123-XYZ";
    NSString *hwid = [TCUAPIService getDeviceHWID];
    
    [[TCUAPIService sharedService] validateLicenseWithVIN:vin
                                                   license:license
                                                      hwid:hwid
                                                completion:^(TCULicenseValidateResponse *validateResp, NSError *error) {
        
        if (error || !validateResp.isSuccess || !validateResp.isActivated) {
            NSLog(@"❌ 激活验证失败");
            return;
        }
        
        NSLog(@"✅ 步骤1: 激活验证通过");
        
        // 第二步: 获取文件列表
        NSString *appSha256 = [TCUAPIService calculateAppSHA256];
        
        [[TCUAPIService sharedService] fetchFileListWithVIN:vin
                                                     license:license
                                               programSha256:appSha256
                                                  completion:^(TCUFileListResponse *listResp, NSError *error) {
            
            if (error || !listResp.isSuccess) {
                NSLog(@"❌ 获取文件列表失败");
                return;
            }
            
            NSLog(@"✅ 步骤2: 获取到 %ld 个文件", (long)listResp.folders.count);
            
            // 第三步: 下载第一个文件（实际应该由用户选择）
            if (listResp.folders.count > 0) {
                TCUFolderInfo *firstFolder = listResp.folders.firstObject;
                
                [[TCUAPIService sharedService] downloadFileWithVIN:vin
                                                            license:license
                                                         folderName:firstFolder.folderName
                                                      programSha256:appSha256
                                                      progressBlock:^(CGFloat progress) {
                    NSLog(@"⬇️ 下载进度: %.1f%%", progress * 100);
                }
                                                         completion:^(NSData *data, NSString *fileName, NSError *error) {
                    
                    if (error || !data) {
                        NSLog(@"❌ 下载失败");
                        return;
                    }
                    
                    NSLog(@"✅ 步骤3: 下载完成");
                    NSLog(@"🎉 完整流程成功！可以开始刷写操作");
                    
                    // 继续刷写流程...
                }];
            }
        }];
    }];
}

#pragma mark - 示例6: 错误处理

void example_errorHandling(void) {
    NSString *vin = @"WBA12345678901234";
    NSString *license = @"ABC-123-XYZ";
    NSString *hwid = [TCUAPIService getDeviceHWID];
    
    [[TCUAPIService sharedService] validateLicenseWithVIN:vin
                                                   license:license
                                                      hwid:hwid
                                                completion:^(TCULicenseValidateResponse *response, NSError *error) {
        
        if (error) {
            // 网络错误或其他系统错误
            NSLog(@"系统错误: %@", error.localizedDescription);
            
            switch (error.code) {
                case TCUErrorCodeNetworkError:
                    // 提示用户检查网络
                    break;
                case TCUErrorCodeSSLError:
                    // SSL配置问题
                    break;
                case TCUErrorCodeCertificateNotFound:
                    // 证书文件丢失
                    break;
                default:
                    break;
            }
            return;
        }
        
        if (!response.isSuccess) {
            // API业务错误
            NSLog(@"API错误: %@ (code=%ld)", response.message, (long)response.errorCode);
            
            switch (response.errorCode) {
                case TCUErrorCodeInvalidLicenseCode:
                    // 激活码无效
                    NSLog(@"激活码无效，请检查");
                    break;
                    
                case TCUErrorCodeLicenseCodeExpired:
                    // 激活码已过期
                    NSLog(@"激活码已过期");
                    break;
                    
                case TCUErrorCodeVehicleAlreadyBound:
                    // 车辆已绑定其他设备
                    NSLog(@"车辆已绑定到其他设备");
                    break;
                    
                case TCUErrorCodeFileNotFound:
                    // 文件未找到
                    NSLog(@"文件不存在");
                    break;
                    
                default:
                    NSLog(@"未知错误: %ld", (long)response.errorCode);
                    break;
            }
        }
    }];
}
