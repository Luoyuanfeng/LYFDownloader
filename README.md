
#LYFDownloader v1.3
***

* **v1.3更新内容**

1.增加了方法以判断下载器当前是否包含某个任务：

```
- (BOOL)containsTask:(NSString *)customKey;
```

***

* **v1.2更新内容**

1.直接获取当前正在下载的任务。

示例：

```
[LYFDownloadManager sharedInstance].downloadingTaskModel;
```

2.优化实现。

***

* **v1.1更新内容**
1. 支持用户退出登录后的自动停止和再次登录后的恢复下载。
2. 下载失败时的通知（尝试恢复下载失败超过3次时抛出通知）。
3. 创建下载任务不需要再传文件名参数。
4. customKey必须为唯一id，以保证下载任务的唯一性。

***

* **时序图**

黑色为下载流程，蓝色为获取任务信息流程。

![时序图](http://wx3.sinaimg.cn/mw690/e8c8bc63ly1fd6mm8g4ukj20p90jo0ul.jpg)

***

* **实现**

1. 单独、批量操作下载任务和获取任务数据均通过单例LYFDownloadManager实现。

2. 调用添加下载任务方法时，LYFDownloadManager负责创建一个NSURLSession的代理，即一个LYFDownloadInstance对象，在该对象中实现了NSURLSession的正在下载、下载完成、出现错误共3个代理方法。在代理方法的实现中完成了下载进度、下载速度的计算及下载完成、下载失败时的回调。

3. 在外部需要获取当前的下载任务信息时，LYFDownloadManager会取出所需的下载任务（即LYFDownloadInstance对象），根据其中的数据创建LYFDownloadTaskModel对象并向外提供，保证了在下载过程中下载任务的数据不会被意外修改，外部可以使用LYFDownloadTaskModel对象中的数据刷新界面或更新数据库。

4. 关于后台下载：后台下载通过NSURLSessionConfiguration的+backgroundSessionConfigurationWithIdentifier:方法实现，该方法使-sessionWithConfiguration:delegate:delegateQueue:方法创建出的NSURLSession可以被托管给系统并在后台执行。当执行完成后则会唤起应用进行回调，为应用留出一段时间进行下载完成后的操作（如添加下一个下载任务等）。

5. 关于断点续传：当应用处于前台时，下载任务的暂停和恢复通过直接调用NSURLSessionDoanloadTask的-suspend和-resume方法实现。当应用在下载任务执行过程中被退出时，系统会自动保存有关当前下载任务的恢复数据，当应用被启动，通过同一个identifier再次创建该下载任务时，系统会找到上次留下的恢复数据并继续下载。

***

###使用：


* **配置AppDelegate**

1.`#import "LYFDownloadManager.h"`

2.在`- (BOOL)application:didFinishLaunchingWithOptions:`中调用`configWithDataRefreshInterval:taskStatusChangeHandler:`

示例：

``` 
- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
//开启下载器并设定数据刷新的时间间隔
[[LYFDownloadManager sharedInstance] configWithDataRefreshInterval:1.f taskStatusChangeHandler:^(NSArray<LYFDownloadTaskModel *> *changedTasksArray) {
//每次有下载任务状态变化时执行该回调，建议使用LYFDownloadTaskModel中的数据更新数据库。
}];
return YES;
}
```

3.实现`-application:handleEventsForBackgroundURLSession:completionHandler:`
并在方法中调用`-taskDidFinishInBackground:completionHandler:`实现后台下载完成时的回调。

示例：

```
- (void)application:(UIApplication *)application handleEventsForBackgroundURLSession:(nonnull NSString *)identifier completionHandler:(nonnull void (^)())completionHandler {
[[LYFDownloadManager sharedInstance] taskDidFinishInBackground:identifier completionHandler:completionHandler];
}
```

* **界面刷新**

1.使用`LYFRefreshDownloadInfoNotification`或`-(void)getAllDownloadTasksInfo:`获取下载任务数组（根据下载任务创建时间排序）。

2.使用`LYFDownloadTaskModel`更新界面。


###接口

* **LYFDownloadManager.h**


```
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
```

* **LYFDownloadTaskModel.h**

```
#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger, LYFTaskStatus) {
LYFTaskStatusNew           = 0,  //创建新任务使用

LYFTaskStatusDownloading   = 1,  //刷新列表、更新db使用
LYFTaskStatusWaiting       = 2,
LYFTaskStatusPause         = 3,

LYFTaskStatusFinish        = 4
};

@interface LYFDownloadTaskModel : NSObject

@property (nonatomic, copy)   NSString       *customKey;               // id标识
@property (nonatomic, strong) NSDictionary   *customInfo;              // 其他附带信息
@property (nonatomic, assign) double         taskCreateTime;           // 下载任务的创建时间(ms时间戳)
@property (nonatomic, assign) LYFTaskStatus  status;                   // 下载状态
@property (nonatomic, copy)   NSString       *customFolderDirectory;   // 沙盒文件夹下需要的路径
@property (nonatomic, copy)   NSString       *urlString;               // 文件地址
@property (nonatomic, assign) int64_t        currentSpeed;             // 当前的下载速度(kb/s)
@property (nonatomic, assign) int64_t        total;                    // 总大小(b)
@property (nonatomic, assign) float          completePercentage;       // 完成百分比(0~1)
@property (nonatomic, assign) int            taskCount;                // 下载任务总数

@end
```
