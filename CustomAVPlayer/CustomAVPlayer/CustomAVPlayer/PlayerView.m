//
//  PlayerView.m
//  CustomAVPlayer
//  工程必须开启Device Orientation 横屏功能才能正常全屏
//  Created by zjl on 2018/6/26.
//  Copyright © 2018年 zjl. All rights reserved.
//

#import "PlayerView.h"
#import<AVFoundation/AVFoundation.h>
#import "PlayerToolsView.h"
typedef NS_ENUM(NSInteger,FullScreenState){
	smallScreen,//小屏状态
	fullScreen,//全屏状态
	animating //正在变化状态中
};

//http://streams.videolan.org/streams/mp4/Mr_MrsSmith-h264_aac.mp4
#define ToolsViewHeightRadio 0.2  //播放工具条的高度和整个播放器高度的比
@interface PlayerView()<UIGestureRecognizerDelegate> {
	CGRect smallPlayerViewFrame;
}
@property (nonatomic,strong) AVPlayer *player;
@property (nonatomic,strong) AVPlayerLayer *playerLayer;
@property (nonatomic,strong) AVPlayerItem *playerItem;
@property (nonatomic,strong) UITapGestureRecognizer *tapGes;//点击显示播放工具条的手势
@property (nonatomic,strong) PlayerToolsView *toolsView;//工具条view
@property (nonatomic,assign) CGFloat totalSeconds;//当前加载的视频的总时间
@property (nonatomic,assign) BOOL isEnd;//当前视频是否播放结束
@property (nonatomic,strong) UIButton *hideToolsViewButton;//点击隐藏工具条按钮
@property (nonatomic,assign) FullScreenState screenState;//当前屏幕状态
@end
@implementation PlayerView

#pragma mark - Init Method
- (instancetype)initWithFrame:(CGRect)frame{
	self = [super initWithFrame:frame];
	if (self) {
		smallPlayerViewFrame = frame;
		_hideToolsViewButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth(self.frame),  CGRectGetHeight(self.frame) - 50)];
		[self addSubview:_hideToolsViewButton];
		_hideToolsViewButton.backgroundColor = [UIColor clearColor];
		[_hideToolsViewButton addTarget:self action:@selector(clickHideToolsViewBtn) forControlEvents:UIControlEventTouchUpInside];
		
//		[[UIApplication sharedApplication] setStatusBarHidden:NO];
		
		[self createTapGesture];
		
		[self createToolsView];
		
		[self noti];

	}
	return self;
}

//创建播放的工具条
- (void)createToolsView {
	self.toolsView = [PlayerToolsView instanceView];
	self.toolsView.frame = CGRectMake(0,CGRectGetHeight(self.frame) - 50, CGRectGetWidth(self.frame), 50);
	[self addSubview:self.toolsView];
	
	
	self.toolsView.PlayButton.frame = CGRectMake(0, 0, 50, 50);
	self.toolsView.currentTimeLabel.frame = CGRectMake(5 + CGRectGetMaxX(self.toolsView.PlayButton.frame), 0, 55, 50);
	self.toolsView.fullScreenButton.frame = CGRectMake(CGRectGetWidth(self.frame) - 50, 0, 50, 50);
	self.toolsView.totalTimeLabel.frame = CGRectMake(CGRectGetMinX(self.toolsView.fullScreenButton.frame) - 60, 0, 55, 50);
	self.toolsView.slider.frame = CGRectMake(5 + CGRectGetMaxX(self.toolsView.currentTimeLabel.frame), 0, CGRectGetMinX(self.toolsView.totalTimeLabel.frame) - CGRectGetMaxX(self.toolsView.currentTimeLabel.frame) - 10, 50);
	
	[self.toolsView.PlayButton addTarget:self action:@selector(clickPlayBtn) forControlEvents:UIControlEventTouchUpInside];
	[self.toolsView.slider setThumbImage:[UIImage imageNamed:@"point"] forState:UIControlStateNormal];
	
	[self.toolsView.slider addTarget:self action:@selector(touchDownSlider) forControlEvents:UIControlEventTouchDown];
	[self.toolsView.slider addTarget:self action:@selector(sliderValueChanged) forControlEvents:UIControlEventValueChanged];
	[self.toolsView.slider addTarget:self action:@selector(touchupSlider) forControlEvents:UIControlEventTouchUpInside];
	
	[self.toolsView.fullScreenButton addTarget:self action:@selector(clickFullScreenButton) forControlEvents:UIControlEventTouchUpInside];
	[self resetToolsView];
	
}

