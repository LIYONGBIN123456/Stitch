//
//  HomeViewController.m
//  YXStitch
//
//  Created by xwan-iossdk on 2022/8/8.
//

#import "HomeViewController.h"
#import "HomeSettingViewController.h"
#import "MoveCollectionViewCell.h"
#import "EnterURLViewController.h"
#import "SettingViewController.h"
#import <AVKit/AVKit.h>
#import <AVFoundation/AVFoundation.h>
#import <ReplayKit/ReplayKit.h>
#import "ScrrenStitchHintView.h"
#import "SaveViewController.h"
#import "GuiderVisitorView.h"
#import "WaterMarkViewController.h"
#import "SelectPictureViewController.h"
#import "CaptionViewController.h"
#import "CustomScrollView.h"
#import "UIScrollView+UITouch.h"
#import "CaptionViewController.h"
#import "UIView+HXExtension.h"
#import "KSViewController.h"
#import "UnlockFuncView.h"
#import "BuyViewController.h"
#import "CheckProView.h"
#import "PictureLayoutController.h"
#import "ImageEditViewController.h"
#import "XWOpenCVHelper.h"
#import "App.h"
#import "HomeModel.h"
#import "SZStichingImageView.h"


//#include "opencv2/opencv.hpp"
//#include "opencv2/features2d.hpp"
//#include "opencv2/calib3d.hpp"
//#include "opencv2/flann.hpp"
//#include <vector>
//#include <iostream>
//using namespace std;
//using namespace cv;


@interface HomeViewController ()<UICollectionViewDelegate,UICollectionViewDataSource,MoveCollectionViewCellDelegate,ScrrenStitchHintViewDelegate,HXPhotoViewDelegate,UIImagePickerControllerDelegate, HXPhotoViewCellCustomProtocol,HXCustomNavigationControllerDelegate,UnlockFuncViewDelegate,CheckProViewDelegate>

@property (nonatomic ,strong)UIView *iconView;
@property (nonatomic ,strong)UICollectionView *MJColloctionView;
@property (nonatomic ,strong)NSMutableArray *iconArr;
@property (nonatomic ,strong)NSMutableArray *schemeArr;
@property (nonatomic ,strong)NSMutableArray *nameArr;
@property (nonatomic ,strong)NSMutableArray *urlArr;

@property (nonatomic ,strong)UIView * shotView;
@property (nonatomic ,strong)NSIndexPath * indexPath;
@property (nonatomic ,strong)NSIndexPath * nextIndexPath;
@property (nonatomic ,weak) MoveCollectionViewCell * originalCell;
@property (nonatomic, strong)SZImageGenerator *generator;
@property (nonatomic ,strong)ScrrenStitchHintView *checkScreenStitchView;

@property (nonatomic ,strong)StitchResultView *resultView;
@property (nonatomic ,strong)GuiderVisitorView *guiderView;

@property (strong, nonatomic) HXPhotoManager *manager;
@property (weak, nonatomic) HXPhotoView *photoView;
@property (strong, nonatomic) UIScrollView *scrollView;
@property (nonatomic ,strong)HXPhotoBottomView *bottomView;
@property (assign, nonatomic) BOOL needDeleteItem;
@property (assign, nonatomic) BOOL showHud;
@property (nonatomic, strong)NSTimer *reTimer;
@property (nonatomic ,assign)BOOL isOpenAlbum;
@property (nonatomic ,assign)NSInteger showBottomViewStatus;
@property (nonatomic ,strong)UIButton *clearBtn;
@property (nonatomic ,assign)NSInteger selectInex;
@property (nonatomic ,strong)UnlockFuncView *funcView;
@property (nonatomic ,strong)CheckProView *checkProView;
@property (nonatomic ,strong)UIView *bgView;

@property (nonatomic ,strong)NSMutableArray *stitchArr;
@property (nonatomic ,strong)NSURL *videoURL;
@property (nonatomic ,assign)BOOL isScrollScreen;

@end

@implementation HomeViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    self.title = @"首页";
    _isScrollScreen = NO;
    GVUserDe.isScorllScreen = _isScrollScreen;
    if (GVUserDe.waterPosition <= 1){
        GVUserDe.waterPosition = 1;
    }
    if (GVUserDe.selectColorArr.count == 0){
        GVUserDe.selectColorArr = [NSMutableArray arrayWithObject:@"#E35AF6"];
    }
    
    if (GVUserDe.homeIconArr.count >0){
        _iconArr = [NSMutableArray arrayWithArray:GVUserDe.homeIconArr];
    }else{
        _iconArr = [NSMutableArray arrayWithObjects:@"截长屏",@"网页滚动截图",@"拼图",@"水印",@"设置",@"更多功能",nil];
        
    }
    [self requestData];
    [self setupViews];
    [self setupLayout];
    [self setupNavItems];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(noty:) name:@"homeChange" object:nil];
    //检测连续截图
    if (GVUserDe.isAutoCheckRecentlyIMG) {
        [SVProgressHUD showWithStatus:@"自动检测到有连续截图"];
        [self screenStitchWithType:1];
    }
    
    [self addObserver];
    if (GVUserDe.isHaveScreenData){
        GVUserDe.isHaveScreenData = NO;
        App *app = [App sharedInstance];
        _videoURL = app.videoURL;
        _isScrollScreen = YES;
        GVUserDe.isScorllScreen = _isScrollScreen;
        [self addScrrenData];
    }
}

- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection {
    [super traitCollectionDidChange:previousTraitCollection];
#ifdef __IPHONE_13_0
    if (@available(iOS 13.0, *)) {
        [self preferredStatusBarUpdateAnimation];
        [self changeStatus];
    }
#endif
}
- (UIStatusBarStyle)preferredStatusBarStyle {
#ifdef __IPHONE_13_0
    if (@available(iOS 13.0, *)) {
        if (UITraitCollection.currentTraitCollection.userInterfaceStyle == UIUserInterfaceStyleDark) {
            return UIStatusBarStyleLightContent;
        }
    }
#endif
    return UIStatusBarStyleDefault;
}

-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    _isOpenAlbum = NO;
    _showBottomViewStatus = 0;
    _selectInex = 0;
    _reTimer = [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(timerMethod) userInfo:nil repeats:YES];
    [self changeStatus];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self changeStatus];
}

-(void)viewDidDisappear:(BOOL)animated{
    [super viewDidDisappear:animated];
    
}
-(void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:animated];
    if (_reTimer != nil){
        [self destoryTimer];
    }
}

-(void)addObserver{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(openAlbum:) name:@"openAlbum" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(closeAlbum:) name:@"closeAlbum" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(screenRecordFinish:) name:kScreenRecordFinishNotification object:nil];
}

- (void)noty:(NSNotification *)noty {
    NSDictionary *dict = noty.userInfo;
    _iconArr = dict[@"iconArr"];
    GVUserDe.homeIconArr = _iconArr;
    [_MJColloctionView reloadData];
}
-(void)screenRecordStart:(NSNotification *)noty{
    //录屏开始的通知
    
}

- (void)screenRecordFinish:(NSNotification *)noty{
    //录屏结束通知 拼接图片
    NSDictionary *dict = noty.userInfo;
    _videoURL = dict[@"videoURL"];
    NSLog(@"_videorul==%@",_videoURL);
    GVUserDe.isHaveScreenData = NO;
    _isScrollScreen = YES;
    GVUserDe.isScorllScreen = _isScrollScreen;
    [self addScrrenData];
    
}

-(void)addScrrenData{
    MJWeakSelf
    [self.stitchArr removeAllObjects];
    NSMutableArray *tempArr = [NSMutableArray array];
    __block NSInteger allSameCount = 1;
  //  [SVProgressHUD showWithStatus:@"检测到有滚动截图，正在为你生成图片"];
    if (_videoURL){
        [[HandlerVideo sharedInstance]splitVideo:_videoURL fps:1 progressImageBlock:^(CGFloat progress) {
            if (progress >= 1) {
                for (NSInteger i = 0 ; i < tempArr.count; i ++) {
                    if ( i < tempArr.count - 1){
                        cv::Mat matImage = [XWOpenCVHelper cvMatFromUIImage:tempArr[i]];
                        cv::Mat matNextImage = [XWOpenCVHelper cvMatFromUIImage:tempArr[i + 1]];
                        int hashValue = aHash(matImage, matNextImage);
                        NSLog(@"hashValue==%d",hashValue);
                        if (hashValue >= 5){
                            [weakSelf.stitchArr addObject:tempArr[i]];
//                            UIImageWriteToSavedPhotosAlbum(tempArr[i], self, @selector(image:didFinishSavingWithError:contextInfo:), NULL);

                        }
                        if (hashValue == 0){
                            allSameCount ++;
                        }
                    }
                }
                if (allSameCount == tempArr.count){
                    [weakSelf.stitchArr addObject:tempArr.firstObject];
                }
                if (tempArr.count > 0){
                    [weakSelf.stitchArr addObject:tempArr.lastObject];
                }
                
                [weakSelf screenStitchWithType:3];
                [SVProgressHUD dismiss];
                NSLog(@"stitchArr.count==%ld",weakSelf.stitchArr.count);
            }
        } splitCompleteBlock:^(BOOL success, UIImage *splitimg) {
            if (success && splitimg) {
                [tempArr addObject:splitimg];
            }
        }];
    }
}

-(void)image:(UIImage *)image didFinishSavingWithError:(NSError *)error contextInfo:(void *)contextInfo{
    NSString *msg = nil;
    if (!error) {
        msg = @"保存成功，已为您保存至相册";
    }else {
        msg = @"系统未授权访问您的照片，请您在设置中进行权限设置后重试";
    }
    NSLog(@"msg=%@",msg);
}

-(void)requestData{
    MJWeakSelf
    [[XWNetTool sharedInstance] queryApplicationListWithCallback:^(NSArray<HomeModel *> * _Nullable dataSources, BOOL isProcessing, NSString * _Nullable errorMsg) {
        if (!errorMsg && isProcessing) {
            for (HomeModel *model in dataSources) {
                [weakSelf.iconArr insertObject:model.image atIndex:(model.sort - 1)];
                if(model.title){
                    [weakSelf.nameArr addObject:model];
                }
                if (model.scheme){
                    [weakSelf.schemeArr addObject:model.scheme];
                }
                
            }
            dispatch_async(dispatch_get_main_queue(), ^ {
                [weakSelf.MJColloctionView reloadData];
            });
        }
    }];
}
#pragma mark - UI
-(void)setupViews{
    UICollectionViewFlowLayout * layout = [[UICollectionViewFlowLayout alloc] init];
    CGFloat sizeWidth = (CGFloat) 168 / 375  * SCREEN_WIDTH;
    CGFloat sizeHeight = (CGFloat) 160 / 667  * SCREEN_HEIGHT;
    layout.itemSize = CGSizeMake(sizeWidth, sizeHeight);
    _MJColloctionView = [[UICollectionView alloc]initWithFrame:CGRectMake(0, Nav_H,SCREEN_WIDTH,SCREEN_HEIGHT - Nav_H) collectionViewLayout:layout];
    [_MJColloctionView registerClass:[MoveCollectionViewCell class] forCellWithReuseIdentifier:@"MoveCollectionViewCell"];
    _MJColloctionView.dataSource = self;
    _MJColloctionView.delegate = self;
    _MJColloctionView.backgroundColor = HexColor(BKGrayColor);
    [self.view addSubview:_MJColloctionView];
}

