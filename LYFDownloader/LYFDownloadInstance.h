//
//  Created by 罗元丰 on 16/9/6.
//  Copyright © 2016年 罗元丰. All rights reserved.
//

#import <Foundation/Foundation.h>

@class LYFDownloadInstance;

typedef NS_ENUM(NSInteger, LYFDownloadStatus) {
    LYFDownloadStatusDownloading   = 1,
    LYFDownloadStatusWaiting       = 2,
    LYFDownloadStatusPause         = 3,
};

typedef void(^LYFDownloadDidFinishCallbackBlock)();
typedef BOOL(^LYFDownloadWillAwakeCallbackBlock)(LYFDownloadInstance *);
typedef void(^LYFDownloadDidFailedCallbackBlock)(LYFDownloadInstance *);

@interface LYFDownloadInstance : NSObject

@property (nonatomic, assign) double                             taskCreateTime;         // 下载任务的创建时间
@property (nonatomic, strong) NSDictionary                       *customInfo;            // 其他附带信息
@property (nonatomic, assign) LYFDownloadStatus                  status;                 // 下载状态
@property (nonatomic, copy)   NSString                           *customFolderDirectory; // 沙盒文件夹下需要的路径
@property (nonatomic, copy)   NSString                           *customFileName;        // 沙盒文件夹下的文件名

@property (nonatomic, copy)   LYFDownloadDidFinishCallbackBlock  finishCallback;         // 下载完成的回调
@property (nonatomic, copy)   LYFDownloadWillAwakeCallbackBlock  awakeCallback;          // 当下载过程中应用退出后再次被打开时执行的回调
@property (nonatomic, copy)   LYFDownloadDidFailedCallbackBlock  failedCallback;         // 下载失败的回调

@property (nonatomic, assign) int                 rootFolder;           //保存文件的根文件夹

@property (nonatomic, copy, readonly)   NSString  *customKey;           // id标识
@property (nonatomic, copy, readonly)   NSString  *urlStr;              // 下载的url 
@property (nonatomic, assign, readonly) int64_t   currentSpeed;         // 当前的下载速度
@property (nonatomic, assign, readonly) int64_t   total;                // 总大小
@property (nonatomic, assign, readonly) float     completePercentage;   // 完成百分比

/** 使用url，key，和下载偏移量开始下载 */
- (instancetype)initWithUrlString:(NSString *)urlString
                        customKey:(NSString *)customKey
                       rootFolder:(int)rootFolder;
/** 开始下载任务 */
- (void)start;
/** 暂停下载任务 */
- (void)pause;
/** 取消下载任务 */
- (void)cancel;
/** 取消并生成恢复数据 */
- (void)cancelByProduceResumeData;

@end
