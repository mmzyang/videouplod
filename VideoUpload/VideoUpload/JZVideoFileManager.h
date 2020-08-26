//
//  JZVideoFileManager.h
//  VideoUpload
//
//  Created by 徐慈 on 2020/8/24.
//  Copyright © 2020 徐慈. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

const static long long kVideoPieceSize = 1 * 1024 * 1024; //视频被分割后，每片的大小
const static long long  FileHashDefaultChunkSizeForReadingData = 1024 * 8;

@interface JZVideoFileManager : NSObject

+ (NSUInteger)getFilePiece:(NSString *)path; //获取视频一共可以分为多少片
+ (NSString *)getFileMD5WithPath:(NSString *)path; //获取当前视频的 md5 码
+ (NSData *)getUnuploadedPiece:(NSString *)path currIndex:(NSUInteger)index; //获取当前需要取的位置的文件数据

+ (void)copyFileFromPath:(NSString *)path1 toPath:(NSString *)path2; //文件复制
+ (void)deleteFile:(NSString *)path; //文件删除

@end

NS_ASSUME_NONNULL_END