-(void)setupLayout{
    
}

-(void)setupNavItems{
    UIButton *leftBtn = [UIButton buttonWithType:UIButtonTypeSystem];
    [leftBtn setBackgroundImage:[UIImage imageNamed:@"水滴"] forState:UIControlStateNormal];
    [leftBtn addTarget:self action:@selector(leftBtnClick:) forControlEvents:UIControlEventTouchUpInside];
    UIBarButtonItem *item = [[UIBarButtonItem alloc]initWithCustomView:leftBtn];
    self.navigationItem.leftBarButtonItem = item;
}
-(void)setupBottomViewWithType:(NSInteger )type{
    [_bottomView removeAllSubviews];
    if(type == 1){
        UILabel *tipLab = [UILabel new];
        tipLab.text = @"点击或滑动来选择图片";
        tipLab.font = FontBold(16);
        tipLab.textAlignment = NSTextAlignmentCenter;
        [_bottomView addSubview:tipLab];
        [tipLab mas_makeConstraints:^(MASConstraintMaker *make) {
            make.centerX.centerY.equalTo(_bottomView);
        }];
    }else {
        NSArray *iconArr ;
        NSArray *textArr;
        if (type == 2){
            iconArr = @[@"裁切icon",@"黑编辑icon"];
            textArr = @[@"裁切",@"编辑"];
        }else{
            iconArr = @[@"截长屏icon",@"拼接icon",@"布局icon",@"字幕icon"];
            textArr = @[@"截长屏",@"拼接",@"布局",@"字幕"];
        }
        CGFloat btnWidth = _bottomView.width / iconArr.count;
        for (NSInteger i = 0; i < iconArr.count; i ++) {
            UIButton *btn = [UIButton buttonWithType:UIButtonTypeSystem];
            btn.tag = type * 100 + i;
            [btn addTarget:self action:@selector(imgEdit:) forControlEvents:UIControlEventTouchUpInside];
            [_bottomView addSubview:btn];
            [btn mas_makeConstraints:^(MASConstraintMaker *make) {
                make.width.equalTo(@(btnWidth));
                make.height.top.equalTo(_bottomView);
                make.left.equalTo(@( i * btnWidth));
            }];
            
            UIImageView *icon = [UIImageView new];
            icon.image = IMG(iconArr[i]);
            [btn addSubview:icon];
            [icon mas_makeConstraints:^(MASConstraintMaker *make) {
                make.width.height.equalTo(@22);
                make.centerX.equalTo(btn);
                make.top.equalTo(@8);
            }];
            
            UILabel *textLab = [UILabel new];
            textLab.textAlignment = NSTextAlignmentCenter;
            textLab.text = textArr[i];
            textLab.font = Font13;
            textLab.textColor = [UIColor blackColor];
            [btn addSubview:textLab];
            [textLab mas_makeConstraints:^(MASConstraintMaker *make) {
                make.width.left.equalTo(btn);
                make.top.equalTo(icon.mas_bottom).offset(4);
            }];
        }
    }
}
        
