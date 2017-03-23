//
//  Created by 罗元丰 on 16/9/6.
//  Copyright © 2016年 罗元丰. All rights reserved.
//

#import "LYFDownloadManager.h"
#import "LYFDownloadInstance.h"

#define kFILE_FUNC_LINE [NSString stringWithFormat:@"%s -- %s -- %d", __FILE__, __FUNCTION__, __LINE__]
#define kDOWNLOADER_CANT_FIND_TASK(desc) if (!instance) {\
NSLog(@"DOWNLOAD ERROR : could not find a task with key:%@ when %@", customKey, desc);\
return;\
}

@interface LYFDownloadManager ()

@property (nonatomic, strong) NSMutableDictionary                *downloadInstances;      //所有下载任务
@property (nonatomic, strong) LYFDownloadInstance                *downloading;            //正在下载的任务
@property (nonatomic, strong) NSTimer                            *pushDownloadInfoTimer;  //发送通知的定时器
@property (nonatomic, assign) NSTimeInterval                     refreshInterval;         //定时器间隔
@property (nonatomic, copy)   LYFTaskStatusChangedCallbackBlock  taskStatusChanged;       //有下载任务的状态发生变化时调用

@end

NSString * const LYFRefreshDownloadInfoNotification = @"_LYFDownloader_refreshDownloadInfo_Notification_";
NSString * const LYFDownloadFailedNotification      = @"_LYFDownloader_failed_Notification_";

@implementation LYFDownloadManager {
    LYFDownloadTaskModel *_downloadingTaskModel;
}

#pragma mark - setters
- (void)setDownloading:(LYFDownloadInstance *)downloading
{
    _downloading = downloading;
    if (_downloading) {
        LYFDownloadTaskModel *model = [self transfer:_downloading];
        if (model) {
            _taskStatusChanged(@[model], LYFDownloadUserOperateSaveOrUpdate);
        }
    }
}

#pragma mark - getters
- (NSMutableDictionary *)downloadInstances
{
    @synchronized (_downloadInstances) {
        if (!_downloadInstances) {
            _downloadInstances = [NSMutableDictionary dictionary];
        }
        return _downloadInstances;
    }
}

#pragma mark 获取下载任务总数
- (int)allTasksCount
{
    return (int)self.downloadInstances.allValues.count;
}

#pragma mark 当前下载任务信息
- (LYFDownloadTaskModel *)downloadingTaskModel
{
    _downloadingTaskModel = [self transfer:_downloading];
    return _downloadingTaskModel;
}

#pragma mark - singleton start
static id obj = nil;
+ (instancetype)sharedInstance
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        obj = [[self alloc] init];
    });
    return obj;
}

+ (instancetype)allocWithZone:(struct _NSZone *)zone
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        obj = [super allocWithZone:zone];
    });
    return obj;
}

- (instancetype)init
{
    return obj;
}

- (id)copyWithZone:(NSZone *)zone
{
    return obj;
}
#pragma mark singleton end

#pragma mark - public(配置方法)
#pragma mark 设置数据刷新时间间隔
- (void)configWithDataRefreshInterval:(NSTimeInterval)timeInterval taskStatusChangeHandler:(LYFTaskStatusChangedCallbackBlock)change
{
    _refreshInterval = timeInterval;
    if (change) {
        _taskStatusChanged = change;
    }
    
    if (_pushDownloadInfoTimer) {
        [_pushDownloadInfoTimer invalidate];
        _pushDownloadInfoTimer = nil;
    }
    _pushDownloadInfoTimer = [NSTimer scheduledTimerWithTimeInterval:_refreshInterval target:self selector:@selector(pushDownloadInfo) userInfo:nil repeats:YES];
}

