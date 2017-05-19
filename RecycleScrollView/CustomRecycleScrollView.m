//
//  CustomRecycleScrollView.m
//  test1
//
//  Created by 王建邦 on 2017/4/18.
//  Copyright © 2017年 王建邦. All rights reserved.
//

#import "CustomRecycleScrollView.h"
#import "UIButton+WebCache.h"
#import "UIImageView+WebCache.h"
#import "Masonry.h"

NSString * const sepIndex = @"INDEXS";
NSInteger const btnBaseTag = 65536;

@interface CustomRecycleScrollView ()<UIScrollViewDelegate>

@property(nonatomic,strong)UIScrollView *mainScr;
@property(nonatomic,strong)UIPageControl *pageControl;
@property(nonatomic,strong)NSArray *saveContainView;//存储可视+2个数量的容器view
@property(nonatomic,strong)NSMutableArray *saveBtnArr;//存储可视+2个数量的button
@property(nonatomic,strong)NSMutableArray *btnContentArr;//存储可视+2个数量的图片名称或者url,对应上边每个image
@property(nonatomic,strong)CADisplayLink *displayTimer;
@property(nonatomic,copy)dispatch_source_t scrTimer;
@property(nonatomic,assign)BOOL isTimmerRunning;
@property(nonatomic,assign)BOOL isOneScrDealFinish;
@property(nonatomic,assign)BOOL isSetDirection;
@property(nonatomic,assign)float avgWidth;
@property(nonatomic,assign)float avgHeight;
@property(nonatomic,assign)NSInteger sourceCount;//传入的图片或者图片url的数量

@end

@implementation CustomRecycleScrollView

-(id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if(self){
        [self createMain];
        _scrDirection = scr_horizonDirection;
        _showItemsCount = 1;
        _mainScr.pagingEnabled = YES;
        _scrInterval = 2;
        _isAutoScr = YES;
        _isTimmerRunning = 1;
        _isOneScrDealFinish = 1;
        _isSetDirection = 0;
        _showPageControl = 1;
        _framePerSecond = 30;
        _scrDealy = scr_type_dealy;
        self.saveBtnArr = [NSMutableArray array];
        self.btnContentArr = [NSMutableArray array];
    }
    return self;
}
-(void)createMain
{
    UIScrollView *mainScr = [[UIScrollView alloc]initWithFrame:self.bounds];
    _mainScr = mainScr;
    mainScr.showsHorizontalScrollIndicator = NO;
    mainScr.showsVerticalScrollIndicator = NO;
    mainScr.delegate = self;
    [self addSubview:mainScr];
    float x = (self.frame.size.width-120)/2;
    float y = self.frame.size.height-40;
    UIPageControl *pageCon = [[UIPageControl alloc]initWithFrame:CGRectMake(x, y, 120, 20)];
    _pageControl = pageCon;
    pageCon.hidesForSinglePage = YES;
    [self addSubview:pageCon];
}
-(void)setShowItemsCount:(NSInteger)showItemsCount
{
    _mainScr.pagingEnabled = (showItemsCount == 1);
    _showItemsCount = showItemsCount;
}
-(void)setScrDirection:(ScrDirection)scrDirection
{
    _scrDirection = scrDirection;
    _isSetDirection = YES;
}

-(void)setScrInterval:(float)scrInterval
{
    _scrInterval = MAX(scrInterval, .5);
}

-(void)setIsAutoScr:(BOOL)isAutoScr
{
    _isAutoScr = isAutoScr;
    if(!isAutoScr){
        if(_scrTimer){
            dispatch_cancel(_scrTimer);
            _scrTimer = nil;
        }
    }
}

-(void)setFramePerSecond:(NSInteger)framePerSecond
{
    NSInteger aa = MAX(framePerSecond, 1);
    aa = MIN(aa, 60);
    _framePerSecond = aa;
}

//处理图片数组
-(void)setImageArr:(NSArray *)imageArr
{
    [self stopTimer];
    NSInteger allCount = imageArr.count;
    _sourceCount = allCount;
    NSInteger recycleTimes = 1;
    while (recycleTimes*imageArr.count < _showItemsCount) {
        recycleTimes ++;
    }
    
    NSMutableArray *muArr = [NSMutableArray array];
    for(NSInteger k=0;k<recycleTimes;k++){
        for(NSInteger i=0;i<allCount;i++){
            NSString *urlStr = imageArr[i];
            urlStr = [NSString stringWithFormat:@"%@%@%ld",urlStr,sepIndex,(long)(i+k*allCount)];
            [muArr addObject:urlStr];
        }
    }
    _pageControl.numberOfPages = imageArr.count;
    _imageArr = [muArr copy];
    [self refreshScrContent];
    [self dealWithImageParam:_imageArr andIsUrl:NO];
}