#pragma mark -- CollectionDelegate

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section{
    return _iconArr.count;
}
- (UIEdgeInsets)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout insetForSectionAtIndex:(NSInteger)section{
    return UIEdgeInsetsMake(20, 10, 10, 10);
}
- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath{
    
    MoveCollectionViewCell * cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"MoveCollectionViewCell" forIndexPath:indexPath];
    cell.p_MoveCollectionViewCellDelegate = self;
    NSString *cellName;
    NSString *iconName;
    if (_nameArr.count > 0){
        if (indexPath.row <= _nameArr.count -1){
            HomeModel *model = _nameArr[indexPath.row];
            cellName = model.title;
            iconName = [_iconArr objectAtIndex:indexPath.row];
        }else{
            cellName = [_iconArr objectAtIndex:indexPath.row];
            iconName = cellName;
        }
    }else{
        cellName = [_iconArr objectAtIndex:indexPath.row];
        iconName = cellName;
    }
    [cell setTitleWithName:cellName andIconIMG:iconName];

    return cell;
}
-(void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath{
    //得到的cell
    MoveCollectionViewCell * cell = (MoveCollectionViewCell *)[self collectionView:collectionView cellForItemAtIndexPath:indexPath];
    NSString *cellName = cell.cellName;
    //跳转
    UIViewController *vc;
    if ([cellName isEqualToString:@"截长屏"]){
        _isScrollScreen = NO;
        GVUserDe.isScorllScreen = _isScrollScreen;
        [self screenStitchWithType:2];
    }else if ([cellName isEqualToString:@"网页滚动截图"]){
        vc = [EnterURLViewController new];
    }else if ([cellName isEqualToString:@"拼图"]){
        _isOpenAlbum = YES;
        HXCustomNavigationController *nav = [[HXCustomNavigationController alloc] initWithManager:self.manager delegate:self];
        nav.modalPresentationStyle = UIModalPresentationOverFullScreen;
        nav.modalPresentationCapturesStatusBarAppearance = YES;
        [self.view.viewController presentViewController:nav animated:YES completion:nil];
        return;
    }else if ([cellName isEqualToString:@"水印"]){
        vc = [WaterMarkViewController new];
    }else if ([cellName isEqualToString:@"设置"]){
        vc = [SettingViewController new];
    }else if ([cellName isEqualToString:@"更多功能"]){
        //更多功能
        vc = [HomeSettingViewController new];
    }else{
        //用来跳转
        HomeModel *model = _nameArr[indexPath.row];
        if ([cellName isEqualToString:@"卡坦"]){  
            if (![self checkAPPIsExist:@"wx22ffa29d07dc4d59://"]){
                //NSLog(@"未安装");
                NSURL *url = [NSURL URLWithString:model.url];
                [[UIApplication sharedApplication]openURL:url options:nil completionHandler:^(BOOL success) {
                                    
                }];
            }else{
               //NSLog(@"安装");
                NSURL *url = [NSURL URLWithString:model.scheme];
                [[UIApplication sharedApplication]openURL:url options:nil completionHandler:^(BOOL success) {
                                    
                }];
            }
        }else{
            NSURL *url = [NSURL URLWithString:model.url];
            [[UIApplication sharedApplication]openURL:url options:nil completionHandler:^(BOOL success) {
                                
            }];
        }
        [self setClickMoment];
        return;
    }
    [self.navigationController pushViewController:vc animated:YES];
}

-(void)setClickMoment{
    //发送点击,后端统计请求
    NSDictionary *params;
    params = @{
        @"id":@"1"
    };
    [[XWNetTool sharedInstance]getRequestWithUrl:API_SUMCLICKCOUNT withParam:params success:^(id  _Nullable responseObject) {
        NSLog(@"responseObject==%@",responseObject);
        NSInteger errorCode = [responseObject[@"error"] integerValue];
        if (errorCode == CodeSuccess) {
            NSLog(@"成功");
        }
    } failure:^(NSError * _Nonnull error) {
       // NSLog(@"error==%@",error);
    }];
}

-(void)GesturePressDelegate:(UIGestureRecognizer *)gestureRecognizer
{
    if ([[[UIDevice currentDevice] systemVersion] floatValue] >9) {
        switch (gestureRecognizer.state) {
            case UIGestureRecognizerStateBegan:{
                //判断手势落点位置是否在路径上
                NSIndexPath *indexPath = [_MJColloctionView indexPathForItemAtPoint:[gestureRecognizer locationInView:self.MJColloctionView]];
                if (indexPath == nil) {
                    break;
                }
                //在路径上则开始移动该路径上的cell
                [_MJColloctionView beginInteractiveMovementForItemAtIndexPath:indexPath];
            }
                break;
            case UIGestureRecognizerStateChanged:
                //移动过程当中随时更新cell位置
                [_MJColloctionView updateInteractiveMovementTargetPosition:[gestureRecognizer locationInView:self.MJColloctionView]];
                break;
            case UIGestureRecognizerStateEnded:
                //移动结束后关闭cell移动
                [_MJColloctionView endInteractiveMovement];
                break;
            default:
                [_MJColloctionView cancelInteractiveMovement];
                break;
        }

    }else{
        MoveCollectionViewCell* cell = (MoveCollectionViewCell*)gestureRecognizer.view;
        static CGPoint startPoint;
        if (gestureRecognizer.state == UIGestureRecognizerStateBegan) {
            _shotView = [cell snapshotViewAfterScreenUpdates:NO];
            _shotView.center = cell.center;
            
            NSLog(@"%@",cell.description);
            NSLog(@"%@",_shotView.description);
            [_MJColloctionView addSubview:_shotView];
            _indexPath = [_MJColloctionView indexPathForCell:cell];
            _originalCell = cell;
            _originalCell.hidden = YES;
            startPoint = [gestureRecognizer locationInView:_MJColloctionView];
        }else if (gestureRecognizer.state == UIGestureRecognizerStateChanged)
        {
            //获取移动量
            CGFloat tranX = [gestureRecognizer locationOfTouch:0 inView:_MJColloctionView].x - startPoint.x;
            CGFloat tranY = [gestureRecognizer locationOfTouch:0 inView:_MJColloctionView].y - startPoint.y;
            
            //进行移动
            _shotView.center = CGPointApplyAffineTransform(_shotView.center, CGAffineTransformMakeTranslation(tranX, tranY));
            //更新初始位置
            startPoint = [gestureRecognizer locationOfTouch:0 inView:_MJColloctionView];
            for (UICollectionViewCell *cellVisible in [_MJColloctionView visibleCells])
            {
                //移动的截图与目标cell的center直线距离
                CGFloat space = sqrtf(pow(_shotView.center.x - cellVisible.center.x, 2) + powf(_shotView.center.y - cellVisible.center.y, 2));
                //判断是否替换位置，通过直接距离与重合程度
                if (space <= _shotView.frame.size.width/2&&(fabs(_shotView.center.y-cellVisible.center.y) <= _shotView.bounds.size.height/2)) {
                    _nextIndexPath = [_MJColloctionView indexPathForCell:cellVisible];
                    if (_nextIndexPath.item > _indexPath.item)
                    {
                        for(NSInteger i = _indexPath.item; i <_nextIndexPath.item;i++)
                        {
                            //移动数据源位置
                            [_iconArr exchangeObjectAtIndex:i withObjectAtIndex:i+1];
                        }
                    }else
                    {
                        for(NSInteger i = _indexPath.item; i <_nextIndexPath.item;i--)
                        {
                            //移动数据源位置
                            [_iconArr exchangeObjectAtIndex:i withObjectAtIndex:i-1];
                        }
                    }
                    //移动视图cell位置
                    [_MJColloctionView moveItemAtIndexPath:_indexPath toIndexPath:_nextIndexPath];
                    //更新移动视图的数据
                    _indexPath = _nextIndexPath;
                    break;
                }
            }
        }else if (gestureRecognizer.state == UIGestureRecognizerStateEnded)
        {
            [_shotView removeFromSuperview];
            [_originalCell setHidden:NO];
        }

    }
}

-(BOOL)collectionView:(UICollectionView *)collectionView canMoveItemAtIndexPath:(NSIndexPath *)indexPath{
    return YES;
}

- (void)collectionView:(UICollectionView *)collectionView moveItemAtIndexPath:(NSIndexPath *)sourceIndexPath toIndexPath:(NSIndexPath*)destinationIndexPath {
    id objc = [_iconArr objectAtIndex:sourceIndexPath.item];
    [_iconArr removeObject:objc];
    [_iconArr insertObject:objc atIndex:destinationIndexPath.item];
    GVUserDe.homeIconArr = _iconArr;
}

#pragma mark --长图识别
-(void)screenStitchWithType:(NSInteger)type{
    //自动识别长图
    if (type != 3){
        if (type == 2){
            [SVProgressHUD showWithStatus:@"正在检测是否有连续截图..."];
        }
        _stitchArr = [Tools detectionScreenShotIMG];
    }
    //触发提示
    MJWeakSelf
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [SVProgressHUD dismiss];
        if (weakSelf.bgView == nil){
            weakSelf.bgView = [Tools addBGViewWithFrame:self.view.frame];
            [weakSelf.view addSubview:weakSelf.bgView];
        }else{
            weakSelf.bgView.hidden = NO;
        }
        weakSelf.checkScreenStitchView = [ScrrenStitchHintView new];
        weakSelf.checkScreenStitchView.frame = CGRectMake(0, SCREEN_HEIGHT, SCREEN_WIDTH, RYRealAdaptWidthValue(550));
        weakSelf.checkScreenStitchView.delegate = self;
        weakSelf.checkScreenStitchView.type = type;
        if (type == 3){
            [SVProgressHUD showWithStatus:@"滚动截图正在拼接中..."];
        }else{
            if (weakSelf.stitchArr.count > 1){
                //连续截图数量大于2才能去拼接
                [SVProgressHUD showWithStatus:@"滚动截图正在拼接中..."];
            }else{
                weakSelf.checkScreenStitchView.type = 1;
            }
        }
        weakSelf.checkScreenStitchView.arr = weakSelf.stitchArr;
        weakSelf.checkScreenStitchView.delegate = self;
        [weakSelf.view addSubview:weakSelf.checkScreenStitchView];
        [UIView animateWithDuration:0.3 animations:^{
            weakSelf.checkScreenStitchView.frame = CGRectMake(0, SCREEN_HEIGHT - weakSelf.checkScreenStitchView.height, SCREEN_WIDTH , weakSelf.checkScreenStitchView.height);
        }];
    });
}


