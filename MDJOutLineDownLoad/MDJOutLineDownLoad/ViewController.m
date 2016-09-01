//
//  ViewController.m
//  MDJOutLineDownLoad
//
//  Created by MDJ on 16/9/1.
//  Copyright © 2016年 MDJ. All rights reserved.
//

#import "ViewController.h"
#import "NSString+Hash.h"


// 所需要下载的文件的URL
#define MDJFileURL @"http://120.25.226.186:32812/resources/videos/minion_01.mp4"

// 文件名（沙盒中的文件名）
#define MDJFilename MDJFileURL.md5String

// 文件的存放路径（caches）
#define MDJFileFullpath [[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject] stringByAppendingPathComponent:MDJFilename]

// 存储文件总长度的文件路径（caches）
#define MDJTotalLengthFullpath [[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject] stringByAppendingPathComponent:@"totalLength.MDJ"]

// 文件的已下载长度
#define MDJDownloadLength [[[NSFileManager defaultManager] attributesOfItemAtPath:MDJFileFullpath error:nil][NSFileSize] integerValue]


@interface ViewController () <NSURLSessionDataDelegate>

/** 下载任务 */
@property (nonatomic, strong) NSURLSessionDataTask *task;
/** session */
@property (nonatomic, strong) NSURLSession *session;
/** 写文件的流对象 */
@property (nonatomic, strong) NSOutputStream *stream;
/** 文件的总长度 */
@property (nonatomic, assign) NSInteger totalLength;
/** 进度提醒 */
@property (weak, nonatomic) IBOutlet UIProgressView *progressBar;

@end

@implementation ViewController


- (NSURLSession *)session
{
    if (!_session) {
        _session = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration] delegate:self delegateQueue:[[NSOperationQueue alloc] init]];
    }
    return _session;
}

- (NSOutputStream *)stream
{
    if (!_stream) {
        _stream = [NSOutputStream outputStreamToFileAtPath:MDJFileFullpath append:YES];
    }
    return _stream;
}

- (NSURLSessionDataTask *)task
{
    if (!_task) {
        NSInteger totalLength = [[NSDictionary dictionaryWithContentsOfFile:MDJTotalLengthFullpath][MDJFilename] integerValue];
        if (totalLength && MDJDownloadLength == totalLength) {
            NSLog(@"----文件已经下载过了");
            return nil;
        }
        
        // 创建请求
        NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:@"http://120.25.226.186:32812/resources/videos/minion_01.mp4"]];
        
        // 设置请求头
        // Range : bytes=xxx-xxx
        NSString *range = [NSString stringWithFormat:@"bytes=%zd-", MDJDownloadLength];
        [request setValue:range forHTTPHeaderField:@"Range"];
        
        // 创建一个Data任务
        _task = [self.session dataTaskWithRequest:request];
    }
    return _task;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    NSLog(@"%@", MDJFileFullpath);
}

/**
 * 开始下载
 */
- (IBAction)start:(id)sender {
    // 启动任务
    [self.task resume];
}

/**
 * 暂停下载
 */
- (IBAction)pause:(id)sender {
    [self.task suspend];
}

#pragma mark - <NSURLSessionDataDelegate>
/**
 * 1.接收到响应
 */
- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveResponse:(NSHTTPURLResponse *)response completionHandler:(void (^)(NSURLSessionResponseDisposition))completionHandler
{
    // 打开流
    [self.stream open];
    
    // 获得服务器这次请求 返回数据的总长度
    self.totalLength = [response.allHeaderFields[@"Content-Length"] integerValue] + MDJDownloadLength;
    
    // 存储总长度
    NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithContentsOfFile:MDJTotalLengthFullpath];
    if (dict == nil) dict = [NSMutableDictionary dictionary];
    dict[MDJFilename] = @(self.totalLength);
    [dict writeToFile:MDJTotalLengthFullpath atomically:YES];
    
    // 接收这个请求，允许接收服务器的数据
    completionHandler(NSURLSessionResponseAllow);
}

/**
 * 2.接收到服务器返回的数据（这个方法可能会被调用N次）
 */
- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveData:(NSData *)data
{
    // 写入数据
    [self.stream write:data.bytes maxLength:data.length];
    
    // 下载进度
    dispatch_async(dispatch_get_main_queue(), ^{
        self.progressBar.progress = 1.0 * MDJDownloadLength / self.totalLength;

    });
}

/**
 * 3.请求完毕（成功\失败）
 */
- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error
{
    // 关闭流
    [self.stream close];
    self.stream = nil;
    
    // 清除任务
    self.task = nil;
}

@end
