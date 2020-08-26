//
//  ViewController.m
//  VideoUpload
//
//  Created by 徐慈 on 2020/8/24.
//  Copyright © 2020 徐慈. All rights reserved.
//

#import "ViewController.h"
#import "JZVideoFileManager.h"
#import "JZRequestManager.h"
#import "JZVideoFile.h"
#import <Photos/Photos.h>

@interface ViewController ()<UIImagePickerControllerDelegate,UINavigationControllerDelegate>

@property (weak, nonatomic) IBOutlet UILabel *videoInfoLbl;//视频信息 label
@property (strong, nonatomic) UIImagePickerController *imagePickerController;
@property (strong, nonatomic) NSString *fileMd5; //上传视频的 md5 码
@property (strong, nonatomic) NSString *fileURL; //上传视频的路径
@property (strong, nonatomic) NSMutableArray <JZVideoFile *> *unuploadedVideos; //未上传的视频文件 model
@property (strong, nonatomic) NSMutableArray <NSString *> *unuploadedFiles; //未上传的视频文件下标
@property (assign, nonatomic) BOOL pause; //暂停/开始
@property (assign, nonatomic) NSUInteger totalPiece; //视频切分总片数
@property (assign, nonatomic) NSUInteger currentUploadIndex;//未上传视频的位置
@property (assign, nonatomic) NSUInteger competedUploadIndex;//上传完成的片数

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
//    [[NSUserDefaults standardUserDefaults] setObject:@"195401364536" forKey:@"kBusNoKey"];
//    [[NSUserDefaults standardUserDefaults] synchronize];
}


- (IBAction)videoSelect:(UIButton *)sender {
    self.imagePickerController.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    [self presentViewController:self.imagePickerController animated:YES completion:nil];
}

- (IBAction)videoUpload:(UIButton *)sender {
    NSString *urlStr = [[NSBundle mainBundle] pathForResource:@"largeFile" ofType:@"mp4"];
    self.fileURL = urlStr;
    self.totalPiece = [JZVideoFileManager getFilePiece:urlStr];
    self.fileMd5 = [JZVideoFileManager getFileMD5WithPath:urlStr];

//    [self getUploadInfo];
}

- (IBAction)pause:(UIButton *)sender {
    self.pause = !self.pause;
//    [self uploadVideoPiece:[[NSUserDefaults standardUserDefaults] objectForKey:@"kBusNoKey"]];
}

#pragma mark --- 代理方法
-(void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary<NSString *,id> *)info{
    [picker dismissViewControllerAnimated:YES completion:nil];    
    NSURL *url = info[@"UIImagePickerControllerMediaURL"];
    NSString *urlStr = url.absoluteString;
    NSString *preFix = @"file://";
    if ([urlStr hasPrefix:preFix]) {
        urlStr = [urlStr substringFromIndex:preFix.length];
    }
    
    self.totalPiece = [JZVideoFileManager getFilePiece:urlStr];
    self.fileMd5 = [JZVideoFileManager getFileMD5WithPath:urlStr];
    
    NSString *cachesDirectory = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) firstObject];
    NSString *toPath = [NSString stringWithFormat:@"%@/%@", cachesDirectory, url.lastPathComponent];
//    NSLog(@"保存到的路径为：%@", toPath);
    [JZVideoFileManager copyFileFromPath:urlStr toPath:toPath];
    self.fileURL = toPath;

    [self getHCFile];
}

- (void)getHCFile {
//        NSString *busno = [[NSUserDefaults standardUserDefaults] objectForKey:@"kBusNoKey"];
        [JZRequestManager qryVideoInfo:@"HCFile" param:@{@"busno":@"195401364536", @"chunks":@(self.totalPiece), @"filemd5":self.fileMd5} success:^(id response) {
            self.unuploadedFiles = [NSMutableArray arrayWithArray:[response[@"schunks"] componentsSeparatedByString:@","]];
            if (self.unuploadedFiles.count == 0) {
                [JZVideoFileManager deleteFile:self.fileURL];
            } else {
                self.currentUploadIndex = 0;
                self.competedUploadIndex = 0;
                [self getVideoPieceDtas];
            }
        } error:^(NSError * error) {
            
        }];
}

//- (void)uploadVideoPiece:(NSString *)busNo {
////    if (self.pause) {
////        return;
////    }
//    NSLog(@" >>>>>>>>>>>>>>>>>>>>> %lu", (unsigned long)self.currPiece);
//    NSDictionary *param = @{@"busno":busNo, @"name":@"张涛的小视频", @"chunk":@(self.currPiece), @"chunks":@(self.totalPiece), @"filemd5":self.fileMd5};
//    [JZRequestManager upload:@"uploaderWithContinuinglyTransferring" param:param path:self.fileURL success:^(id response) {
//        if (++self.currPiece <= self.totalPiece) {
//            [self uploadVideoPiece:busNo];
//        }
//    } error:^(NSError * error) {
//    }];
//}

- (void)uploadVideoPieceFile:(JZVideoFile *)file {
    if (self.pause) {
        return;
    }
    [JZRequestManager upload:@"uploaderWithContinuinglyTransferring" file:file success:^(id response) {
        NSLog(@"------------------- 第 %lu 片上传成功 -------------------", (unsigned long)file.chunk);
        self.competedUploadIndex++;
        [self mutiUpload:++self.currentUploadIndex];
    } fail:^(NSError * error) {
        NSLog(@"------------------- 第 %lu 片上传超时 -------------------", (unsigned long)file.chunk);
        self.competedUploadIndex++;
        [self mutiUpload:++self.currentUploadIndex];
    }];
}

- (void)getVideoPieceDtas {
    self.unuploadedVideos = [NSMutableArray array];
    for (NSString *index in self.unuploadedFiles) {
        NSUInteger fileIndex = [index intValue];
        NSFileHandle *readHandle = [NSFileHandle fileHandleForReadingAtPath:self.fileURL];
        if (readHandle) {
            [readHandle seekToFileOffset:kVideoPieceSize * (fileIndex - 1)];
            NSData *data = [readHandle readDataOfLength:kVideoPieceSize];
            [readHandle closeFile];
            
            JZVideoFile *file = [JZVideoFile new];
            file.busno = @"195401364536";
            file.chunk = fileIndex;
            file.chunks = self.totalPiece;
            file.name = @"张涛的小视频";
            file.filemd5 = self.fileMd5;
            file.pieceData = data;
            [self.unuploadedVideos addObject:file];
        }
    }
    [self mutiUpload:self.currentUploadIndex];
    [self mutiUpload:++self.currentUploadIndex];
    [self mutiUpload:++self.currentUploadIndex];
}

- (void)mutiUpload:(NSUInteger)index {
    NSLog(@"当前 index：%lu", (unsigned long)self.competedUploadIndex);
    if (self.competedUploadIndex == self.unuploadedFiles.count) {
        [self getHCFile];
        return;
    }
    if (index >= self.unuploadedFiles.count) {
        return;
    }
    dispatch_queue_t globalQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    dispatch_async(globalQueue, ^{
        JZVideoFile *file = self.unuploadedVideos[index];
        [self uploadVideoPieceFile:file];
    });
}

- (UIImagePickerController*) imagePickerController{
    if (_imagePickerController == nil){
        _imagePickerController = [[UIImagePickerController alloc] init];
        _imagePickerController.delegate = self;
        _imagePickerController.mediaTypes = @[@"public.movie"]; //picker中只显示视频
        _imagePickerController.modalPresentationStyle = UIModalPresentationFullScreen;
    }
    return  _imagePickerController;
}

@end