#pragma mark -- btnClick &  viewDelegate
-(void)leftBtnClick:(UIButton *)btn{
    //滚动截图指引
    MJWeakSelf
    if (_bgView == nil){
        _bgView = [Tools addBGViewWithFrame:self.view.frame];
        [self.view addSubview:_bgView];
    }else{
        _bgView.hidden = NO;
    }
    if (_guiderView == nil){
        _guiderView = [GuiderVisitorView new];
        _guiderView.frame = CGRectMake(0, SCREEN_HEIGHT, SCREEN_WIDTH, 565);
 
        [self.view addSubview:_guiderView];
    }
    
    _guiderView.btnClick = ^{
        [UIView animateWithDuration:0.3 animations:^{
            weakSelf.guiderView.frame = CGRectMake(0, SCREEN_HEIGHT + 100, SCREEN_WIDTH , weakSelf.guiderView.height);
        } completion:^(BOOL finished) {
            weakSelf.bgView.hidden = YES;
            weakSelf.guiderView.pageC.currentPage = 0;
        }];
    };
    [UIView animateWithDuration:0.3 animations:^{
        weakSelf.guiderView.frame = CGRectMake(0, SCREEN_HEIGHT - weakSelf.guiderView.height, SCREEN_WIDTH , weakSelf.guiderView.height);
    }];
}

