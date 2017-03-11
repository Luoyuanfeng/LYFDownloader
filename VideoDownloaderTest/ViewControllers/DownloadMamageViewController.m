//
//  ViewController.m
//  VideoDownloaderTest
//
//  Created by 罗元丰 on 16/9/4.
//  Copyright © 2016年 罗元丰. All rights reserved.
//

#import "DownloadMamageViewController.h"
#import "DownloadCell.h"
#import "LYFDownloadManager.h"

#define VIDEO_URL_STRING @"http://source.highso.com.cn/1606/QUERXYWW/QUERXYWW_phone/QUERXYWW_phone.m3u8"
#define S_W [UIScreen mainScreen].bounds.size.width
#define S_H [UIScreen mainScreen].bounds.size.height

@interface DownloadMamageViewController () <UITableViewDataSource, UITableViewDelegate, DownloadCellDelegate>

/** tableView */
@property (nonatomic, strong) UITableView *table;

@end

@implementation DownloadMamageViewController {
    NSArray *_resourceArray;
    NSTimer *_timer;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.navigationItem.title = @"Download Manage";
    self.view.backgroundColor = [UIColor lightGrayColor];
    
    self.table = [[UITableView alloc] initWithFrame:CGRectMake(0, 30, self.view.bounds.size.width, self.view.bounds.size.height - 30) style:UITableViewStylePlain];
    self.table.dataSource = self;
    self.table.delegate = self;
    self.table.separatorStyle = UITableViewCellSeparatorStyleNone;
    [self.table registerNib:[UINib nibWithNibName:@"DownloadCell" bundle:[NSBundle mainBundle]] forCellReuseIdentifier:@"cell_id"];
    [self.view addSubview:self.table];
    
    UIBarButtonItem *right = [[UIBarButtonItem alloc] initWithTitle:@"模拟退出登录" style:UIBarButtonItemStylePlain target:self action:@selector(quitLogin)];
    self.navigationItem.rightBarButtonItem = right;
    
    if (!_timer) {
        _timer = [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(refreshDownloadInfo) userInfo:nil repeats:YES];
    }
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    [_timer invalidate];
    _timer = nil;
}

- (void)quitLogin
{
    [[LYFDownloadManager sharedInstance] cancelAllByProduceResumeData];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return _resourceArray.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    DownloadCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell_id" forIndexPath:indexPath];
    cell.viewModel = _resourceArray[indexPath.row];
    cell.delegate = self;
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 150;
}

- (void)refreshDownloadInfo
{
    [[LYFDownloadManager sharedInstance] getAllDownloadTasksInfo:^(NSArray<LYFDownloadTaskModel *> *modelArray) {
        _resourceArray = modelArray;
        [_table reloadData];
    }];
}

- (void)downloadCell:(DownloadCell *)cell didClickButtonWithModel:(LYFDownloadTaskModel *)model
{
    switch (model.status) {
        case LYFTaskStatusDownloading:
            [[LYFDownloadManager sharedInstance] pauseDownloadTaskForKey:model.customKey];
            break;
        case LYFTaskStatusPause:
            [[LYFDownloadManager sharedInstance] startDownloadTaskForKey:model.customKey];
            break;
        case LYFTaskStatusWaiting:
            [[LYFDownloadManager sharedInstance] startDownloadTaskForKey:model.customKey];
            break;
        default:
            break;
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end