- (void)resetToolsView {
	[self.toolsView.PlayButton setImage:[UIImage imageNamed:@"play"] forState:UIControlStateNormal];
	self.toolsView.currentTimeLabel.text = @"00:00";
	self.toolsView.totalTimeLabel.text = @"00:00";
	self.toolsView.slider.value = 0;
}
#pragma mark - setter
- (void)setSourcePath:(NSString *)sourcePath {
	_sourcePath = sourcePath;
	if (_player) {
		[_player pause];
		[self removeKvoObserver];
		[self removeNoti];
		_player = nil;
		_playerLayer = nil;
		_playerItem = nil;

	}
	// 1、获取媒体资源地址
	NSURL *sourceMovieURL;
	if ([_sourcePath hasPrefix:@"http"]) {
		sourceMovieURL = [NSURL URLWithString:_sourcePath];
	}else {
		sourceMovieURL = [NSURL fileURLWithPath:_sourcePath];
	}

	// 2、创建AVPlayerItem
	_playerItem = [AVPlayerItem playerItemWithURL:sourceMovieURL];
	// 3、根据AVPlayerItem创建媒体播放器
	_player = [AVPlayer playerWithPlayerItem:_playerItem];
	// 4、创建AVPlayerLayer，用于呈现视频
	_playerLayer = [AVPlayerLayer playerLayerWithPlayer:_player];
	// 5、设置显示大小和位置
	//	playerLayer.bounds = CGRectMake(0, 0, 350, 300);
	//	playerLayer.position = CGPointMake(CGRectGetMidX(self.view.bounds), 64 + CGRectGetMidY(playerLayer.bounds) + 30);
	_playerLayer.frame = CGRectMake(0, 0, CGRectGetWidth(self.frame), CGRectGetHeight(self.frame));
	// 6、设置拉伸模式
	_playerLayer.videoGravity = AVLayerVideoGravityResize;
	// 7、获取播放持续时间
	//	NSLog(@"%lld", _playerItem.duration.value);
//	[self.layer addSublayer:_playerLayer];
	[self.layer insertSublayer:_playerLayer below:self.toolsView.layer];
	
	[self addKVOObserver];
	
	[self addNoti];
	
	[self resetToolsView];
	
	__weak typeof(self) weakSelf = self;
	// 播放1s回调一次
	[_player addPeriodicTimeObserverForInterval:CMTimeMake(1, 1) queue:NULL usingBlock:^(CMTime time) {
		weakSelf.toolsView.currentTimeLabel.text = [weakSelf secondsToString:[weakSelf getTimeToSeconds:time]];
		weakSelf.toolsView.slider.value = [weakSelf getTimeToSeconds:time] / self.totalSeconds;
//		[weakSelf pv_setTimeLabel];
//		NSLog(@"current=%lld",time.value);
//		NSTimeInterval totalTime = CMTimeGetSeconds(weakSelf.player.currentItem.duration);
//		weakSelf.toolView.slider.value = time.value/time.timescale/totalTime;//time.value/time.timescale是当前时间
	}];
}

#pragma mark - Gesture
//设置点击显示/隐藏播放条的手势
- (void)createTapGesture {
	_tapGes = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapPlayer:)];
	self.userInteractionEnabled = YES;
	_tapGes.delegate = self;
	[self addGestureRecognizer:_tapGes];
}

- (void)tapPlayer:(UITapGestureRecognizer *)ges{


//	if (self.screenState == smallScreen) {
		[[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:UIStatusBarAnimationFade];
//	}
	[UIView animateWithDuration:0.2 delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
		self.toolsView.alpha = 1;
	} completion:^(BOOL finished) {
		self.toolsView.hidden = NO;
		self.hideToolsViewButton.hidden = NO;
	}];
}
#pragma mark - UIGestureRecognizerDelegate
-(BOOL)gestureRecognizer:(UIGestureRecognizer*)gestureRecognizer shouldReceiveTouch:(UITouch*)touch {
	if([touch.view isKindOfClass:[UISlider class]]){
		return NO;
	}else{
		return YES;
	}
}

#pragma mark - Button Action
- (void)clickHideToolsViewBtn {

	[[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:UIStatusBarAnimationFade];
	[UIView animateWithDuration:0.2 delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
		self.toolsView.alpha = 0;
	} completion:^(BOOL finished) {
		self.toolsView.hidden = YES;
		self.hideToolsViewButton.hidden = YES;
	}];
}

- (void)clickPlayBtn {
	if (_player && _player.currentItem.status == AVPlayerStatusReadyToPlay) {
		if (_player.rate == 0) {

			[self.toolsView.PlayButton setImage:[UIImage imageNamed:@"pause.png"] forState:UIControlStateNormal];
			if (self.isEnd) {
				[self.player seekToTime:CMTimeMakeWithSeconds(0, NSEC_PER_SEC) toleranceBefore:kCMTimeZero toleranceAfter:kCMTimeZero];
			}
				[_player play];
		}else {
			[_player pause];
			[self.toolsView.PlayButton setImage:[UIImage imageNamed:@"play.png"] forState:UIControlStateNormal];
		}
	}
}

