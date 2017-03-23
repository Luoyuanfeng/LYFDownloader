//
//  DownloadCell.h
//  VideoDownloaderTest
//
//  Created by 罗元丰 on 16/9/6.
//  Copyright © 2016年 罗元丰. All rights reserved.
//

#import <UIKit/UIKit.h>

@class DownloadCell, LYFDownloadTaskModel;

@protocol DownloadCellDelegate <NSObject>

- (void)downloadCell:(DownloadCell *)cell didClickButtonWithModel:(LYFDownloadTaskModel *)model;

@end

@interface DownloadCell : UITableViewCell

@property (nonatomic, strong) LYFDownloadTaskModel *viewModel;
@property (nonatomic, assign) id<DownloadCellDelegate> delegate;

@end
