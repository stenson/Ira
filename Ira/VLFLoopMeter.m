//
//  VLFLoopMeter.m
//  Ira
//
//  Created by Robert Stenson on 9/12/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "VLFLoopMeter.h"

static const float kFadeIncrement = 0.02;

@interface VLFLoopMeter () {
    BOOL _fading;
    NSTimer *_timer;
}

@end

@implementation VLFLoopMeter

@synthesize gain = _gain;

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        _fading = NO;
    }
    return  self;
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    [self setGainWithTouches:touches];
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
    [self setGainWithTouches:touches];
}

- (void)setGainWithTouches:(NSSet *)touches
{
    UITouch *dragTouch = [touches.allObjects objectAtIndex:0]; // should be latest touch?
    CGFloat height = self.frame.size.height;
    CGFloat y = height - [dragTouch locationInView:self].y;
    y = MAX(MIN(y, height), 0);
    [self setGain:y/height];
    [self setNeedsDisplay];
}

- (void)fadeWithTimer:(NSTimer *)timer
{
    if (_gain <= 0.0) {
        _fading = NO;
        [_timer invalidate];
    }
    [self setGain:_gain - kFadeIncrement];
    [self setNeedsDisplay];
}

- (void)fade
{
    if (_fading) {
        _fading = NO;
        [_timer invalidate];
    } else {
        _fading = YES;
        _timer = [NSTimer scheduledTimerWithTimeInterval:0.075 target:self selector:@selector(fadeWithTimer:) userInfo:nil repeats:YES];
    }
}

- (void)drawRect:(CGRect)rect
{
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGRect allRect = self.bounds;
    
    CGContextBeginPath(context);
    CGFloat cellHeight = 1;
    int i = 0;
    for (i = 0; i < 50; i++) {
        CGContextAddRect(context, CGRectMake(0, cellHeight*i + 2*i, allRect.size.width, cellHeight));
    }
    CGContextClosePath(context);
    CGContextClip(context);
    
    CGContextSetRGBFillColor(context, .9f, .9f, .9f, 1.f);
    CGContextFillRect(context, allRect);
    
    CGContextSetRGBFillColor(context, .3f, .8f, .6f, 1.f);
    CGFloat height = (1 - _gain);
    CGRect gainRect = CGRectMake(0, allRect.size.height * height, allRect.size.width, allRect.size.height);
    CGContextFillRect(context, gainRect);
}

@end
