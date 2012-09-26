//
//  VLFRecordButton.m
//  Ira
//
//  Created by Robert Stenson on 8/30/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "VLFRecordButton.h"
#import <QuartzCore/QuartzCore.h>

static const CGFloat kStandbyRed[4] = { .8f, .2f, .2f, 1.f };
static const CGFloat kRecordingRed[4] = { 1.f, .2f, .2f, 1.f };

@interface VLFRecordButton () {
    AudioUnit _au;
    Float32 _inputGain;
    NSDate *_pressedDate;
    
    BOOL _recording;
}

@end

@implementation VLFRecordButton

@synthesize graph = _graph;

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        CADisplayLink *link = [CADisplayLink displayLinkWithTarget:self selector:@selector(updateGraphics:)];
        [link addToRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
        [self addTarget:self action:@selector(recordPressed) forControlEvents:UIControlEventTouchUpInside];
    }
    return self;
}

- (void)recordPressed
{
    _pressedDate = [NSDate date];
    _recording = [_graph toggleRecording];
}

- (void)updateGraphics:(CADisplayLink *)link
{
    if (YES) {
        _inputGain = [_graph getMicrophoneAverageDecibels] * 10;
        _inputGain = floorf(_inputGain * 100) / 100 + 0.45;
        _inputGain = fminf(_inputGain, 1.f);
    } else {
        _inputGain = [_graph getMicrophoneAverageDecibels] / 9500;
        _inputGain = powf(10, _inputGain) / 10;
        _inputGain = fmaxf(_inputGain, .3f);
    }
    
    [self setNeedsDisplay];
}

- (void)drawRect:(CGRect)rect
{
    CGFloat inputLevel = 1 - (floorf(_inputGain * 50) / 50);
    CGFloat inset = 1.f;
    
    CGRect allRect = self.bounds;
    CGRect insetRect = CGRectInset(allRect, inset, inset);
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    CGFloat radius = insetRect.size.width / 2;
    CGRect inputRect = CGRectInset(insetRect, radius * inputLevel, radius * inputLevel);
    CGContextSetFillColor(context, _recording ? kRecordingRed : kStandbyRed);
    CGContextFillEllipseInRect(context, inputRect);
    
    CGContextSetRGBStrokeColor(context, 1.f, 1.f, 1.f, 1.f);
    CGContextStrokeEllipseInRect(context, CGRectInset(inputRect, 3.f, 3.f));
    
    UIFont *bigBold = [UIFont boldSystemFontOfSize:20];
    CGFloat typeOffset = ((allRect.size.height - bigBold.pointSize) / 2.f) - 3.f;
    CGRect textRect = CGRectInset(allRect, 0.f, typeOffset);
    
    CGContextSetRGBFillColor(context, 1.f, 1.f, 1.f, 1.f);
    
    NSString *text;
    if (_recording) {
        double interval = fabs([_pressedDate timeIntervalSinceNow]);
        int remainder = (int)interval % 3600;
        text = [NSString stringWithFormat:@"%i:%i", remainder / 60, remainder % 60];
    } else {
        text = @"R";
    }
    
    [text drawInRect:textRect withFont:bigBold lineBreakMode:UILineBreakModeClip alignment:UITextAlignmentCenter];
}

@end
