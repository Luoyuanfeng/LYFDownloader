//
//  Created by 罗元丰 on 16/9/6.
//  Copyright © 2016年 罗元丰. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "LYFDownloadTaskModel.h"

FOUNDATION_EXPORT NSString * const LYFRefreshDownloadInfoNotification;
FOUNDATION_EXPORT NSString * const LYFDownloadFailedNotification;

typedef NS_ENUM(int, LYFDownloaderRootFolder) {
    LYFDownloaderRootFolderCache = 0,
    LYFDownloaderRootFolderDocuments = 1
};
typedef NS_ENUM(int, LYFDownloadUserOperate) {
    LYFDownloadUserOperateSaveOrUpdate = 1,
    LYFDownloadUserOperateDelete,
    LYFDownloadUserOperateDeleteAll
};
typedef void(^LYFTaskStatusChangedCallbackBlock)(NSArray<LYFDownloadTaskModel *>* changedArray, LYFDownloadUserOperate userOperate);

@interface LYFDownloadManager : NSObject

@property (nonatomic, assign) LYFDownloaderRootFolder rootFolder; //下载的根目录（cache或documnets，默认cache）

@property (nonatomic, strong, readonly) LYFDownloadTaskModel *downloadingTaskModel; //当前下载任务信息
@property (nonatomic, assign, readonly) int allTasksCount;                          //下载任务总数

#pragma mark - singleton
+ (instancetype)sharedInstance;

#pragma mark - 配置方法
/** 
 * 设置数据刷新的时间间隔 
 * taskStatusChangeHandler是在有下载任务状态发生改变时的回调，建议在此回调中操作数据路库
 */
- (void)configWithDataRefreshInterval:(NSTimeInterval)timeInterval taskStatusChangeHandler:(LYFTaskStatusChangedCallbackBlock)change;
/** -application:handleEventsForBackgroundURLSession:completionHandler: 中调用，下载任务在后台完成时执行 */
- (void)taskDidFinishInBackground:(NSString *)customKey completionHandler:(void(^)())completion;

#pragma mark - 下载动作
/** 获取所有下载任务 */
- (void)getAllDownloadTasksInfo:(void(^)(NSArray <LYFDownloadTaskModel *>* modelArray))completion;
/** 是否已包含某个下载任务 */
- (BOOL)containsTask:(NSString *)customKey;

/****
 * 创建下载任务
 * customKey: 唯一标识，使用customKey确定唯一的下载任务，必须
 * url: 下载地址，必须
 * createTime: 创建时间
 * status: 下载状态，新建下载任务请使用TaskStatusNew，应用启动时恢复原先下载任务请使用从数据库读取的状态，不要使用TaskStatusFinish创建下载任务
 * customInfo: 下载任务的其他附带信息，下载过程中由下载任务一直携带
 * expectedFileName: 用户期望的文件名，nil表示使用系统建议文件名
 * expectedDirectory: 用户期望的文件存储路径，nil表示存储在根文件夹（见rootFolder属性）下的downloadFile文件夹中
 */
- (void)addDownloadTaskForKey:(NSString *)customKey
                          url:(NSString *)url
                   createTime:(double)createTime
                       status:(LYFTaskStatus)status
                   customInfo:(NSDictionary *)customInfo
             expectedFileName:(NSString *)aFileName
            expectedDirectory:(NSString *)aDirectory;

/** 使用customKey启动下载 */
- (void)startDownloadTaskForKey:(NSString *)customKey;
/** 使用customKey暂停下载 */
- (void)pauseDownloadTaskForKey:(NSString *)customKey;
/** 使用customKey删除下载任务 */
- (void)deleteDownloadTaskForKey:(NSString *)customKey;
/** 开始所有下载任务（只启动最早创建的任务，其它进入等待状态）*/
- (void)startAll;
/** 暂停所有下载任务 */
- (void)pauseAll;
/** 删除所有下载任务 */
- (void)deleteAll;
/** 强制取消所有下载任务并生成恢复数据，用于退出登录 */
- (void)cancelAllByProduceResumeData;

@end