- (void)clickFullScreenButton {
	if (self.screenState == smallScreen) {
		[self fullScreenAnimation];
	}else if (self.screenState == fullScreen){
		[self smallScreenAnimation];
	}
//	[[UIApplication sharedApplication] setStatusBarOrientation:UIInterfaceOrientationPortrait animated:YES];
}

- (void)fullScreenAnimation {
	self.screenState = animating;
	//		[[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:UIStatusBarAnimationFade];
	//		CGRect rectInWindow = [self convertRect:self.bounds toView:[UIApplication sharedApplication].keyWindow];
	//		[self removeFromSuperview];
	//		self.frame = rectInWindow;
	//		[[UIApplication sharedApplication].keyWindow addSubview:self];
	NSNumber *orientationUnknown = [NSNumber numberWithInt:UIInterfaceOrientationUnknown];
	[[UIDevice currentDevice] setValue:orientationUnknown forKey:@"orientation"];
	
	NSNumber *orientationTarget = [NSNumber numberWithInt:UIInterfaceOrientationLandscapeRight];
	[[UIDevice currentDevice] setValue:orientationTarget forKey:@"orientation"];
	self.frame = CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height);
	self.toolsView.frame = CGRectMake(0, [UIScreen mainScreen].bounds.size.height - 50, [UIScreen mainScreen].bounds.size.width, 50);
	_playerLayer.frame = CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height);
	self.hideToolsViewButton.frame = CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height - 50);
	self.toolsView.fullScreenButton.frame = CGRectMake(CGRectGetWidth(self.frame) - 50, 0, 50, 50);
	self.toolsView.totalTimeLabel.frame = CGRectMake(CGRectGetMinX(self.toolsView.fullScreenButton.frame) - 60, 0, 55, 50);
	self.toolsView.slider.frame = CGRectMake(5 + CGRectGetMaxX(self.toolsView.currentTimeLabel.frame), 0, CGRectGetMinX(self.toolsView.totalTimeLabel.frame) - CGRectGetMaxX(self.toolsView.currentTimeLabel.frame) - 10, 50);
	self.screenState = fullScreen;
	[self.toolsView.fullScreenButton setImage:[UIImage imageNamed:@"shrinkscreen.png"] forState:UIControlStateNormal];
	[[UIApplication sharedApplication] setStatusBarHidden:self.toolsView.hidden];
}

- (void)smallScreenAnimation {
	self.screenState = animating;
	NSNumber *orientationUnknown = [NSNumber numberWithInt:UIInterfaceOrientationUnknown];
	[[UIDevice currentDevice] setValue:orientationUnknown forKey:@"orientation"];
	
	NSNumber *orientationTarget = [NSNumber numberWithInt:UIInterfaceOrientationPortrait];
	[[UIDevice currentDevice] setValue:orientationTarget forKey:@"orientation"];
	self.frame = smallPlayerViewFrame;
	self.toolsView.frame = CGRectMake(0,CGRectGetHeight(self.frame) - 50, CGRectGetWidth(self.frame), 50);
	_playerLayer.frame = CGRectMake(0, 0, CGRectGetWidth(self.frame), CGRectGetHeight(self.frame));
	self.hideToolsViewButton.frame = CGRectMake(0, 0, CGRectGetWidth(self.frame),  CGRectGetHeight(self.frame) - 50);
	self.toolsView.fullScreenButton.frame = CGRectMake(CGRectGetWidth(self.frame) - 50, 0, 50, 50);
	self.toolsView.totalTimeLabel.frame = CGRectMake(CGRectGetMinX(self.toolsView.fullScreenButton.frame) - 60, 0, 55, 50);
	self.toolsView.slider.frame = CGRectMake(5 + CGRectGetMaxX(self.toolsView.currentTimeLabel.frame), 0, CGRectGetMinX(self.toolsView.totalTimeLabel.frame) - CGRectGetMaxX(self.toolsView.currentTimeLabel.frame) - 10, 50);
	self.screenState = smallScreen;
	[self.toolsView.fullScreenButton setImage:[UIImage imageNamed:@"fullscreen.png"] forState:UIControlStateNormal];

}
#pragma mark - auto rotation
- (void)noti{
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(statusBarOrientationChange:) name:UIApplicationDidChangeStatusBarOrientationNotification object:nil];
}

