//
//  DownloadCell.m
//  VideoDownloaderTest
//
//  Created by 罗元丰 on 16/9/6.
//  Copyright © 2016年 罗元丰. All rights reserved.
//

#import "DownloadCell.h"
#import "LYFDownloadTaskModel.h"

@interface DownloadCell ()
@property (weak, nonatomic) IBOutlet UILabel *urlLabel;
@property (weak, nonatomic) IBOutlet UIButton *beginBtn;
@property (weak, nonatomic) IBOutlet UIProgressView *progressView;
@property (weak, nonatomic) IBOutlet UILabel *percentageLabel;
@property (weak, nonatomic) IBOutlet UILabel *speedLabel;
@end

@implementation DownloadCell

- (void)awakeFromNib
{
    [super awakeFromNib];
    self.selectionStyle = UITableViewCellSelectionStyleNone;
}

- (void)setViewModel:(LYFDownloadTaskModel *)viewModel
{
    _viewModel = viewModel;
    
    NSString *statusStr = @"unknownStatus";
    switch (_viewModel.status) {
        case LYFTaskStatusDownloading:
            statusStr = @"暂停";
            break;
        case LYFTaskStatusPause:
            statusStr = @"开始";
            break;
        case LYFTaskStatusWaiting:
            statusStr = @"等待";
            break;
        default:
            break;
    }
    
    _urlLabel.text = _viewModel.customKey;
    [_beginBtn setTitle:statusStr forState:UIControlStateNormal];
    _progressView.progress = _viewModel.completePercentage;
    _percentageLabel.text = [NSString stringWithFormat:@"%.2f", _viewModel.completePercentage];
    _speedLabel.text = [NSString stringWithFormat:@"%lld/s", _viewModel.currentSpeed];
}

- (IBAction)changeStatus:(id)sender
{
    if (self.delegate && [self.delegate respondsToSelector:@selector(downloadCell:didClickButtonWithModel:)]) {
        [self.delegate downloadCell:self didClickButtonWithModel:self.viewModel];
    }
}

@end