#pragma mark 后台下载完成
- (void)taskDidFinishInBackground:(NSString *)customKey completionHandler:(void (^)())completion
{
    NSAssert(customKey, @"DOWNLOAD_ERROR : must have a customKey to continue in background download at %@", kFILE_FUNC_LINE);
    NSAssert(completion, @"DOWNLOAD_ERROR : must have a completion handler to continue in background download at %@", kFILE_FUNC_LINE);
    
    LYFDownloadInstance *instance = self.downloadInstances[customKey];
    kDOWNLOADER_CANT_FIND_TASK(@"finish in background");
    instance.finishCallback();
    completion();
}

#pragma mark - public(下载动作)
#pragma mark 获取所有下载任务
- (void)getAllDownloadTasksInfo:(void(^)(NSArray <LYFDownloadTaskModel *> *modelArray))completion;
{
    __block NSMutableArray *modelArray = [NSMutableArray array];
    
    if (self.downloadInstances.allValues.count) {
        
        dispatch_queue_t globalQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
        dispatch_async(globalQueue, ^{
            
            NSArray *sortedArr = [self sort:self.downloadInstances];
            for (LYFDownloadInstance *ins in sortedArr) {
                LYFDownloadTaskModel *model = [self transfer:ins];
                [modelArray addObject:model];
            }
            if (completion) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    completion(modelArray);
                });
            }
        });
    } else {
        if (completion) {
            completion(modelArray);
        }
    }
}

#pragma mark - 是否已包含某个下载任务
- (BOOL)containsTask:(NSString *)customKey
{
    return (self.downloadInstances[customKey] != nil);
}

#pragma mark 创建下载任务
- (void)addDownloadTaskForKey:(NSString *)customKey
                          url:(NSString *)url
                   createTime:(double)createTime
                       status:(LYFTaskStatus)status
                   customInfo:(NSDictionary *)customInfo
             expectedFileName:(NSString *)aFileName
            expectedDirectory:(NSString *)aDirectory
{
    
    NSAssert(customKey, @"DOWNLOAD_ERROR : need a key to create download task AT >> %@", kFILE_FUNC_LINE);
    NSAssert(url, @"DOWNLOAD_ERROR : a download task must have a url AT >> %@", kFILE_FUNC_LINE);
    
    if ([self containsTask:customKey]) {
        NSLog(@"DOWNLOAD_WARNNING : task \"%@\" is already exists AT >> %@", customKey, kFILE_FUNC_LINE);
        return;
    }
    
    LYFDownloadInstance *instance = [[LYFDownloadInstance alloc] initWithUrlString:url
                                                                         customKey:customKey
                                                                        rootFolder:_rootFolder];
    if (aFileName)
        instance.customFileName = aFileName;
    if (aDirectory)
        instance.customFolderDirectory = aDirectory;
    if (customInfo)
        instance.customInfo = customInfo;
    if (createTime)
        instance.taskCreateTime = createTime;
    if (status && status < 4)
        instance.status = (LYFDownloadStatus)status;
    [self setCallBack:instance];
    [self.downloadInstances setObject:instance forKey:instance.customKey];
    
    if (!_downloading && instance.status != LYFDownloadStatusPause) {
        
        instance.status = LYFDownloadStatusDownloading;
        self.downloading = instance;
        [instance start];
        
    } else if (!instance.status) {
        
        instance.status = LYFDownloadStatusWaiting;
        LYFDownloadTaskModel *model = [self transfer:instance];
        if (model) {
            _taskStatusChanged(@[model], LYFDownloadUserOperateSaveOrUpdate);
        }
    }
}

#pragma mark 开始下载
- (void)startDownloadTaskForKey:(NSString *)customKey
{
    LYFDownloadInstance *instance = [self.downloadInstances objectForKey:customKey];
    kDOWNLOADER_CANT_FIND_TASK(@"start")
    
    if (instance != _downloading && instance.status) {
        
        if (_downloading) {
            [_downloading pause];
            _downloading.status = LYFDownloadStatusWaiting;
            self.downloading = nil;
        }
    }
    
    [instance start];
    instance.status = LYFDownloadStatusDownloading;
    self.downloading = instance;
}

