//
//  PlayerView.m
//  CustomAVPlayer
//
//  Created by zjl on 2018/6/26.
//  Copyright © 2018年 zjl. All rights reserved.
//

#import "PlayerView.h"
#import<AVFoundation/AVFoundation.h>
#import "PlayerToolsView.h"

#define ToolsViewHeightRadio 0.2  //播放工具条的高度和整个播放器高度的比
@interface PlayerView()<UIGestureRecognizerDelegate>
@property (nonatomic,strong) AVPlayer *player;
@property (nonatomic,strong) AVPlayerLayer *playerLayer;
@property (nonatomic,strong) AVPlayerItem *playerItem;
@property (nonatomic,strong) UITapGestureRecognizer *tapGes;
@property (nonatomic,strong) PlayerToolsView *toolsView;
@property (nonatomic,assign) CGFloat totalSeconds;
@property (nonatomic,assign) BOOL isEnd;
@property (nonatomic,strong) UIButton *hideToolsViewButton;
@end
@implementation PlayerView

#pragma mark - Init Method
- (instancetype)initWithFrame:(CGRect)frame{
	self = [super initWithFrame:frame];
	if (self) {
		
		_hideToolsViewButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth(self.frame), (1 - ToolsViewHeightRadio) * CGRectGetHeight(self.frame))];
		[self addSubview:_hideToolsViewButton];
		_hideToolsViewButton.backgroundColor = [UIColor clearColor];
		[_hideToolsViewButton addTarget:self action:@selector(clickHideToolsViewBtn) forControlEvents:UIControlEventTouchUpInside];
		
		[self createTapGesture];
		
		[self createToolsView];

	}
	return self;
}

//创建播放的工具条
- (void)createToolsView {
	self.toolsView = [PlayerToolsView instanceView];
	self.toolsView.frame = CGRectMake(0, (1 - ToolsViewHeightRadio) * CGRectGetHeight(self.frame), CGRectGetWidth(self.frame), ToolsViewHeightRadio * CGRectGetHeight(self.frame));
	[self addSubview:self.toolsView];
	[self.toolsView.PlayButton addTarget:self action:@selector(clickPlayBtn) forControlEvents:UIControlEventTouchUpInside];
	[self.toolsView.slider setThumbImage:[UIImage imageNamed:@"point"] forState:UIControlStateNormal];
	
	[self.toolsView.slider addTarget:self action:@selector(touchDownSlider) forControlEvents:UIControlEventTouchDown];
	[self.toolsView.slider addTarget:self action:@selector(sliderValueChanged) forControlEvents:UIControlEventValueChanged];
	[self.toolsView.slider addTarget:self action:@selector(touchupSlider) forControlEvents:UIControlEventTouchUpInside];
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
	NSURL *sourceMovieURL = [NSURL fileURLWithPath:_sourcePath];
	
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

	self.toolsView.hidden = NO;
	self.hideToolsViewButton.hidden = NO;
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
	self.toolsView.hidden = YES;
	self.hideToolsViewButton.hidden = YES;
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
