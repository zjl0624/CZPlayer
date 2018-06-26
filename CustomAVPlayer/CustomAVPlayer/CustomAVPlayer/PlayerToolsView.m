//
//  PlayerToolsView.m
//  CustomAVPlayer
//
//  Created by zjl on 2018/6/26.
//  Copyright © 2018年 zjl. All rights reserved.
//

#import "PlayerToolsView.h"

@implementation PlayerToolsView

+ (instancetype)instanceView {
	return [[[NSBundle mainBundle] loadNibNamed:NSStringFromClass(self) owner:nil options:nil] firstObject];
}

@end
