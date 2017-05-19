//
//  ViewController.m
//  RecycleScrollView
//
//  Created by 王建邦 on 2017/5/19.
//  Copyright © 2017年 王建邦. All rights reserved.
//

#import "ViewController.h"

#import "CustomRecycleScrollView.h"
#define SCREEN_HEIGHT  [UIScreen mainScreen].bounds.size.height
#define SCREEN_WIDTH  [UIScreen mainScreen].bounds.size.width

@interface ViewController ()
{
    CustomRecycleScrollView *_recycleScrollView;
}
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    CustomRecycleScrollView *recycle = [[CustomRecycleScrollView alloc]initWithFrame:CGRectMake(0, SCREEN_HEIGHT-46-64-100, SCREEN_WIDTH, 100)];
    _recycleScrollView = recycle;
    _recycleScrollView.showItemsCount = 5;
    _recycleScrollView.showPageControl = 1;
    _recycleScrollView.framePerSecond = 60;
    _recycleScrollView.backgroundImage = [UIImage imageNamed:@"csd"];
    _recycleScrollView.scrDealy = scr_type_NoDealy;
//    _recycleScrollView.scrDealy = scr_type_dealy;
    [self.view addSubview:recycle];
    //回调处理
    recycle.goodsSelectBlock = ^(NSInteger index){
        NSLog(@"%ld",index);
    };
    //赋值
    
    _recycleScrollView.imageArr = @[@"11.png",@"22.png",@"33.png",@"44.png",@"55.png"];
    
    /**  url数组 */
    //    _recycleScrollView.gropuUrlArr = @[];
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
