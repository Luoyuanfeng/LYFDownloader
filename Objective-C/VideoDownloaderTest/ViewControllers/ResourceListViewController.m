//
//  ResourceListViewController.m
//  VideoDownloaderTest
//
//  Created by 罗元丰 on 2017/2/23.
//  Copyright © 2017年 罗元丰. All rights reserved.
//

#import "ResourceListViewController.h"
#import "DownloadMamageViewController.h"
#import "DownloadManageCell.h"

#import "LYFDownloadManager.h"

@interface ResourceListViewController () <UITableViewDelegate, UITableViewDataSource, DownloadManageCellDelegate>

@property (nonatomic, strong) UITableView *table;
@property (nonatomic, strong) NSArray     *resourceArray;

@end

@implementation ResourceListViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    _resourceArray = @[@"http://enc-mp4.highso.com.cn/1612/VWATTUIH/66a7c464cb786b736642088fdf7a5510.mp4",
                       @"http://enc-mp4.highso.com.cn/1605/HHCXPWER/216d4b82b6ee7ed33f3306cdcb55370e.mp4",
                       @"http://enc-mp4.highso.com.cn/1606/QUERXYWW/4c8ce769ab4da13057ff5476732b93bd.mp4",
                       @"http://enc-mp4.highso.com.cn/1606/HDJOGRYM/7aa5a702dcf2592f6e4321d9411cb4f1.mp4",
                       @"http://enc-mp4.highso.com.cn/1606/UIHWDWGC/e3d41d5f4a8ee223c8321b73325b8e70.mp4",
                       @"http://enc-mp4.highso.com.cn/1606/DEACJGHM/c9026aa1bc1e18853bf22ebce73ef2ff.mp4",
                       @"http://enc-mp4.highso.com.cn/1606/IRGWTGTN/5d8c0a64956bb6efd18122d588a2a94e.mp4",
                       @"http://enc-mp4.highso.com.cn/1606/QVXPIUKW/67fbfd4ed50e2d6c5a495a4a2747c4a3.mp4",
                       @"http://dlsw.baidu.com/sw-search-sp/soft/9d/25765/sogou_mac_32c_V3.2.0.1437101586.dmg",
                       @"https://timgsa.baidu.com/timg?image&quality=80&size=b9999_10000&sec=1487849376539&di=b033c0a468ba2aaf7ac533d4fe3e4d4b&imgtype=0&src=http%3A%2F%2Fimg2.niushe.com%2Fupload%2F201304%2F19%2F14-22-31-71-26144.jpg"];
    
    self.navigationItem.title = @"Resource List";
    self.view.backgroundColor = [UIColor lightGrayColor];
    
    self.table = [[UITableView alloc] initWithFrame:CGRectMake(0, 30, self.view.bounds.size.width, self.view.bounds.size.height - 30) style:UITableViewStylePlain];
    self.table.dataSource = self;
    self.table.delegate = self;
    self.table.separatorStyle = UITableViewCellSeparatorStyleNone;
    [self.table registerNib:[UINib nibWithNibName:@"DownloadManageCell" bundle:[NSBundle mainBundle]] forCellReuseIdentifier:@"cell"];
    [self.view addSubview:self.table];
    
    UIBarButtonItem *right = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemPlay target:self action:@selector(goManage)];
    self.navigationItem.rightBarButtonItem = right;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return _resourceArray.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    DownloadManageCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell" forIndexPath:indexPath];
    cell.urlStr = _resourceArray[indexPath.row];
    cell.delegate = self;
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return [self getH:_resourceArray[indexPath.row]] + 80;
}

- (void)goManage
{
    DownloadMamageViewController *vc = [[DownloadMamageViewController alloc] init];
    [self.navigationController pushViewController:vc animated:YES];
}

- (void)download:(NSString *)url sender:(UIButton *)btn
{
    NSString *customKey = [url componentsSeparatedByString:@"/"].lastObject;
    [[LYFDownloadManager sharedInstance] addDownloadTaskForKey:customKey
                                                           url:url
                                                    createTime:[[NSDate date] timeIntervalSince1970] * 1000
                                                        status:LYFTaskStatusNew
                                                    customInfo:nil
                                              expectedFileName:nil
                                             expectedDirectory:nil];
}

- (CGFloat)getH:(NSString *)str
{
    CGRect rect = [str boundingRectWithSize:CGSizeMake([UIScreen mainScreen].bounds.size.width - 20, 10000) options:NSStringDrawingUsesFontLeading | NSStringDrawingUsesLineFragmentOrigin attributes:@{NSFontAttributeName : [UIFont systemFontOfSize:15]} context:nil];
    return rect.size.height;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

@end
