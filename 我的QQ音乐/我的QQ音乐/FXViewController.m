//
//  FXViewController.m
//  我的QQ音乐
//
//  Created by fanxi on 16/3/10.
//  Copyright © 2016年 fanxi. All rights reserved.
//


#import "FXViewController.h"
#import "Masonry.h"
#import "FXMusicTool.h"
#import "FXMusic.h"
#import "FXAudioTool.h"
#import "NSString+FXTimeExtension.h"
#import "CALayer+PauseAimate.h"
#import "FXLrcView.h"
#import "FXLrcLabel.h"
#import <MediaPlayer/MediaPlayer.h>

#define FXColor(r,g,b) ([UIColor colorWithRed:r/255.0 green:g/255.0 blue:b/255.0 alpha:1.0])


@interface FXViewController ()
@property (weak, nonatomic) IBOutlet UIImageView *albumView;

@property (weak, nonatomic) IBOutlet UIImageView *iconView;
@property (weak, nonatomic) IBOutlet UILabel *songLabel;
@property (weak, nonatomic) IBOutlet UILabel *singerLabel;
@property (weak, nonatomic) IBOutlet UILabel *currentTimeLabel;
@property (weak, nonatomic) IBOutlet UILabel *totalTimeLabel;
@property (weak, nonatomic) IBOutlet UIButton *playOrPauseBtn;

@property (weak, nonatomic) IBOutlet UISlider *progressSlider;


@property (weak, nonatomic) IBOutlet FXLrcLabel *lrcLabel;
@property (weak, nonatomic) IBOutlet FXLrcView *lrcView;




/** 进度的Timer */
@property (nonatomic, strong) NSTimer *progressTimer;

/** 歌词更新的定时器 */
@property (nonatomic, strong) CADisplayLink *lrcTimer;

/** 当前的播放器 */
@property (nonatomic, strong) AVAudioPlayer *currentPlayer;

- (IBAction)playOrPause;
- (IBAction)previous;
- (IBAction)next;


- (IBAction)startSlide;
- (IBAction)sliderValueChange;
- (IBAction)endSlide;

@end

@implementation FXViewController 

- (void)viewDidLoad {
    [super viewDidLoad];
    // 1.添加毛玻璃效果
    [self setupBlurView];
    
    // 2.设置滑块的图片
    [self.progressSlider setThumbImage:[UIImage imageNamed:@"player_slider_playback_thumb"] forState:UIControlStateNormal];
    
    // 3.展示界面的信息
    [self startPlayingMusic];
    
    // 4.设置lrcView的ContentSize
    self.lrcView.contentSize = CGSizeMake(self.view.bounds.size.width * 2, 0);
    self.lrcView.lrcLabel = self.lrcLabel;
    self.view.backgroundColor = [UIColor redColor];
}

- (void)viewWillLayoutSubviews
{
    [super viewWillLayoutSubviews];
    
    // 设置iconView圆角
    self.iconView.layer.cornerRadius = self.iconView.bounds.size.width * 0.5;
    self.iconView.layer.masksToBounds = YES;
    self.iconView.layer.borderWidth = 8.0;
    self.iconView.layer.borderColor = FXColor(36, 36, 36).CGColor;
}

- (void)setupBlurView
{
    UIToolbar *toolBar = [[UIToolbar alloc] init];
    [toolBar setBarStyle:UIBarStyleBlack];
    [self.albumView addSubview:toolBar];
    toolBar.translatesAutoresizingMaskIntoConstraints = NO;
    [toolBar mas_makeConstraints:^(MASConstraintMaker *make) {
        /*
         make.top.equalTo(self.albumView.mas_top);
         make.bottom.equalTo(self.albumView.mas_bottom);
         make.left.equalTo(self.albumView.mas_left);
         make.right.equalTo(self.albumView.mas_right);
         */
        make.edges.equalTo(self.albumView);
    }];
}

- (UIStatusBarStyle)preferredStatusBarStyle
{
    return UIStatusBarStyleLightContent;
}

#pragma mark - 开始播放音乐
- (void)startPlayingMusic
{
    // 1.取出当前播放歌曲
    FXMusic *playingMusic = [FXMusicTool playingMusic];
    
    // 2.设置界面信息
    self.albumView.image = [UIImage imageNamed:playingMusic.icon];
    self.iconView.image = [UIImage imageNamed:playingMusic.icon];
    self.songLabel.text = playingMusic.name;
    self.singerLabel.text = playingMusic.singer;
    
    // 3.开始播放歌曲
    AVAudioPlayer *currentPlayer = [FXAudioTool playMusicWithMusicName:playingMusic.filename];
    currentPlayer.delegate = self;
    self.totalTimeLabel.text = [NSString stringWithTime:currentPlayer.duration];
    self.currentTimeLabel.text = [NSString stringWithTime:currentPlayer.currentTime];
    self.currentPlayer = currentPlayer;
    self.playOrPauseBtn.selected = self.currentPlayer.isPlaying;
    
    // 4.设置歌词
    self.lrcView.lrcName = playingMusic.lrcname;
    
    //刚开始 外界歌词label清空
    self.lrcLabel.text = @"";
    
    
    self.lrcView.duration = currentPlayer.duration;
    
    // 5.开始播放动画
    [self startIconViewAnimate];
    
    // 6.添加定时器用户更新进度界面
    [self removeProgressTimer];
    [self addProgressTimer];
    [self removeLrcTimer];
    [self addLrcTimer];
}

