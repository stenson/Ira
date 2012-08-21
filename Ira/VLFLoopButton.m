//
//  VLFLoopButton.m
//  Ira
//
//  Created by Robert Stenson on 8/16/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "VLFLoopButton.h"

static UInt32 const kLoopNotFading = 0;
static UInt32 const kLoopFadingIn = 1;
static UInt32 const kLoopFadingOut = 2;
static UInt32 const kLoopFullVolume = 3;

@interface VLFLoopButton () {
    VLFAudioGraph *_graph;
    CALayer *_gainLayer;
    
    int _unitIndex;
    AudioUnit _unit;
    CFURLRef _loopURLRef;
    
    BOOL _dragging;
    BOOL _playing;
    Float32 _gain;
    Float32 _fadingState;
}

- (void)setGainWithValue:(Float32)gain;
@end

@implementation VLFLoopButton

#pragma mark callbacks

static OSStatus UnitRenderCallback (void *inRefCon,
                                    AudioUnitRenderActionFlags *ioActionFlags,
                                    const AudioTimeStamp *inTimeStamp,
                                    UInt32 inBusNumber,
                                    UInt32 inNumberFrames,
                                    AudioBufferList *ioData)
{
    if (*ioActionFlags & kAudioUnitRenderAction_PostRender) {
        VLFLoopButton *button = (__bridge VLFLoopButton *)inRefCon;
        
        if (button->_fadingState != kLoopNotFading && button->_fadingState != kLoopFullVolume) {
            if (button->_fadingState == kLoopFadingIn) {
                if (button->_gain < 1.0) {
                    button->_gain = button->_gain + 0.009;
                } else {
                    button->_fadingState = kLoopFullVolume;
                    button->_gain = 1.0;
                }
            } else if (button->_fadingState == kLoopFadingOut) {
                if (button->_gain > 0.0) {
                    button->_gain = button->_gain - 0.005;
                } else {
                    button->_fadingState = kLoopNotFading;
                    button->_gain = 0.0;
                }
            }
            
            [button setGainWithValue:button->_gain];
        }
    }
    
    return noErr;
}

#pragma mark public

- (id)initWithFrame:(CGRect)frame audioUnitIndex:(int)index audioGraph:(VLFAudioGraph *)graph andLoopTitle:(NSString *)loopTitle
{
    self = [super initWithFrame:frame];
    if (self) {
        [self addGainLayerGivenFrame:frame];
        [self alterBackgroundWithAlpha:0.3f];
        self.layer.cornerRadius = 8.0f;
        
        _dragging = NO;
        _unitIndex = index;
        _graph = graph;
        _playing = false;
        _gain = 0.0;
        _unit = [_graph getFilePlayerForIndex:_unitIndex];
        
        NSString *filePath = [[NSBundle mainBundle] pathForResource:loopTitle ofType:@"m4a"];
        _loopURLRef = CFURLCreateWithFileSystemPath(kCFAllocatorDefault, (__bridge CFStringRef)filePath, kCFURLPOSIXPathStyle, false);
        
        [self addCallbacks];
    }
    return self;
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    [self alterBackgroundWithAlpha:0.4f];
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
    _dragging = YES;
    _fadingState = kLoopFullVolume;
    
    UITouch *dragTouch = [touches.allObjects objectAtIndex:0];
    CGFloat height = self.frame.size.height;
    CGFloat y = height - [dragTouch locationInView:self].y;
    y = MAX(MIN(y, height), 0);
    [self setGainWithValue:(y/height)];
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    if (_dragging && !_playing) {
        _fadingState = kLoopFullVolume;
        [self simpleButtonPressedWithFade:NO];
    } else if (!_dragging) {
        [self simpleButtonPressedWithFade:YES];
    }
    
    _dragging = NO;
    [self alterBackgroundWithAlpha:0.3f];
}

#pragma mark private

- (void)alterBackgroundWithAlpha:(CGFloat)alpha
{
    self.backgroundColor = [UIColor colorWithRed:0.16f green:0.08f blue:0.54f alpha:alpha];
}

- (void)addGainLayerGivenFrame:(CGRect)frame
{
    _gainLayer = [CALayer layer];
    _gainLayer.frame = CGRectMake(0, frame.size.height - 1, frame.size.width, frame.size.height);
    _gainLayer.backgroundColor = [[UIColor colorWithRed:0.26f green:0.18f blue:0.64f alpha:0.7] CGColor];
    
    [self.layer insertSublayer:_gainLayer above:self.layer];
    self.layer.masksToBounds = YES;
}

- (void)setGainWithValue:(Float32)gain
{
    _gain = gain;
    [_graph setGain:_gain forMixerInput:_unitIndex];
    
    if (_gain == 0.0) {
        NSLog(@"DOING THIS");
        _playing = false;
        AudioUnitReset(_unit, kAudioUnitScope_Global, 0);
    }
    
    [self repositionGainLayerWithGain:_gain];
}

- (void)repositionGainLayerWithGain:(Float32)gain
{
    [CATransaction begin];
    [CATransaction setValue: (id) kCFBooleanTrue forKey: kCATransactionDisableActions];
    _gainLayer.frame = CGRectMake(0, _gainLayer.frame.size.height * (1.0 - gain), _gainLayer.frame.size.width, _gainLayer.frame.size.height);
    [CATransaction commit];
}

- (void)simpleButtonPressedWithFade:(BOOL)shouldFade
{
    if (_playing) {
        if (_fadingState == kLoopFullVolume) {
            _fadingState = kLoopFadingOut;
        } else if (_fadingState == kLoopFadingIn) {
            _fadingState = kLoopFadingOut;
        } else {
            _fadingState = kLoopFadingIn;
        }
    } else {
        if (shouldFade) {
            _fadingState = kLoopFadingIn;
        }
        
        _playing = true;
        _gain = 0.01;
        [self setGainWithValue:_gain];
        [_graph playbackURL:_loopURLRef withLoopCount:100 andUnitIndex:_unitIndex];
    }
}

- (void)addCallbacks
{
    CheckError(AudioUnitAddRenderNotify(_unit, &UnitRenderCallback, (__bridge void*)self), "unit render notifier");
}

@end
