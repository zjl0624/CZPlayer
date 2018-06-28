//
//  ViewController.m
//  CustomAVPlayer
//
//  Created by zjl on 2018/6/26.
//  Copyright © 2018年 zjl. All rights reserved.
//

#import "ViewController.h"
#import "PlayerView.h"

@interface ViewController ()
- (IBAction)twoAction:(id)sender;
- (IBAction)OneAction:(id)sender;
@property (nonatomic,strong) PlayerView *playerView;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
	[self.navigationController.navigationBar setHidden:YES];
	[self initPlayerView];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


#pragma mark - Init
- (void)initPlayerView {
	self.playerView = [[PlayerView alloc] initWithFrame:CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, 200)];
	[self.view addSubview:self.playerView];
	NSString *path = [[NSBundle mainBundle] pathForAuxiliaryExecutable:@"localvideo.mp4"];
	self.playerView.sourcePath = path;
}

#pragma mark - Action
- (IBAction)twoAction:(id)sender {
	NSString *path = [[NSBundle mainBundle] pathForAuxiliaryExecutable:@"localvideo.mp4"];
	self.playerView.sourcePath = path;
}

- (IBAction)OneAction:(id)sender {
	NSString *path = [[NSBundle mainBundle] pathForAuxiliaryExecutable:@"localvideo.mp4"];
	self.playerView.sourcePath = path;
}
@end