-(void)stitchBtnClickWithTag:(NSInteger)tag{
    MJWeakSelf
    if (tag == 4){
        [SVProgressHUD dismiss];
        [weakSelf checkScreenStitchViewDiss];
    }else if (tag == 5){
        //导出
        if (User.checkIsVipMember){
            [SVProgressHUD showWithStatus:@"正在生成图片中.."];
            [TYSnapshotScroll screenSnapshot:_resultView.scrollView finishBlock:^(UIImage *snapshotImage) {
                [SVProgressHUD dismiss];
                SaveViewController *saveVC = [SaveViewController new];
                saveVC.screenshotIMG = snapshotImage;
                saveVC.isVer = YES;
                saveVC.type = 2;
                [weakSelf checkScreenStitchViewDiss];
                [weakSelf.navigationController pushViewController:saveVC animated:YES];
            }];
        }else{
            [self addFuncViewWithType:6];
        }
        
       
    }else {
        if (User.checkIsVipMember){
            //字幕//拼接//裁切
            CaptionViewController *vc = [CaptionViewController new];
            __block NSMutableArray *tmpArr = [NSMutableArray array];
            if (!_isScrollScreen){
                for (PHAsset *asset in _stitchArr) {
                    [Tools getImageWithAsset:asset withBlock:^(UIImage * _Nonnull image) {
                        [tmpArr addObject:image];
                    }];
                }
                vc.dataArr = tmpArr;
                if (tag == 1){
                    vc.type = 2;
                }else if (tag == 2){
                    vc.type = 1;
                }else{
                    vc.type = 3;
                }
            }else{
                vc.dataArr = _stitchArr;
                vc.editImgArr = _stitchArr;
                vc.gengrator = _generator;
                vc.type = 4;
            }
            [weakSelf checkScreenStitchViewDiss];
            [self.navigationController pushViewController:vc animated:YES];
        }else{
            [self addFuncViewWithType:6];
        }
        
        
    }
    
}
-(void)checkScreenStitchViewDiss{
    MJWeakSelf
    [UIView animateWithDuration:0.3 animations:^{
        weakSelf.checkScreenStitchView.frame = CGRectMake(0, SCREEN_HEIGHT, SCREEN_WIDTH , weakSelf.checkScreenStitchView.height);
    } completion:^(BOOL finished) {
        weakSelf.bgView.hidden = YES;
        [weakSelf.checkScreenStitchView removeFromSuperview];
    }];
}

-(void)showResult:(SZImageGenerator *)result{
    [SVProgressHUD dismiss];
    if (!result) {
        return;
    }
    _generator = result;
    _resultView = [StitchResultView new];
    _resultView.generator = _generator;
    SZStichingImageView *imageView = _resultView.imageViews.lastObject;
    [_resultView.scrollView setContentSize:CGSizeMake(0, imageView.bottom)];
    [_checkScreenStitchView addSubview:_resultView];
    [_resultView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(@23);
        make.width.equalTo(@(SCREEN_WIDTH  - 46));
        make.top.equalTo(@50);
        make.height.equalTo(@(_checkScreenStitchView.height - 128));
    }];
}
-(void)btnClickWithTag:(NSInteger)tag{
    MJWeakSelf
    if (tag == 1) {
        [_funcView removeFromSuperview];
//        [self.navigationController pushViewController:[BuyViewController new] animated:YES];
        [[NSNotificationCenter defaultCenter]postNotificationName:@"dismiss" object:nil];
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [weakSelf.navigationController pushViewController:[BuyViewController new ] animated:YES];
        });
    }else{
        MJWeakSelf
        if (_bgView == nil){
            _bgView = [Tools addBGViewWithFrame:self.view.frame];
            [self.view addSubview:_bgView];
        }else{
            _bgView.hidden = NO;
            [self.view bringSubviewToFront:_bgView];
        }
        if (_checkProView == nil){
            _checkProView = [[CheckProView alloc]initWithFrame:CGRectMake(0, SCREEN_HEIGHT, SCREEN_WIDTH, 550)];
            _checkProView.delegate = self;
            [self.view.window addSubview:_checkProView];
        }
        _checkProView.hidden = NO;
        [self.view.window bringSubviewToFront:_checkProView];
        [UIView animateWithDuration:0.3 animations:^{
            weakSelf.checkProView.frame = CGRectMake(0, SCREEN_HEIGHT - weakSelf.checkProView.height, SCREEN_WIDTH , weakSelf.checkProView.height);
        }];
    }
}

-(BOOL)checkAPPIsExist:(NSString*)URLScheme{
    NSURL* url;
    if ([URLScheme containsString:@"://"]) {
        url = [NSURL URLWithString:[NSString stringWithFormat:@"%@",URLScheme]];
    } else {
        url = [NSURL URLWithString:[NSString stringWithFormat:@"%@://",URLScheme]];
    }
    if ([[UIApplication sharedApplication] canOpenURL:url]){
        return YES;
    } else {
        return NO;
    }
}

-(void)cancelClickWithTag:(NSInteger)tag{
    MJWeakSelf
    if (tag == 1){
        [UIView animateWithDuration:0.3 animations:^{
            weakSelf.checkProView.frame = CGRectMake(0, SCREEN_HEIGHT + 100, SCREEN_WIDTH , weakSelf.checkProView.height);
          //  weakSelf.bgView.hidden = YES;
        }];
    }else{
        [UIView animateWithDuration:0.3 animations:^{
            weakSelf.checkProView.frame = CGRectMake(0, SCREEN_HEIGHT, SCREEN_WIDTH, 550);
        } completion:^(BOOL finished) {
           // weakSelf.bgView.hidden = YES;
            [weakSelf.checkProView removeFromSuperview];
            weakSelf.checkProView = nil;
            [weakSelf.view bringSubviewToFront:weakSelf.checkScreenStitchView];
            
        }];
        [_funcView removeFromSuperview];
        [[NSNotificationCenter defaultCenter]postNotificationName:@"dismiss" object:nil];
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [weakSelf.navigationController pushViewController:[BuyViewController new] animated:YES];
        });
    }
}
#pragma mark 定时器检测图片选择器状态
-(void)timerMethod{
    if (_isOpenAlbum){
        if (self.manager.selectedCount == 0){
            _showBottomViewStatus = 0;
            if (_showBottomViewStatus == 0){
                _clearBtn.hidden = YES;
                _showBottomViewStatus = 1;
                [self setupBottomViewWithType:1];
            }
        }else {
            if (_clearBtn == nil){
                _clearBtn = [UIButton buttonWithType:UIButtonTypeSystem];
                [_clearBtn setBackgroundImage:IMG(@"清空") forState:UIControlStateNormal];
                [_clearBtn addTarget:self action:@selector(clearSelectIMG) forControlEvents:UIControlEventTouchUpInside];
                [self.view.window addSubview:_clearBtn];
                [_clearBtn mas_makeConstraints:^(MASConstraintMaker *make) {
                    make.width.equalTo(@70);
                    make.height.equalTo(@30);
                    make.bottom.equalTo(@-100);
                    make.left.equalTo(@(SCREEN_WIDTH - 86));
                }];
                
            }
            _clearBtn.hidden = NO;
            [self.view.window bringSubviewToFront:_clearBtn];
            if (self.manager.selectedCount == 1){
               _showBottomViewStatus = 1;
               if (_showBottomViewStatus == 1){
                   _showBottomViewStatus = 2;
                   [self setupBottomViewWithType:2];
               }
           }else{
               _showBottomViewStatus = 2;
               if (_showBottomViewStatus == 2){
                   _showBottomViewStatus = 0;
                   [self setupBottomViewWithType:3];
               }
           }
        }
        
    }
}
//销毁定时器
-(void)destoryTimer{
    if (_reTimer) {
        [_reTimer setFireDate:[NSDate distantFuture]];
        [_reTimer invalidate];
        _reTimer = nil;
    }
}

