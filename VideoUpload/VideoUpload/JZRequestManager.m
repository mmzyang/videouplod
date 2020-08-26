//
//  JZRequestManager.m
//  VideoUpload
//
//  Created by 徐慈 on 2020/8/24.
//  Copyright © 2020 徐慈. All rights reserved.
//

#import "JZRequestManager.h"
#import <AFNetworking/AFNetworking.h>
#import "JZVideoFileManager.h"

//const static NSString *kCurrentBaseURL = @"http://192.168.8.231:7004/agate/";
const static NSString *kCurrentBaseURL = @"http://192.168.8.104:8090/agate_xsxt/";

@interface JZRequestManager ()
@property (strong,nonatomic) AFHTTPSessionManager *manager;

@end

@implementation JZRequestManager

+ (JZRequestManager *)shared {
    static dispatch_once_t onceToken;
    static JZRequestManager *tools = nil;
    dispatch_once(&onceToken, ^{
        if (tools == nil) {
            tools = [[JZRequestManager alloc] init];
        }
    });
    return tools;
}

- (instancetype)init{
    if (self = [super init]) {
        _manager = [AFHTTPSessionManager manager];
        _manager.requestSerializer = [AFJSONRequestSerializer serializer];
        _manager.responseSerializer = [AFJSONResponseSerializer serializer];
        [_manager.requestSerializer setTimeoutInterval:30];
        [_manager.requestSerializer setValue:@"multipart/form-data" forHTTPHeaderField:@"Content-Type"];
        _manager.responseSerializer.acceptableContentTypes = [NSSet setWithObjects:@"application/json", @"text/json", @"text/plain",  @"text/javascript", @"text/html",@"text/xml", nil];
    }
    return self;
}

+ (void)upload:(NSString *)code param:(NSDictionary *)param path:(NSString *)path success:(nonnull void (^)(id _Nonnull))success error:(nonnull void (^)(NSError * _Nonnull))fail {
    NSString *url = [NSString stringWithFormat:@"%@%@.do", kCurrentBaseURL, code];
    [[JZRequestManager shared].manager POST:url parameters:param constructingBodyWithBlock:^(id<AFMultipartFormData>  _Nonnull formData) {
        NSData *pieceData = [JZVideoFileManager getUnuploadedPiece:path currIndex:[param[@"chunk"] intValue] - 1];
        [formData appendPartWithFileData:pieceData name:param[@"name"] fileName:param[@"name"] mimeType:@"multipart/form-data"];
    } progress:^(NSProgress * _Nonnull uploadProgress) {
//        NSLog(@"%@", uploadProgress);
    } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        if (success) {
            success(responseObject);
        } else {
            NSLog(@"%@", responseObject[@"retMsg"]);
        }
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        if (fail) {
            fail(error);
        }
    }];
}

+ (void)upload:(NSString *)code file:(JZVideoFile *)file success:(void(^)(id))success fail:(void(^)(NSError *))fail {
    NSString *url = [NSString stringWithFormat:@"%@%@.do", kCurrentBaseURL, code];
    NSDictionary *param = @{@"busno":file.busno, @"name":file.name, @"chunk":@(file.chunk), @"chunks":@(file.chunks), @"filemd5":file.filemd5};
    [[JZRequestManager shared].manager POST:url parameters:param constructingBodyWithBlock:^(id<AFMultipartFormData>  _Nonnull formData) {
        [formData appendPartWithFileData:file.pieceData name:file.name fileName:file.name mimeType:@"multipart/form-data"];
    } progress:^(NSProgress * _Nonnull uploadProgress) {
        
    } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        if (success) {
             success(responseObject);
         } else {
             NSLog(@"%@", responseObject[@"retMsg"]);
         }
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        if (fail) {
            fail(error);
        }
    }];
}

+ (void)qryVideoInfo:(NSString *)code param:(NSDictionary *)param success:(void (^)(id _Nonnull))success error:(void (^)(NSError * _Nonnull))fail {
    NSString *url = [NSString stringWithFormat:@"%@%@.do", kCurrentBaseURL, code];
    [[JZRequestManager shared].manager GET:url parameters:param progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        NSLog(@"成功  %@", responseObject);
        if ([responseObject[@"retCode"] isEqualToString:@"0"]) {
            if (success) {
                success(responseObject);
            }
        } else {
            NSLog(@"%@", responseObject[@"retMsg"]);
        }
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        if (fail) {
            fail(error);
        }
    }];
}

@end
