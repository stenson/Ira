//
//  VLFLoopButton.m
//  Ira
//
//  Created by Robert Stenson on 8/16/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "VLFLoopControl.h"

static UInt32 const kLoopNotFading = 0;
static UInt32 const kLoopFadingIn = 1;
static UInt32 const kLoopFadingOut = 2;
static UInt32 const kLoopFullVolume = 3;
static Float32 const kDragGainLowerBound = 0.0;

@interface VLFLoopControl () {
    VLFAudioGraph *_graph;
    
    VLFLoopMeter *_meter;
    VLFLoopButton *_button;
    
    NSString *_loopTitle;
    
    int _unitIndex;
    AudioUnit _unit;
    CFURLRef _loopURLRef;
    
    BOOL _playing;
    Float32 _fadingState;
}
@end

@implementation VLFLoopControl

#pragma mark public

- (id)initWithFrame:(CGRect)frame audioUnitIndex:(int)index audioGraph:(VLFAudioGraph *)graph andLoopTitle:(NSString *)loopTitle
{
    self = [super initWithFrame:frame];
    if (self) {
        
        self.opaque = YES;
        
        _unitIndex = index;
        _graph = graph;
        _playing = NO;
        _unit = [_graph getFilePlayerForIndex:_unitIndex];
        
        _loopTitle = loopTitle;
        
        NSString *filePath = [[NSBundle mainBundle] pathForResource:loopTitle ofType:@"m4a"];
        _loopURLRef = CFURLCreateWithFileSystemPath(kCFAllocatorDefault, (__bridge CFStringRef)filePath, kCFURLPOSIXPathStyle, false);
        
        CADisplayLink *link = [CADisplayLink displayLinkWithTarget:self selector:@selector(updateGraphics:)];
        [link addToRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
        
        CGRect loopMeterRect = CGRectMake(0, 5, self.frame.size.width, self.bounds.size.height - 120);
        _meter = [[VLFLoopMeter alloc] initWithFrame:loopMeterRect];
        _meter.gain = 0.0;
        [self addSubview:_meter];
        
        [_meter addObserver:self forKeyPath:@"gain" options:NSKeyValueObservingOptionNew context:NULL];
        
        CGRect buttonRect = CGRectMake(10, self.frame.size.height - 86, 60, 60);
        _button = [[VLFLoopButton alloc] initWithFrame:buttonRect];
        [_button addUnit:_unit andURL:_loopURLRef];
        [self addSubview:_button];
        
        [_button addTarget:self action:@selector(handleButtonPressed) forControlEvents:UIControlEventTouchDown];
    }
    return self;
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if ([keyPath isEqualToString:@"gain"] && object == _meter) {
        [_graph setGain:_meter.gain forMixerInput:_unitIndex];
        if (_playing && _meter.gain <= kDragGainLowerBound) {
            [self stopLoop];
            _meter.gain = 0.0;
        }
    }
}
         
- (void)handleButtonPressed
{
    if (!_playing) {
        NSLog(@"not playing");
        [self playLoop];
    } else {
        NSLog(@"playing");
        [_meter fade];
    }
}


- (void)updateGraphics:(CADisplayLink *)link
{
    if (_playing) {
        [_button setNeedsDisplay];
    }
}

- (void)drawRect:(CGRect)rect
{
    CGRect allRect = self.bounds;
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    [[UIColor whiteColor] setFill];
    CGContextFillRect(context, allRect);
    
    int i = 0;
    for (i = 0; i < 2500; i++) {
        CGFloat dim = .5f;
        
        if (arc4random_uniform(2) > 1) {
            dim = 1.f;
            CGContextSetRGBFillColor(context, .9f, .9f, .9f, 1.f);
        } else {
            CGContextSetRGBFillColor(context, .8f, .8f, .8f, 1.f);
        }
        CGContextFillRect(context, CGRectMake(arc4random_uniform(allRect.size.width),
                                              arc4random_uniform(allRect.size.height),
                                              dim, dim));
    }
}

#pragma mark private

- (void)playLoop
{
    _playing = YES;
    [_meter setGain:_meter.gain <= 0.1 ? 1.0 : _meter.gain];
    [_meter setNeedsDisplay];
    [_graph playbackURL:_loopURLRef withLoopCount:100 andUnitIndex:_unitIndex];
}

- (void)stopLoop
{
    _playing = NO;
    AudioUnitReset(_unit, kAudioUnitScope_Global, 0);
    [_button reset];
}

@end