//处理图片url数组
-(void)setGroupUrlArr:(NSArray *)groupUrlArr
{
    [self stopTimer];
    NSInteger allCount = groupUrlArr.count;
    _sourceCount = allCount;
    NSInteger recycleTimes = 1;
    while (recycleTimes*groupUrlArr.count < _showItemsCount) {
        recycleTimes ++;
    }
    
    NSMutableArray *muArr = [NSMutableArray array];
    for(NSInteger k=0;k<recycleTimes;k++){
        for(NSInteger i=0;i<allCount;i++){
            NSString *urlStr = groupUrlArr[i];
            urlStr = [NSString stringWithFormat:@"%@%@%ld",urlStr,sepIndex,(long)(i+k*allCount)];
            [muArr addObject:urlStr];
        }
    }
    _pageControl.numberOfPages = groupUrlArr.count;
    _groupUrlArr = [muArr copy];
    [self refreshScrContent];
    [self dealWithImageParam:_groupUrlArr andIsUrl:YES];
}

-(void)setBackgroundImage:(UIImage *)backgroundImage
{
    if(!_saveContainView.count) return;
    for(UIImageView *imageView in _saveContainView){
        imageView.image = backgroundImage;
    }
}

-(void)stopTimer
{
    if(_scrTimer){
        dispatch_suspend(_scrTimer);
    }
    if(_displayTimer)
        _displayTimer.paused = YES;
}

//加载滚屏上容器view
-(void)refreshScrContent
{
    [_btnContentArr removeAllObjects];
    [_saveBtnArr removeAllObjects];
    for(UIView *view in _mainScr.subviews){
        [view removeFromSuperview];
    }
    //创建showItemsCount+2个数量的view
    NSMutableArray *containerArr = [NSMutableArray array];
    if(_scrDirection == scr_horizonDirection){
        float avgWidth = self.frame.size.width/_showItemsCount;
        _avgWidth = avgWidth;
        _mainScr.contentSize = CGSizeMake(avgWidth*(_showItemsCount+2),0);
        //创建_showItemsCount+2个imageView
        for(NSInteger i=0;i<_showItemsCount+2;i++){
            UIImageView *bgImageView = [[UIImageView alloc]initWithImage:self.backgroundImage];
            bgImageView.userInteractionEnabled = YES;
            bgImageView.frame = CGRectMake(i*avgWidth, 0, avgWidth, self.frame.size.height);
            [_mainScr addSubview:bgImageView];
            [containerArr addObject:bgImageView];
            
            UIButton *bgBtn = [UIButton buttonWithType:UIButtonTypeCustom];
            bgBtn.tag = btnBaseTag+i;
            [bgBtn addTarget:self action:@selector(showImageInfo:) forControlEvents:UIControlEventTouchUpInside];
            [bgImageView addSubview:bgBtn];
            [bgBtn mas_makeConstraints:^(MASConstraintMaker *make) {
                make.center.mas_equalTo(bgImageView);
                make.size.mas_equalTo(CGSizeMake(avgWidth-6, avgWidth-6));
            }];
            [_saveBtnArr addObject:bgBtn];
        }
        [_mainScr setContentOffset:CGPointMake(avgWidth, 0)];
    }
    else{
        float avgHeight = _mainScr.frame.size.height/_showItemsCount;
        _avgHeight = avgHeight;
        _mainScr.contentSize = CGSizeMake(0, avgHeight*(_showItemsCount+2));
        _pageControl.hidden = YES;
        //创建_showItemsCount+2个imageView
        for(NSInteger i=0;i<_showItemsCount+2;i++){
            UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
            btn.tag = btnBaseTag+i;
            [btn addTarget:self action:@selector(showImageInfo:) forControlEvents:UIControlEventTouchUpInside];
            btn.frame = CGRectMake(0,i*avgHeight, _mainScr.frame.size.width, avgHeight);
            [_mainScr addSubview:btn];
            [_saveBtnArr addObject:btn];
        }
        [_mainScr setContentOffset:CGPointMake(0, avgHeight)];
    }
    _saveContainView = [containerArr copy];
}