- (void)statusBarOrientationChange:(NSNotification *)notification{
	UIInterfaceOrientation orientation = [[UIApplication sharedApplication] statusBarOrientation];
	if (orientation ==UIInterfaceOrientationLandscapeRight)// home键靠右
	{
		[self fullScreenAnimation];
		NSLog(@"home键靠右");
	}
	if (orientation ==UIInterfaceOrientationLandscapeLeft)// home键靠左
	{
		NSLog(@"home键靠左");
	}
	if (orientation ==UIInterfaceOrientationPortrait){
		[self smallScreenAnimation];
		NSLog(@"竖直方向");
	}
}
#pragma mark - slider
- (void)touchDownSlider {
	NSLog(@"按下slider");
	[_player pause];
}

- (void)sliderValueChanged {
	
	self.toolsView.currentTimeLabel.text = [self secondsToString:self.totalSeconds * self.toolsView.slider.value];
}

- (void)touchupSlider {
	NSLog(@"松开slider");
	_isEnd = NO;
	[self.player seekToTime:CMTimeMake(self.totalSeconds * self.toolsView.slider.value * 1000000000, NSEC_PER_SEC) toleranceBefore:kCMTimeZero toleranceAfter:kCMTimeZero];
	[self.toolsView.PlayButton setImage:[UIImage imageNamed:@"pause.png"] forState:UIControlStateNormal];
	[self.player play];

}
#pragma mark - KVO
- (void)addKVOObserver {
	[_playerItem addObserver:self forKeyPath:@"status" options:NSKeyValueObservingOptionNew context:nil];// 监听status属性
	[_playerItem addObserver:self forKeyPath:@"loadedTimeRanges" options:NSKeyValueObservingOptionNew context:nil];// 监听loadedTimeRanges属性
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
	AVPlayerItem *playerItem = (AVPlayerItem *)object;
	if ([keyPath isEqualToString:@"status"]) {
		if ([playerItem status] == AVPlayerStatusReadyToPlay) {
			NSLog(@"AVPlayerStatusReadyToPlay");
			self.toolsView.PlayButton.enabled = YES;
//			[_player play];
			//			self.stateButton.enabled = YES;
			CMTime duration = self.playerItem.duration;// 获取视频总长度
			self.totalSeconds = [self getTimeToSeconds:duration];
			self.toolsView.totalTimeLabel.text = [self secondsToString:self.totalSeconds];
			//			_totalTime = [self convertTime:totalSecond];// 转换成播放时间
			//			[self customVideoSlider:duration];// 自定义UISlider外观
//			NSLog(@"movie total duration:%f",CMTimeGetSeconds(duration));
			//			[self monitoringPlayback:self.playerItem];// 监听播放状态
		} else if ([playerItem status] == AVPlayerStatusFailed) {
			NSLog(@"AVPlayerStatusFailed");
		}
	} else if ([keyPath isEqualToString:@"loadedTimeRanges"]) {
		//		NSTimeInterval timeInterval = [self availableDuration];// 计算缓冲进度
		//		NSLog(@"Time Interval:%f",timeInterval);
		CMTime duration = self.playerItem.duration;
		CGFloat totalDuration = CMTimeGetSeconds(duration);
		//		[self.videoProgress setProgress:timeInterval / totalDuration animated:YES];
	}
}

- (void)removeKvoObserver {
	[self.player.currentItem removeObserver:self forKeyPath:@"status"];
	[self.player.currentItem removeObserver:self forKeyPath:@"loadedTimeRanges"];
}
#pragma mark - Notification
- (void)addNoti {
	 [[NSNotificationCenter defaultCenter] addObserver:self           selector:@selector(playbackFinished:) name:AVPlayerItemDidPlayToEndTimeNotification   object:self.player.currentItem];
}

- (void)playbackFinished:(NSNotification *)noti {
	NSLog(@"播放结束");
	[self.toolsView.PlayButton setImage:[UIImage imageNamed:@"play"] forState:UIControlStateNormal];
	self.toolsView.slider.value = 0;
	self.isEnd = YES;
	self.toolsView.currentTimeLabel.text = @"00:00";
}

- (void)removeNoti {
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - private method
- (CGFloat)getTimeToSeconds:(CMTime)time {
	CGFloat second = time.value / time.timescale;// 转换成秒
	return second;
}

- (NSString *)secondsToString:(CGFloat)seconds {
	NSNumber *num = [NSNumber numberWithFloat:seconds];
	int sec = [num intValue] % 60;

	NSString *secStr = [NSString stringWithFormat:@"%d",sec];
	if (sec<10) {
		secStr = [NSString stringWithFormat:@"0%d",sec];
	}
	
	int min = [num intValue] / 60;
	NSString *minStr = [NSString stringWithFormat:@"%d",min];
	if (min<10) {
		minStr = [NSString stringWithFormat:@"0%d",min];
	}
	NSString *resultString = [NSString stringWithFormat:@" %@:%@ ",minStr,secStr];
	return resultString;
	
}



@end
