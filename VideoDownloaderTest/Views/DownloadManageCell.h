//
//  DownloadManageCell.h
//  VideoDownloaderTest
//
//  Created by 罗元丰 on 2017/2/23.
//  Copyright © 2017年 罗元丰. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol DownloadManageCellDelegate <NSObject>

- (void)download:(NSString *)url sender:(UIButton *)btn;;

@end

@interface DownloadManageCell : UITableViewCell

@property (nonatomic, assign) id<DownloadManageCellDelegate> delegate;
@property (nonatomic, copy) NSString *urlStr;

@end