//打开相册
-(void)openAlbum:(NSNotification *)noti{
    _isOpenAlbum = YES;
}
//关闭相册
-(void)closeAlbum:(NSNotification *)noti{
    _isOpenAlbum = NO;
    _showBottomViewStatus = 0;
    _clearBtn.hidden = YES;
}




#pragma mark -- 清空选择图片
- (void)clearSelectIMG {
    if (self.manager.selectedCount > 0 ){
        [[NSNotificationCenter defaultCenter]postNotificationName:@"clearData" object:nil];
        _showBottomViewStatus = 0;
        _clearBtn.hidden = YES;
        [self setupBottomViewWithType:1];
       
    }else{
        [SVProgressHUD showInfoWithStatus:@"您未选择任何图片"];
    }
}

#pragma clang diagnostic push
#pragma clang diagnostic ignored"-Wdeprecated-declarations"
- (void)changeStatus {
#ifdef __IPHONE_13_0
    if (@available(iOS 13.0, *)) {
        if (UITraitCollection.currentTraitCollection.userInterfaceStyle == UIUserInterfaceStyleDark) {
            [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent animated:YES];
            return;
        }
    }
#endif
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleDefault animated:YES];
}
#pragma clang diagnostic pop

#pragma mark -photoViewDelegate


-(HXPhotoView *)photoView{
    if (!_photoView){
        _photoView = [HXPhotoView photoManager:self.manager scrollDirection:UICollectionViewScrollDirectionVertical];
        _photoView.frame = CGRectMake(0, 12, SCREEN_WIDTH, 0);
        _photoView.collectionView.contentInset = UIEdgeInsetsMake(0, 12, 0, 12);
        _photoView.delegate = self;
        _photoView.outerCamera = NO;
        _photoView.previewStyle = HXPhotoViewPreViewShowStyleDark;
        _photoView.previewShowDeleteButton = YES;
        _photoView.showAddCell = YES;
        [_photoView.collectionView reloadData];
        [_MJColloctionView addSubview:_photoView];
    }
    return _photoView;
}

- (HXPhotoManager *)manager {
    MJWeakSelf
    if (!_manager) {
        _manager = [[HXPhotoManager alloc] initWithType:HXPhotoManagerSelectedTypePhoto];
        _manager.configuration.type = HXConfigurationTypeWXChat;
        //设定高级用户和普通选择图片数量
        _manager.configuration.maxNum = 10000;
        _manager.configuration.photoListBottomView = ^(HXPhotoBottomView *bottomView) {
            bottomView.backgroundColor = [UIColor whiteColor];
            weakSelf.bottomView = bottomView;
            [weakSelf.bottomView removeAllSubviews];
            [weakSelf setupBottomViewWithType:1];
        };
        _manager.configuration.previewBottomView = ^(HXPhotoPreviewBottomView *bottomView) {
            
        };

    }
    return _manager;
}
-(void)photoNavigationViewController:(HXCustomNavigationController *)photoNavigationViewController didDoneWithResult:(HXPickerResult *)result{
    [self.manager.selectedArray arrayByAddingObjectsFromArray:result.models];
}