//将容器中的view 附上值，并且开启定时器
-(void)dealWithImageParam:(NSArray *)paramArr andIsUrl:(BOOL)isurl
{
    if(_scrDirection == scr_verticalDirection || _showPageControl ==NO)
        _pageControl.hidden = YES;
    for(NSInteger i=0;i<self.saveBtnArr.count;i++){
        UIButton *btn = self.saveBtnArr[i];
        NSString *nameStr = nil;
        if(!i){
            nameStr = paramArr.lastObject;
        }
        else{
            nameStr = paramArr[(i-1)%paramArr.count];
        }
        [self.btnContentArr addObject:nameStr];
        nameStr = [[nameStr componentsSeparatedByString:sepIndex] firstObject];
        if(isurl){
            [btn sd_setImageWithURL:[NSURL URLWithString:nameStr] forState:UIControlStateNormal placeholderImage:[UIImage imageNamed:self.defaultImageStr]];
        }
        else{
            [btn setImage:[UIImage imageNamed:nameStr] forState:UIControlStateNormal];
        }
    }
    [self createTimer];
}

-(void)createTimer
{
    if(!_isAutoScr) return;
    if(_scrDealy == scr_type_dealy){
        if(_scrTimer){
            dispatch_resume(_scrTimer);
            return;
        }
        dispatch_source_t timer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, dispatch_get_main_queue());
        _scrTimer = timer;
        dispatch_source_set_timer(timer, DISPATCH_TIME_NOW, _scrInterval * NSEC_PER_SEC, .1 * NSEC_PER_SEC);
        dispatch_source_set_event_handler(timer, ^{
            [self dealWithScrWithDealy];
        });
        dispatch_resume(timer);
    }
    else{//连续滑动
        if(_displayTimer) {
            _displayTimer.paused = NO;
            return;
        }
        CADisplayLink *displaylinkTimer = [CADisplayLink displayLinkWithTarget:self selector:@selector(dealWithScrNoDealy)];
        _displayTimer = displaylinkTimer;
        if([[[UIDevice currentDevice] systemVersion] floatValue]<10)
            displaylinkTimer.frameInterval = _framePerSecond/60;//间隔多少帧调用一次
        else
            displaylinkTimer.preferredFramesPerSecond = _framePerSecond;//一秒钟调用多少次
        [displaylinkTimer addToRunLoop:[NSRunLoop currentRunLoop] forMode:NSRunLoopCommonModes];
    }
}

//处理定时器的滚动事件(带停顿效果)
-(void)dealWithScrWithDealy
{
    [UIView animateWithDuration:.5 animations:^{
        if(_scrDirection == scr_horizonDirection)
            self.mainScr.contentOffset = CGPointMake(_avgWidth*2, 0);
        else
            self.mainScr.contentOffset = CGPointMake(0, _avgHeight*2);
    } completion:^(BOOL finished) {
        //处理当前显示的图片数组
        if(finished){
            [self dealWithCurrentImageViewWithDirection:0];
        }
    }];
}

//处理定时器的滚动事件(不带停顿效果)
-(void)dealWithScrNoDealy
{
    float x = self.mainScr.contentOffset.x;
    float y = self.mainScr.contentOffset.y;
    x++;
    y++;
    if(_scrDirection == scr_horizonDirection)
        self.mainScr.contentOffset= CGPointMake(x, 0);
    else
        self.mainScr.contentOffset = CGPointMake(0, y);
}


#pragma mark 处理滚屏上的imageView ,dir:0:左或下，1：右或上
//处理数据（不带停顿的滚动，滑到一定范围需要预处理数据）
-(void)dealWithCurrentImageViewWithDirection:(BOOL)dir
{
    if(!_isOneScrDealFinish) return;
    NSString *needInsertStr = nil;
    NSInteger index = 0;
    NSArray *currentArr = self.imageArr.count?self.imageArr:self.groupUrlArr;
    if(dir){//向右、下滑
        [self.btnContentArr removeLastObject];
        NSString *firstStr = self.btnContentArr.firstObject;
        index = [currentArr indexOfObject:firstStr];
        if(index==0){
            needInsertStr = currentArr.lastObject;
        }
        else
            needInsertStr = currentArr[index-1];
        [self.btnContentArr insertObject:needInsertStr atIndex:0];
        //设置pageControll
        if(_pageControl.hidden == NO){
            NSInteger curIndex = _pageControl.currentPage - 1;
            if(curIndex < 0)
                _pageControl.currentPage = _pageControl.numberOfPages-1;
            else
                _pageControl.currentPage = curIndex;
        }
    }
    else{//左滑
        [self.btnContentArr removeObjectAtIndex:0];
        NSString *lastStr = self.btnContentArr.lastObject;
        index = [currentArr indexOfObject:lastStr];
        if(index == currentArr.count-1){
            needInsertStr = currentArr.firstObject;
        }
        else
            needInsertStr = currentArr[index+1];
        [self.btnContentArr addObject:needInsertStr];
        //设置pageControll
        if(_pageControl.hidden == NO){
            NSInteger curIndex = _pageControl.currentPage + 1;
            if(curIndex > _pageControl.numberOfPages-1)
                _pageControl.currentPage = 0;
            else
                _pageControl.currentPage = curIndex;
            
        }
    }
    [self refreshContentWithData];
}

