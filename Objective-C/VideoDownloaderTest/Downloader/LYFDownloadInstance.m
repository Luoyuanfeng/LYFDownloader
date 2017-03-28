//
//  Created by 罗元丰 on 16/9/6.
//  Copyright © 2016年 罗元丰. All rights reserved.
//

#import "LYFDownloadInstance.h"
#import "LYFDownloadFileManager.h"
#import "NSData+LYFCorrectResumeData.h"

static int kDefaultFailCount  = 3;
static int kRequestTimeout    = 30;

@interface LYFDownloadInstance () <NSURLSessionDownloadDelegate>

@end

@implementation LYFDownloadInstance {
    
@private;
    NSData                     *_resumeData;
    NSURLRequest               *_request;
    NSURLSession               *_session;
    NSURLSessionDownloadTask   *_downloadTask;
    NSURLSessionConfiguration  *_config;
    
    NSString                   *_baseFilePath;     //根文件夹
    NSString                   *_filePath;         //文件的保存路径
    NSTimer                    *_speedTimer;       //定时器，统计下载速度
    int64_t                    _speed;             //当前的下载速度
    int                        _failCount;         //下载尝试次数，默认2次，连续失败后抛出异常通知
    BOOL                       _isProducing;       //是否是主动生成的下载数据
}

//初始化
- (instancetype)initWithUrlString:(NSString *)urlString customKey:(NSString *)customKey rootFolder:(int)rootFolder
{
    if (self = [super init]) {
        _urlStr = urlString;
        _customKey = customKey;
        _baseFilePath = rootFolder ? NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).lastObject : NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES).lastObject;
        
        _speedTimer = [NSTimer scheduledTimerWithTimeInterval:1.0f target:self selector:@selector(getCurrentSpeed) userInfo:nil repeats:YES];
        
        _config = [NSURLSessionConfiguration backgroundSessionConfigurationWithIdentifier:customKey];
        _config.sessionSendsLaunchEvents = YES;
        _config.discretionary = NO;
        _config.timeoutIntervalForRequest = kRequestTimeout;
        
        _session = [NSURLSession sessionWithConfiguration:_config delegate:self delegateQueue:[NSOperationQueue mainQueue]];
        
        _request = [NSURLRequest requestWithURL:[NSURL URLWithString:_urlStr]];
        _downloadTask = [_session downloadTaskWithRequest:_request];
    }
    return self;
}

#pragma mark - <NSURLSessionDownloadDelegate>
//下载完成
- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didFinishDownloadingToURL:(NSURL *)location
{
    NSString *createPath = [NSString stringWithFormat:@"%@/%@", _baseFilePath, _customFolderDirectory ? _customFolderDirectory : @"downloadFile"];
    NSString *fileName = _customFileName ? : _customKey;
    
    NSError *error = nil;
    [LYFDownloadFileManager moveFileFromPath:location.path
                                      toPath:createPath
                                    fileName:fileName
                                       error:&error];
    if (error) {
        NSLog(@"DOWNLOAD_ERROR : %@", error);
    }
    
    _currentSpeed = 0;
    _completePercentage = 1;
    if (_finishCallback) {
        _finishCallback();
    }
    
    NSString *path = [NSString stringWithFormat:@"%@/%@/resumeData/%@", _baseFilePath, _customFolderDirectory ? _customFolderDirectory : @"downloadFile", _customKey];
    [LYFDownloadFileManager deleteFileAtPath:path];
    
    [self releaseProperties];
}

//正在下载
- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didWriteData:(int64_t)bytesWritten totalBytesWritten:(int64_t)totalBytesWritten totalBytesExpectedToWrite:(int64_t)totalBytesExpectedToWrite
{
    _failCount = 0;
    _speed += bytesWritten / 1024;
    NSLog(@"downloading %@ >>> speed:%lldkbps, written:%lldbytes, total:%lldbytes", _customKey, _speed, totalBytesWritten, totalBytesExpectedToWrite);
    
    _total = totalBytesExpectedToWrite;
    _completePercentage = totalBytesWritten / (float)totalBytesExpectedToWrite;
}

