//
//  BINFileProcess.h
//  CarLinkChannel
//
//  Created by 刘润泽 on 2024/9/24.
//

#import <Foundation/Foundation.h>
#import "LicenseKeyManager.h"
NS_ASSUME_NONNULL_BEGIN

@interface BINFileProcess : NSObject
-(void)loadBinaryFile:(NSString *)Vin :(NSArray *)SvtMsg :(void(^)(NSString *))doneBlock withErrorBlock:(void(^)(NSError*))errorBlock;
-(BOOL)RegisterVinAndBINNameToServer:(NSString *)Vin BinName:(NSString *)fileName;
@end

NS_ASSUME_NONNULL_END