#pragma mark 暂停下载
- (void)pauseDownloadTaskForKey:(NSString *)customKey
{
    LYFDownloadInstance *instance = [self.downloadInstances objectForKey:customKey];
    kDOWNLOADER_CANT_FIND_TASK(@"pause")
    
    [instance pause];
    instance.status = LYFDownloadStatusPause;
            
    LYFDownloadTaskModel *model = [self transfer:instance];
    if (model) {
        _taskStatusChanged(@[model], LYFDownloadUserOperateSaveOrUpdate);
    }
    
    if (instance == _downloading) {
        self.downloading = nil;
    }
    
    if (self.downloadInstances.allValues.count > 1) {
        [self nextTask];
    }
}

#pragma mark 删除下载任务
- (void)deleteDownloadTaskForKey:(NSString *)customKey
{
    LYFDownloadInstance *instance = self.downloadInstances[customKey];
    kDOWNLOADER_CANT_FIND_TASK(@"delete")
    
    LYFDownloadTaskModel *model = [self transfer:instance];
    if (model) {
        _taskStatusChanged(@[model], LYFDownloadUserOperateDelete);
    }
    
    if (instance == _downloading) {
        self.downloading = nil;
        [self.downloadInstances removeObjectForKey:instance.customKey];
        
        if (self.downloadInstances.count > 0) {
            [self nextTask];
        }
    } else {
        [self.downloadInstances removeObjectForKey:instance.customKey];
    }
    [instance cancel];
}

#pragma mark 全部开始
- (void)startAll
{
    NSArray *sortedArr = [self sort:self.downloadInstances];
    NSMutableArray *changeArray = [NSMutableArray array];
    
    for (int i = 0; i < sortedArr.count; i++) {
        LYFDownloadInstance *instance = sortedArr[i];
        [instance pause];
        instance.status = LYFDownloadStatusWaiting;
        
        if (!_downloading) {
            
            [instance start];
            instance.status = LYFDownloadStatusDownloading;
            self.downloading = instance;
            continue;
        }
        
        LYFDownloadTaskModel *model = [self transfer:instance];
        if (model) {
            [changeArray addObject:model];
        }
    }
    _taskStatusChanged(changeArray, LYFDownloadUserOperateSaveOrUpdate);
}

#pragma mark 全部暂停
- (void)pauseAll
{
    self.downloading = nil;
    NSMutableArray *changeArray = [NSMutableArray array];
    
    for (LYFDownloadInstance *instance in self.downloadInstances.allValues) {
        
        [instance pause];
        instance.status = LYFDownloadStatusPause;
        
        LYFDownloadTaskModel *model = [self transfer:instance];
        if (model) {
            [changeArray addObject:model];
        }
    }
    _taskStatusChanged(changeArray, LYFDownloadUserOperateSaveOrUpdate);
}

#pragma mark 全部删除
- (void)deleteAll
{
    self.downloading = nil;
    NSMutableArray *changeArray = [NSMutableArray array];
    
    for (LYFDownloadInstance *instance in self.downloadInstances.allValues) {
        
        LYFDownloadTaskModel *model = [self transfer:instance];
        if (model) {
            [changeArray addObject:model];
        }
        [instance cancel];
    }
    
    [self.downloadInstances removeAllObjects];
    _taskStatusChanged(changeArray, LYFDownloadUserOperateDeleteAll);
}

#pragma mark - 强制取消所有下载任务并生成恢复数据，用于退出登录
- (void)cancelAllByProduceResumeData
{
    self.downloading = nil;
    NSMutableArray *changeArray = [NSMutableArray array];
    
    for (LYFDownloadInstance *instance in self.downloadInstances.allValues) {
        
        LYFDownloadTaskModel *model = [self transfer:instance];
        if (model) {
            [changeArray addObject:model];
        }
        [instance cancelByProduceResumeData];
    }
    _taskStatusChanged(changeArray, LYFDownloadUserOperateSaveOrUpdate);
    [self.downloadInstances removeAllObjects];
}