//刷新界面
-(void)refreshContentWithData
{
    BOOL isUrl = (self.imageArr.count == 0);
    for(NSInteger i=0;i<self.btnContentArr.count;i++){
        UIButton *btn = self.saveBtnArr[i];
        NSString *nameStr = [[self.btnContentArr[i] componentsSeparatedByString:sepIndex] firstObject];
        if(isUrl){
            [btn sd_setImageWithURL:[NSURL URLWithString:nameStr] forState:UIControlStateNormal];
        }
        else{
            [btn setImage:[UIImage imageNamed:nameStr] forState:UIControlStateNormal];
        }
    }
    //将scrollView归位
    if(_scrDirection == scr_horizonDirection)
        self.mainScr.contentOffset = CGPointMake(_avgWidth, 0);
    else
        self.mainScr.contentOffset = CGPointMake(0, _avgHeight);
    _isOneScrDealFinish = 1;
}

//处理上边的点击事件
-(void)showImageInfo:(UIButton *)btn
{
    NSInteger index1 = btn.tag-btnBaseTag;
    NSString *name = self.btnContentArr[index1];
    NSArray *currentArr = self.imageArr.count?self.imageArr:self.groupUrlArr;
    NSInteger index2 = [currentArr indexOfObject:name];
    if(self.goodsSelectBlock)
        self.goodsSelectBlock(index2%_sourceCount);
}

#pragma mark scrollView delegate

-(void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    if(!_isOneScrDealFinish) return;
    if(_scrDealy == scr_type_dealy && _isTimmerRunning == 1){
        return;
    }
    if(_scrDirection == scr_horizonDirection ){
        float offsetX = scrollView.contentOffset.x;
        if(offsetX>=_avgWidth*2){
            [self dealWithCurrentImageViewWithDirection:0];
        }
        else if (offsetX<=0){
            [self dealWithCurrentImageViewWithDirection:1];
        }
    }
    else{
        float offsetY = scrollView.contentOffset.y;
        if(offsetY >= _avgHeight*2){
            [self dealWithCurrentImageViewWithDirection:0];
        }
        else if(offsetY<=0){
            [self dealWithCurrentImageViewWithDirection:1];
        }
    }
}
-(void)scrollViewWillBeginDragging:(UIScrollView *)scrollView
{
    [self stopScrollAnnimation];
}
-(void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate
{
    if(!decelerate)
        [self beginScrollAnnimation];
}
-(void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
    [self beginScrollAnnimation];
}

-(void)beginScrollAnnimation
{
    if(_scrDealy == scr_type_dealy){
        if(!_scrTimer || _isTimmerRunning) return;
        dispatch_resume(_scrTimer);
        _isTimmerRunning = 1;
    }
    else{
        _displayTimer.paused = NO;
        _isTimmerRunning = YES;
    }
}
-(void)stopScrollAnnimation
{
    if(_scrDealy == scr_type_dealy){
        if(!_scrTimer || !_isTimmerRunning) return;
        dispatch_suspend(_scrTimer);
        _isTimmerRunning = 0;
    }
    else{
        _displayTimer.paused = YES;
        _isTimmerRunning = NO;
    }
}


-(void)dealloc
{
    if(_scrTimer){
        dispatch_cancel(_scrTimer);
        _scrTimer = nil;
    }
    if(_displayTimer){
        [_displayTimer removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSRunLoopCommonModes];
        [_displayTimer invalidate];
        _displayTimer = nil;
    }
}

-(void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    [self stopScrollAnnimation];

}


@end
