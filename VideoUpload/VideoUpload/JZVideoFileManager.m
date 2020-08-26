//
//  JZVideoFileManager.m
//  VideoUpload
//
//  Created by 徐慈 on 2020/8/24.
//  Copyright © 2020 徐慈. All rights reserved.
//

#import "JZVideoFileManager.h"
#import <CommonCrypto/CommonDigest.h>

@implementation JZVideoFileManager

+ (long long)getFileSize:(NSString *)path{
    unsigned long long fileLength = 0;
    NSNumber *fileSize;
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSDictionary *fileAttributes = [fileManager attributesOfItemAtPath:path error:nil];
    if ((fileSize = [fileAttributes objectForKey:NSFileSize])) {
        fileLength = [fileSize unsignedLongLongValue]; //单位是 B
    }
    return fileLength;
}

+ (NSUInteger)getFilePiece:(NSString *)path {
    if (![self checkFileExist:path]) {
        return 0;
    }
    long long fileSize = [self getFileSize:path];
    return fileSize % kVideoPieceSize == 0 ? fileSize / kVideoPieceSize : fileSize / kVideoPieceSize + 1;
}

+ (BOOL)checkFileExist:(NSString *)path {
    if (path == nil || path == NULL || path.length == 0) {
        return NO;
    }

    return [[NSFileManager defaultManager] fileExistsAtPath:path];
}

+ (NSData *)getUnuploadedPiece:(NSString *)path currIndex:(NSUInteger)index {
    NSFileHandle *readHandle = [NSFileHandle fileHandleForReadingAtPath:path];
    if (readHandle) {
        [readHandle seekToFileOffset:kVideoPieceSize * index];
        NSData *data = [readHandle readDataOfLength:kVideoPieceSize];
        [readHandle closeFile];
        
        return data;
    }
    return [NSData data];
}

+ (void)copyFileFromPath:(NSString *)path1 toPath:(NSString *)path2 {
    NSFileHandle * fh1 = [NSFileHandle fileHandleForReadingAtPath:path1];//读到内存
    [[NSFileManager defaultManager] createFileAtPath:path2 contents:nil attributes:nil];//写之前必须有该文件
    NSFileHandle * fh2 = [NSFileHandle fileHandleForWritingAtPath:path2];//写到文件
    NSData * _data = nil;
    unsigned long long ret = [fh1 seekToEndOfFile];
   if (ret < 1024 * 1024 * 5) {
       [fh1 seekToFileOffset:0];
        _data = [fh1 readDataToEndOfFile];
       [fh2 writeData:_data];
    }else{
        NSUInteger n = ret / (1024 * 1024 * 5);
        if (ret % (1024 * 1024 * 5) != 0) {
            n++;
        }
        NSUInteger offset = 0;
        NSUInteger size = 1024 * 1024 * 5;
        for (NSUInteger i = 0; i < n - 1; i++) {
            [fh1 seekToFileOffset:offset];
            @autoreleasepool {
                _data = [fh1 readDataOfLength:size];
                [fh2 seekToEndOfFile];
                [fh2 writeData:_data];
            }
            offset += size;
        }
        [fh1 seekToFileOffset:offset];
        _data = [fh1 readDataToEndOfFile];
        [fh2 seekToEndOfFile];
        [fh2 writeData:_data];
    }
    [fh1 closeFile];
    [fh2 closeFile];
}

+ (void)deleteFile:(NSString *)path {
    if (![[NSFileManager defaultManager] fileExistsAtPath:path]) {
        return;
    }
    BOOL res = [[NSFileManager defaultManager] removeItemAtPath:path error:nil];
    if (res) {
        NSLog(@"文件删除成功");
    }else
        NSLog(@"文件删除失败");
}

+ (NSString *)getFileMD5WithPath:(NSString *)path {
    if (![self checkFileExist:path]) {
        return @"file not exist!!!";
    }
    return (__bridge_transfer NSString *)FileMD5HashCreateWithPath((__bridge CFStringRef)path, FileHashDefaultChunkSizeForReadingData);
}

CFStringRef FileMD5HashCreateWithPath(CFStringRef filePath,size_t chunkSizeForReadingData) {
    // Declare needed variables
    CFStringRef result = NULL;
    CFReadStreamRef readStream = NULL;
    // Get the file URL
    CFURLRef fileURL =
    CFURLCreateWithFileSystemPath(kCFAllocatorDefault,
                                  (CFStringRef)filePath,
                                  kCFURLPOSIXPathStyle,
                                  (Boolean)false);
    if (!fileURL) goto done;
    // Create and open the read stream
    readStream = CFReadStreamCreateWithFile(kCFAllocatorDefault,
                                            (CFURLRef)fileURL);
    if (!readStream) goto done;
    bool didSucceed = (bool)CFReadStreamOpen(readStream);
    if (!didSucceed) goto done;
    // Initialize the hash object
    CC_MD5_CTX hashObject;
    CC_MD5_Init(&hashObject);
    // Make sure chunkSizeForReadingData is valid
    if (!chunkSizeForReadingData) {
        chunkSizeForReadingData = FileHashDefaultChunkSizeForReadingData;
    }
    // Feed the data to the hash object
    bool hasMoreData = true;
    while (hasMoreData) {
        uint8_t buffer[chunkSizeForReadingData];
        CFIndex readBytesCount = CFReadStreamRead(readStream,(UInt8 *)buffer,(CFIndex)sizeof(buffer));
        if (readBytesCount == -1) break;
        if (readBytesCount == 0) {
            hasMoreData = false;
            continue;
        }
        CC_MD5_Update(&hashObject,(const void *)buffer,(CC_LONG)readBytesCount);
    }
    // Check if the read operation succeeded
    didSucceed = !hasMoreData;
    // Compute the hash digest
    unsigned char digest[CC_MD5_DIGEST_LENGTH];
    CC_MD5_Final(digest, &hashObject);
    // Abort if the read operation failed
    if (!didSucceed) goto done;
    // Compute the string result
    char hash[2 * sizeof(digest) + 1];
    for (size_t i = 0; i < sizeof(digest); ++i) {
        snprintf(hash + (2 * i), 3, "%02x", (int)(digest[i]));
    }
    result = CFStringCreateWithCString(kCFAllocatorDefault,(const char *)hash,kCFStringEncodingUTF8);
done:
    if (readStream) {
        CFReadStreamClose(readStream);
        CFRelease(readStream);
    }
    if (fileURL) {
        CFRelease(fileURL);
    }
    
    return result;
    
}


@end