#pragma mark - private
#pragma mark instance转model
- (LYFDownloadTaskModel *)transfer:(LYFDownloadInstance *)instance
{
    if (!instance) {
        return nil;
    }
    
    NSSearchPathDirectory dir = NSCachesDirectory;
    if (_rootFolder == LYFDownloaderRootFolderDocuments) {
        dir = NSDocumentDirectory;
    }
    
    LYFDownloadTaskModel *model = [[LYFDownloadTaskModel alloc] init];
    model.customKey             = instance.customKey;
    model.customFolderDirectory = instance.customFolderDirectory;
    model.customFileName        = instance.customFileName;
    model.urlString             = instance.urlStr;
    model.customInfo            = instance.customInfo;
    model.taskCreateTime        = instance.taskCreateTime;
    model.currentSpeed          = instance.currentSpeed;
    model.completePercentage    = instance.completePercentage;
    model.total                 = instance.total;
    model.status                = (LYFTaskStatus)instance.status;
    model.taskCount             = (int)self.downloadInstances.allValues.count;
    return model;
}

#pragma mark 为下载任务设置回调
- (void)setCallBack:(LYFDownloadInstance *)instance
{
    instance.finishCallback = ^{
        [self pushDownloadInfo];
        
        LYFDownloadTaskModel *model = [self transfer:_downloading];
        model.status = LYFTaskStatusFinish;
        if (model) {
            _taskStatusChanged(@[model], LYFDownloadUserOperateSaveOrUpdate);
        }
        
        self.downloading = nil;
        [self nextTask];
    };
    
    instance.awakeCallback = ^BOOL (LYFDownloadInstance *ins){
        return (!(_downloading) || _downloading == ins);
    };
    
    instance.failedCallback = ^(LYFDownloadInstance *ins){
        [[NSNotificationCenter defaultCenter] postNotificationName:LYFDownloadFailedNotification object:[self transfer:ins]];
    };
}

#pragma mark 执行下一个下载任务
- (void)nextTask
{
    if (!_downloading) {
        
        NSArray *sortedArr = [self sort:self.downloadInstances];
        for (LYFDownloadInstance *instance in sortedArr) {
            
            if (instance.status == LYFDownloadStatusWaiting) {
                
                [instance start];
                instance.status = LYFDownloadStatusDownloading;
                self.downloading = instance;
                return;
            }
        }
    }
}

#pragma mark 根据创建时间排序下载任务
- (NSArray *)sort:(NSDictionary *)dic
{
    return [[dic allValues] sortedArrayUsingComparator:^NSComparisonResult(LYFDownloadInstance *obj1, LYFDownloadInstance *obj2) {
        if (obj1.taskCreateTime < obj2.taskCreateTime) {
            return NSOrderedAscending;
        } else if (obj1.taskCreateTime > obj2.taskCreateTime) {
            return NSOrderedDescending;
        } else {
            return NSOrderedSame;
        }
    }];
}

#pragma mark 发送刷新界面的通知
- (void)pushDownloadInfo
{
    if (self.downloadInstances.allValues.count == 0) {
        NSLog(@"_______________NO_______TASK________________");
        return;
    }
    
    __block NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    
    dispatch_queue_t globalQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    dispatch_async(globalQueue, ^{
    
        LYFDownloadInstance *willRemove = nil;
        for (NSString *customKey in self.downloadInstances.allKeys) {
            
            LYFDownloadInstance *ins = self.downloadInstances[customKey];
            if (ins) {
                LYFDownloadTaskModel *model = [self transfer:ins];
                [dict setObject:model forKey:customKey];
                
                if (ins.completePercentage == 1) {
                    willRemove = ins;
                }
            }
        }
        
        if (willRemove) {
            [self.downloadInstances removeObjectForKey:willRemove.customKey];
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [[NSNotificationCenter defaultCenter] postNotificationName:LYFRefreshDownloadInfoNotification object:dict];
        });
    });
}

#pragma mark -
- (void)dealloc
{
    [_pushDownloadInfoTimer invalidate];
    _pushDownloadInfoTimer = nil;
}

@end
