//
//  PlayerToolsView.h
//  CustomAVPlayer
//
//  Created by zjl on 2018/6/26.
//  Copyright © 2018年 zjl. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface PlayerToolsView : UIView
@property (weak, nonatomic) IBOutlet UIButton *fullScreenButton;
@property (weak, nonatomic) IBOutlet UILabel *totalTimeLabel;
@property (weak, nonatomic) IBOutlet UISlider *slider;
@property (weak, nonatomic) IBOutlet UIButton *PlayButton;
@property (weak, nonatomic) IBOutlet UILabel *currentTimeLabel;
+ (instancetype)instanceView;
@end
