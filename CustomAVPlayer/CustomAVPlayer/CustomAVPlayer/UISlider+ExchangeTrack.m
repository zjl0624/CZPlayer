//
//  UISlider+ExchangeTrack.m
//  CustomAVPlayer
//
//  Created by zjl on 2018/7/23.
//  Copyright © 2018年 zjl. All rights reserved.
//

#import "UISlider+ExchangeTrack.h"
#import <objc/runtime.h>
@implementation UISlider (ExchangeTrack)
+ (void)load {
//	Method oldMethod = class_getInstanceMethod([self class], @selector(thumbRectForBounds:trackRect:value:));
//	Method newMethod = class_getInstanceMethod([self class], @selector(reloadTrackRectForBounds:trackRect:value:));
//	method_exchangeImplementations(oldMethod, newMethod);
}

//- (CGRect)reloadTrackRectForBounds:(CGRect)bounds {
////	[self trackRectForBounds:bounds];
//	bounds.origin.x=15;
//
//	bounds.origin.y=bounds.size.height/3;
//
//	bounds.size.height=bounds.size.height/5;
//
//	bounds.size.width=bounds.size.width-30;
//
//	return bounds;
//}

- (CGRect)reloadTrackRectForBounds:(CGRect)bounds trackRect:(CGRect)rect value:(float)value {
	
	rect.origin.x = rect.origin.x - 10 ;
	
	rect.size.width = rect.size.width +20;
	CGRect resultRect = CGRectMake(0, rect.origin.y, rect.size.width + 4, rect.size.height);
	return resultRect;
}
@end
