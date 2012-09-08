//
//  VLFRecordButton.m
//  Ira
//
//  Created by Robert Stenson on 8/30/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "VLFRecordButton.h"
#import <QuartzCore/QuartzCore.h>

@interface VLFRecordButton () {
    AudioUnit _au;
    Float32 _inputGain;
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
    }
    return self;
}

- (void)updateGraphics:(CADisplayLink *)link
{
    NSLog(@"average %f", [_graph getMicrophoneAverageDecibels]);
    [self setNeedsDisplay];
}

- (void)drawRect:(CGRect)rect
{
    CGRect allRect = self.bounds;
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    CGContextSetRGBFillColor(context, 0.8, 0.4, 0.4, 1.0);
    CGContextFillRect(context, allRect);
    
    float inputLevel = 1 - ((_inputGain - 0.86) * 10);
    CGRect inputRect = CGRectMake(0, allRect.size.height * inputLevel, allRect.size.width, allRect.size.width);
    
    CGContextSetRGBFillColor(context, 0.5, 0.2, 0.2, 1.0);
    CGContextFillRect(context, inputRect);
}

@end
