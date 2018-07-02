//
//  PlayerView.h
//  CustomAVPlayer
//
//  Created by zjl on 2018/6/26.
//  Copyright © 2018年 zjl. All rights reserved.
//

#import <UIKit/UIKit.h>
#define NetMp4Url  @"http://220.249.115.46:18080/wav/day_by_day.mp4"
@interface PlayerView : UIView
@property (nonatomic,copy) NSString *sourcePath;
@end
