//
//  JZVideoFile.h
//  VideoUpload
//
//  Created by 徐慈 on 2020/8/26.
//  Copyright © 2020 徐慈. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface JZVideoFile : NSObject

@property (strong, nonatomic) NSData *pieceData;//视频切片后数据
@property (strong, nonatomic) NSString *busno;//业务号
@property (strong, nonatomic) NSString *name;//视频名字
@property (strong, nonatomic) NSString *filemd5;//文件 md5
@property (assign, nonatomic) NSUInteger chunk;//文件切片位置
@property (assign, nonatomic) NSUInteger chunks;//文件总切片数

@end

NS_ASSUME_NONNULL_END


//@{@"busno":busNo, @"name":@"张涛的小视频", @"chunk":@(chunk), @"chunks":@(self.totalPiece), @"filemd5":self.fileMd5}