//下载失败
- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error
{
    if (error && !_isProducing) {
        if ([error.userInfo objectForKey:NSURLSessionDownloadTaskResumeData]) {
            
            _failCount++;
            _resumeData = [NSData getCorrectResumeData:[error.userInfo objectForKey:NSURLSessionDownloadTaskResumeData]];
            
            if (_downloadTask) {
                [_downloadTask cancel];
                _downloadTask = nil;
            }
            
            if (_failCount == kDefaultFailCount) {
                if (_failedCallback) {
                    _failedCallback(self);
                }
                return;
            }
            
            _downloadTask = [_session downloadTaskWithResumeData:_resumeData];
            if (_awakeCallback(self)) {
                [_downloadTask resume];
            }
        } else {
            NSLog(@"DOWNLOAD_ERROR : %@ AT >>> %s-%s-%d", error.localizedDescription, __FILE__, __FUNCTION__, __LINE__);
        }
    }
}

#pragma mark - public
//开始下载
- (void)start
{
    if (_downloadTask.state == NSURLSessionTaskStateSuspended) {
        [_downloadTask resume];
        [self resumeIfNeeded];
    }
}

//暂停下载
- (void)pause
{
    if (_downloadTask.state == NSURLSessionTaskStateRunning) {
        [_downloadTask suspend];
    }
}

//取消下载
- (void)cancel
{
    if (_downloadTask.state != NSURLSessionTaskStateCanceling) {
        [_downloadTask cancel];
        [self releaseProperties];
    }
}

//取消并生成恢复数据
- (void)cancelByProduceResumeData
{
    if (_downloadTask.state == NSURLSessionTaskStateCanceling) {
        return;
    }
    
    _isProducing = YES;
    [_downloadTask cancelByProducingResumeData:^(NSData * _Nullable resumeData) {
        
        if (resumeData) {
            NSString *path = [NSString stringWithFormat:@"%@/%@/resumeData", _baseFilePath, _customFolderDirectory ? _customFolderDirectory : @"downloadFile"];
            NSError *error = nil;
            [LYFDownloadFileManager writeContent:[NSData getCorrectResumeData:resumeData]
                                          toPath:path
                                        fileName:_customKey
                                  createNotExist:YES
                                           error:&error];
            if (error) {
                NSLog(@"%@", error);
            }
        }
        
        [self releaseProperties];
    }];
}

#pragma mark - private
//获取当前下载速度
- (void)getCurrentSpeed
{
    _currentSpeed = _speed;
    _speed = 0;
}

//检测本地是否有可供恢复下载的数据
- (void)resumeIfNeeded
{
    NSString *path = [NSString stringWithFormat:@"%@/%@/resumeData", _baseFilePath, _customFolderDirectory ? _customFolderDirectory : @"downloadFile"];
    NSArray *arr = [LYFDownloadFileManager subpathOfPath:path];
    
    for (NSString *fileName in arr) {
        
        if ([fileName isEqualToString:_customKey]) {
            
            [LYFDownloadFileManager readFileFromPath:[path stringByAppendingPathComponent:_customKey] completion:^(NSData *data) {
                NSData *resumeData = data;
                if (resumeData) {
                    [_downloadTask cancel];
                    _downloadTask = nil;
                    _downloadTask = [_session downloadTaskWithResumeData:resumeData];
                    if (_awakeCallback(self)) {
                        [_downloadTask resume];
                    }
                }
            }];
            break;
        }
    }
}

//置空属性释放当前对象（下载完成 或 取消下载 时执行）
- (void)releaseProperties
{
    _failCount = 0;
    _config = nil;
    [_speedTimer invalidate];
    _speedTimer = nil;
    [_session finishTasksAndInvalidate];
    _session = nil;
}

#pragma mark -
- (NSString *)description
{
    return [NSString stringWithFormat:@"<%@:%p> customKey:%@ -- customInfo:%@", [self class], self, _customKey, _customInfo];
}

- (void)dealloc
{
    NSLog(@"download instance: <%@_%p> for key: \"%@\" has been deallocated", [self class], self, _customKey);
}

@end
