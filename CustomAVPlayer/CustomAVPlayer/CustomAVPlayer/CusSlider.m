//
//  CusSlider.m
//  CustomAVPlayer
//
//  Created by zjl on 2018/7/23.
//  Copyright © 2018年 zjl. All rights reserved.
//

#import "CusSlider.h"

@implementation CusSlider

- (CGRect)thumbRectForBounds:(CGRect)bounds trackRect:(CGRect)rect value:(float)value
{
	rect.origin.x = rect.origin.x - 10 ;
	rect.size.width = rect.size.width +20;
	return CGRectInset ([super thumbRectForBounds:bounds trackRect:rect value:value], 10 , 10);
}

@end
