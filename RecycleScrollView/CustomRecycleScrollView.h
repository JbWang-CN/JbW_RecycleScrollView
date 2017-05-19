//
//  CustomRecycleScrollView.h
//  test1
//
//  Created by 王建邦 on 2017/4/18.
//  Copyright © 2017年 王建邦. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef NS_ENUM(NSInteger,ScrDirection) {
    scr_horizonDirection,
    scr_verticalDirection,
};

typedef NS_ENUM(NSInteger,ScrType) {
    scr_type_NoDealy = 1<<1,
    scr_type_dealy  = 1<<2,
};

typedef void(^SelectBlock)(NSInteger index);

@interface CustomRecycleScrollView : UIView

/**
 滚动方向，默认是水平方向,这个属性要优先设置
 */
@property(nonatomic,assign)ScrDirection scrDirection;

/**
 一屏显示几张图片 默认是1
 */
@property(nonatomic,assign)NSInteger showItemsCount;

/**
 自动滚动时间 默认2s
 */
@property(nonatomic,assign)float scrInterval;

/**
 是否自动滚动
 */
@property(nonatomic,assign)BOOL isAutoScr;

/**
 是否有停顿的滚动
 */
@property(nonatomic,assign)ScrType scrDealy;
/**
 如果是连续滚动，每秒多少像素，最大60 最小1,默认30
 */
@property(nonatomic,assign)NSInteger framePerSecond;

/**
 默认的背景图
 */
@property(nonatomic,strong)NSString *defaultImageStr;

/**
 是否显示pageController
 */
@property(nonatomic,assign)BOOL showPageControl;

/**
    设置容器背景图
 */
@property(nonatomic,strong)UIImage *backgroundImage;

/**
 指定的图片数组 要在上面的属性设置之后再设置当前属性
 */
@property(nonatomic,strong)NSArray *imageArr;
/**
 指定的图片url数组 要在上面的属性设置之后再设置当前属性(与上边的数组互斥！！！)
 */
@property(nonatomic,strong)NSArray *groupUrlArr;

//点击某一张图片的回调
@property(nonatomic,copy)SelectBlock goodsSelectBlock;


-(void)stopScrollAnnimation;

-(void)beginScrollAnnimation;


@end