#pragma mark -- 图片编辑btn事件
-(void)imgEdit:(UIButton *)btn{
    MJWeakSelf
    [_clearBtn removeFromSuperview];
    if (btn.tag < 300){
        if (btn.tag == 200){
            //选择一图裁切
            CaptionViewController *vc = [CaptionViewController new];
            vc.type = 5;
            __block NSMutableArray *arr = [NSMutableArray array];
            for (HXPhotoModel *photoModel in [self.manager selectedArray]) {
                [Tools getImageWithAsset:photoModel.asset withBlock:^(UIImage * _Nonnull image) {
                    [arr addObject:image];
                }];
            }
            
            vc.dataArr = arr;
            [[NSNotificationCenter defaultCenter]postNotificationName:@"dismiss" object:nil];
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [weakSelf.navigationController pushViewController:vc animated:YES];
            });
        }else{
            //选择一图编辑
            ImageEditViewController *vc = [ImageEditViewController new];
            vc.isVer = YES;
            vc.type = 1;
            vc.titleStr = @"1张图片";
            __block NSMutableArray *arr = [NSMutableArray array];
            for (HXPhotoModel *photoModel in [self.manager selectedArray]) {
                [Tools getImageWithAsset:photoModel.asset withBlock:^(UIImage * _Nonnull image) {
                    [arr addObject:image];
                }];
            }
            vc.imgArr = arr;
            [[NSNotificationCenter defaultCenter]postNotificationName:@"dismiss" object:nil];
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [weakSelf.navigationController pushViewController:vc animated:YES];
            });
        }
    }else{
        _isOpenAlbum = NO;
        [_clearBtn removeFromSuperview];
        _clearBtn = nil;
        if (btn.tag == 302){
            //多图布局
            if (self.manager.selectedArray.count > 9){
                [SVProgressHUD showInfoWithStatus:@"布局最多只支持9张图片!"];
                return;
            }
            PictureLayoutController *layoutVC = [[PictureLayoutController alloc] init];
            
            __block NSMutableArray *arr = [NSMutableArray array];
            for (HXPhotoModel *photoModel in [self.manager selectedArray]) {
                [Tools getImageWithAsset:photoModel.asset withBlock:^(UIImage * _Nonnull image) {
                    [arr addObject:image];
                }];
            }
            
            layoutVC.pictures = arr;
            
            [[NSNotificationCenter defaultCenter]postNotificationName:@"dismiss" object:nil];
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [weakSelf.navigationController pushViewController:layoutVC animated:YES];
            });
        }else{
            if (!User.checkIsVipMember && self.manager.selectedCount > 9){
                //非会员弹出提示
                [self addFuncViewWithType:3];
            }else{
                if (btn.tag == 300){
                    //多图截长屏
                    __block NSMutableArray *arr = [NSMutableArray array];
                    __block NSMutableArray *imgArr = [NSMutableArray array];
                    for (HXPhotoModel *photoModel in [self.manager selectedArray]) {
                        [arr addObject:photoModel.asset];
                        [Tools getImageWithAsset:photoModel.asset withBlock:^(UIImage * _Nonnull image) {
                            [imgArr addObject:image];
                        }];
                    }
                    //判断图片分辨率是否一样
                    BOOL isSimilarityImage = NO;
                    UIImage *firstIMG = imgArr[0];
                    CGFloat scale = firstIMG.size.width / firstIMG.size.height;
                    for (NSInteger i = 1 ; i < imgArr.count; i ++) {
                        UIImage *secondIMG = imgArr[i];
                        CGFloat secondScale = secondIMG.size.width / secondIMG.size.height;
                        if (scale == secondScale){
                            isSimilarityImage = YES;
                        }else{
                            isSimilarityImage = NO;
                            break;
                        }
                    }
                    //相同分辨率 才可进入长截图拼图
                    if (isSimilarityImage){
                        CaptionViewController *vc = [CaptionViewController new];
                        vc.type = 4;
                        vc.dataArr = arr;
                        vc.editImgArr = imgArr;
                        [[NSNotificationCenter defaultCenter]postNotificationName:@"dismiss" object:nil];
                        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                            [weakSelf.navigationController pushViewController:vc animated:YES];
                        });
                    }else{
                        [SVProgressHUD showInfoWithStatus:@"相同分辨率图片才能进行长截图拼接！"];
                    }
                }else if(btn.tag == 301){
                    //多图拼接
                    CaptionViewController *vc = [CaptionViewController new];
                    vc.type = 2;
                    __block NSMutableArray *arr = [NSMutableArray array];
                    for (HXPhotoModel *photoModel in [self.manager selectedArray]) {
                        [Tools getImageWithAsset:photoModel.asset withBlock:^(UIImage * _Nonnull image) {
                            [arr addObject:image];
                        }];
                    }
                    
                    vc.dataArr = arr;
                    [[NSNotificationCenter defaultCenter]postNotificationName:@"dismiss" object:nil];
                    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                        [weakSelf.navigationController pushViewController:vc animated:YES];
                    });
                    
                }else{
                    //多图字幕
                    if ([self.manager selectedArray].count > 1){
                        
                        CaptionViewController *vc = [CaptionViewController new];
                        vc.type = 1;
                        __block NSMutableArray *arr = [NSMutableArray array];
                        for (HXPhotoModel *photoModel in [self.manager selectedArray]) {
                            [Tools getImageWithAsset:photoModel.asset withBlock:^(UIImage * _Nonnull image) {
                                [arr addObject:image];
                            }];
                        }
                        
                        vc.dataArr = arr;
                        [[NSNotificationCenter defaultCenter]postNotificationName:@"dismiss" object:nil];
                        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                            [weakSelf.navigationController pushViewController:vc animated:YES];
                        });
                    }else{
                        [SVProgressHUD showInfoWithStatus:@"电影截图拼接至少2张图片"];
                    }
                    
                }
            }
        }
        
        
    }
}

-(void)addFuncViewWithType:(NSInteger)type{
    _funcView = [UnlockFuncView new];
    _funcView.delegate = self;
    _funcView.type = type;
    [self.view.window addSubview:_funcView];
    [_funcView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.view);
    }];
}


#pragma mark -- set
-(NSMutableArray *)stitchArr{
    if (_stitchArr == nil){
        self.stitchArr = [NSMutableArray array];
    }
    return _stitchArr;
}
-(NSMutableArray *)schemeArr{
    if (_schemeArr == nil){
        self.schemeArr = [NSMutableArray array];
    }
    return _schemeArr;
}
-(NSMutableArray *)nameArr{
    if (_nameArr == nil){
        self.nameArr = [NSMutableArray array];
    }
    return _nameArr;
}

@end
