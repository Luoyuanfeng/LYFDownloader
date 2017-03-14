//
//  Created by 罗元丰 on 16/11/27.
//  Copyright © 2016年 罗元丰. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger, LYFTaskStatus) {
    LYFTaskStatusNew           = 0,  //创建任务使用
    
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
@property (nonatomic, copy)   NSString       *customFileName;          // 沙盒文件夹下文件名
@property (nonatomic, copy)   NSString       *urlString;               // 文件地址
@property (nonatomic, assign) int64_t        currentSpeed;             // 当前的下载速度(kb/s)
@property (nonatomic, assign) int64_t        total;                    // 总大小(b)
@property (nonatomic, assign) float          completePercentage;       // 完成百分比(0~1)
@property (nonatomic, assign) int            taskCount;                // 下载任务总数

@end
