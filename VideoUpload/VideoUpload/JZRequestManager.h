//
//  JZRequestManager.h
//  VideoUpload
//
//  Created by 徐慈 on 2020/8/24.
//  Copyright © 2020 徐慈. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "JZVideoFile.h"

NS_ASSUME_NONNULL_BEGIN

@interface JZRequestManager : NSObject

+ (JZRequestManager *)shared;
+ (void)upload:(NSString *)code param:(NSDictionary *)param path:(NSString *)path success:(void(^)(id))success error:(void(^)(NSError *))fail;//上传视频
+ (void)qryVideoInfo:(NSString *)code param:(NSDictionary *)param  success:(void(^)(id))success error:(void(^)(NSError *))fail;//查询视频信息
+ (void)upload:(NSString *)code file:(JZVideoFile *)file success:(void(^)(id))success fail:(void(^)(NSError *))fail;

@end

NS_ASSUME_NONNULL_END