- (void)startIconViewAnimate
{
    // 1.创建基本动画
    CABasicAnimation *rotateAnim = [CABasicAnimation animationWithKeyPath:@"transform.rotation.z"];
    
    // 2.设置基本动画属性
    rotateAnim.fromValue = @(0);
    rotateAnim.toValue = @(M_PI * 2);
    rotateAnim.repeatCount = NSIntegerMax;
    rotateAnim.duration = 40;
    
    // 3.添加动画到图层上
    [self.iconView.layer addAnimation:rotateAnim forKey:nil];
}

#pragma mark - 对定时器的操作
- (void)addProgressTimer
{
    [self updateProgressInfo];
    self.progressTimer = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(updateProgressInfo) userInfo:nil repeats:YES];
    [[NSRunLoop mainRunLoop] addTimer:self.progressTimer forMode:NSRunLoopCommonModes];
}

- (void)removeProgressTimer
{
    [self.progressTimer invalidate];
    self.progressTimer = nil;
}

- (void)addLrcTimer
{
    self.lrcTimer = [CADisplayLink displayLinkWithTarget:self selector:@selector(updateLrc)];
    [self.lrcTimer addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSRunLoopCommonModes];
}

- (void)removeLrcTimer
{
    [self.lrcTimer invalidate];
    self.lrcTimer = nil;
}
#pragma mark - 更新进度的界面
- (void)updateProgressInfo
{
    // 1.设置当前的播放时间
    self.currentTimeLabel.text = [NSString stringWithTime:self.currentPlayer.currentTime];
    
    // 2.更新滑块的位置
    self.progressSlider.value = self.currentPlayer.currentTime / self.currentPlayer.duration;
}

#pragma mark - 更新歌词
- (void)updateLrc
{
    self.lrcView.currentTime = self.currentPlayer.currentTime;
}






- (IBAction)playOrPause {
    
    self.playOrPauseBtn.selected = !self.playOrPauseBtn.selected;
    
    if (self.currentPlayer.playing) {
        [self.currentPlayer pause];
        
        [self removeProgressTimer];
        [self removeLrcTimer];
        
        // 暂停iconView的动画
        [self.iconView.layer pauseAnimate];
    } else {
        [self.currentPlayer play];
        
        [self addProgressTimer];
        [self removeLrcTimer];
        
        // 恢复iconView的动画
        [self.iconView.layer resumeAnimate];
    }
}

- (IBAction)previous {
    
    // 1.取出上一首歌曲
    FXMusic *previousMusic = [FXMusicTool previousMusic];
    
    // 2.播放上一首歌曲
    [self playingMusicWithMusic:previousMusic];
}

- (IBAction)next {
    
    // 1.取出下一首歌曲
    FXMusic *nextMusic = [FXMusicTool nextMusic];
    
    // 2.播放下一首歌曲
    [self playingMusicWithMusic:nextMusic];
}

- (IBAction)startSlide {
    
     [self removeProgressTimer];
}

- (IBAction)sliderValueChange {
    
    // 设置当前播放的时间Label
    self.currentTimeLabel.text = [NSString stringWithTime:self.currentPlayer.duration * self.progressSlider.value];
}

- (IBAction)endSlideendSlide {
    
    // 1.设置歌曲的播放时间
    self.currentPlayer.currentTime = self.progressSlider.value * self.currentPlayer.duration;
    
    // 2.添加定时器
    [self addProgressTimer];
}

- (void)playingMusicWithMusic:(FXMusic *)music
{
    // 1.停止当前歌曲
    FXMusic *playingMusic = [FXMusicTool playingMusic];
    [FXAudioTool stopMusicWithMusicName:playingMusic.filename];
    
    // 3.播放歌曲
    [FXAudioTool playMusicWithMusicName:music.filename];
    
    // 4.将工具类中的当前歌曲切换成播放的歌曲
    [FXMusicTool setPlayingMusic:music];
    
    // 5.改变界面信息
    [self startPlayingMusic];
}

#pragma mark - 实现UIScrollView的代理方法
- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    // 1.获取到滑动多少
    CGPoint point = scrollView.contentOffset;
    
    // 2.计算滑动的比例
    CGFloat ratio = 1 - point.x / scrollView.bounds.size.width;
    
    // 3.设置iconView和歌词的Label的透明度
    self.iconView.alpha = ratio;
    self.lrcLabel.alpha = ratio;
}

#pragma mark - AVAudioplayer的代理方法
- (void)audioPlayerDidFinishPlaying:(AVAudioPlayer *)player successfully:(BOOL)flag
{
    if (flag) {
        [self next];
    }
}
// 监听远程事件
- (void)remoteControlReceivedWithEvent:(UIEvent *)event
{
    switch (event.subtype) {
        case UIEventSubtypeRemoteControlPlay:
        case UIEventSubtypeRemoteControlPause:
            [self playOrPause];
            break;
            
        case UIEventSubtypeRemoteControlNextTrack:
            [self next];
            break;
            
        case UIEventSubtypeRemoteControlPreviousTrack:
            [self previous];
            break;
            
        default:
            break;
    }
}

@end
