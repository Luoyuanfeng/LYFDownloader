//
//  DownloadManageCell.m
//  VideoDownloaderTest
//
//  Created by 罗元丰 on 2017/2/23.
//  Copyright © 2017年 罗元丰. All rights reserved.
//

#import "DownloadManageCell.h"

@interface DownloadManageCell ()

@property (weak, nonatomic) IBOutlet UILabel *urlLabel;
@property (weak, nonatomic) IBOutlet UIButton *downloadButton;

@end

@implementation DownloadManageCell

- (void)awakeFromNib
{
    [super awakeFromNib];
    self.selectionStyle = UITableViewCellSelectionStyleNone;
}

- (void)setUrlStr:(NSString *)urlStr
{
    _urlStr = urlStr;
    _urlLabel.text = _urlStr;
}

- (IBAction)download:(UIButton *)sender {
    if (self.delegate && [self.delegate respondsToSelector:@selector(download:sender:)]) {
        [self.delegate download:_urlStr sender:_downloadButton];
    }
}

@end
