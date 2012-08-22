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

static Float32 const kDragGainLowerBound = 0.1;

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

//        self.backgroundColor = [UIColor colorWithRed:0.8f green:0.9f blue:0.8f alpha:0.1];
//        self.layer.cornerRadius = self.frame.size.height / 2;
//        self.layer.borderWidth = 1.0f;
//        self.layer.borderColor = [[self borderColor] CGColor];
        
//        self.layer.shadowOffset = CGSizeMake(0, 1);
//        self.layer.shadowColor = [[UIColor darkGrayColor] CGColor];
//        self.layer.shadowRadius = 1.0;
//        self.layer.shadowOpacity = 0.2;
        
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
    [self setGainWithTouches:touches];
    
    if (!_playing) {
        [self playLoop];
    }
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
    _dragging = YES;
    _fadingState = kLoopFullVolume;
    
    [self setGainWithTouches:touches];
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    if (_gain < kDragGainLowerBound) {
        [self stopLoop];
        [self setGainWithValue:0.0];
    }
    
//    if (_dragging && !_playing) {
//        _fadingState = kLoopFullVolume;
//        //[self simpleButtonPressedWithFade:NO];
//    } else if (!_dragging) {
//        //[self simpleButtonPressedWithFade:YES];
//    }
    
    _dragging = NO;
}

#pragma mark private

- (UIColor *)borderColor
{
    return [UIColor colorWithWhite:0.4 alpha:1.0];
}

- (void)playLoop
{
    _playing = YES;
    [_graph playbackURL:_loopURLRef withLoopCount:100 andUnitIndex:_unitIndex];
}

- (void)stopLoop
{
    _playing = NO;
    AudioUnitReset(_unit, kAudioUnitScope_Global, 0);
}

- (void)setGainWithTouches:(NSSet *)touches
{
    UITouch *dragTouch = [touches.allObjects objectAtIndex:0];
    CGFloat height = self.frame.size.height;
    CGFloat y = height - [dragTouch locationInView:self].y;
    y = MAX(MIN(y, height), 0);
    [self setGainWithValue:(y/height)];
}

- (void)addGainLayerGivenFrame:(CGRect)frame
{
    CALayer *circle = [CALayer layer];
    circle.frame = CGRectMake(0, 0, frame.size.width, frame.size.height);
    circle.borderWidth = 1.0f;
    circle.borderColor = [[self borderColor] CGColor];
    
    circle.shadowOffset = CGSizeMake(0, 1);
    circle.shadowColor = [[UIColor darkGrayColor] CGColor];
    circle.shadowRadius = 1.0;
    circle.shadowOpacity = 0.2;
    
    _gainLayer = [CALayer layer];
    _gainLayer.frame = CGRectMake(-2, frame.size.height, frame.size.width + 2, frame.size.height + 2);
    _gainLayer.backgroundColor = [[UIColor colorWithRed:0.56f green:0.78f blue:0.64f alpha:0.2] CGColor];
    
    _gainLayer.borderWidth = 1.0;
    _gainLayer.borderColor = [[self borderColor] CGColor];
    
    _gainLayer.shadowOffset = CGSizeMake(0, 1);
    _gainLayer.shadowColor = [[UIColor darkGrayColor] CGColor];
    _gainLayer.shadowRadius = 1.0;
    _gainLayer.shadowOpacity = 0.2;
    
//    _gainLayer.borderWidth = 1.0f;
//    _gainLayer.borderColor = [[UIColor colorWithWhite:0.3 alpha:1.0] CGColor];
    
    [self.layer insertSublayer:_gainLayer above:self.layer];
    [self.layer insertSublayer:circle above:self.layer];
    
    self.layer.masksToBounds = YES;
}

- (void)setGainWithValue:(Float32)gain
{
    _gain = gain;
    [_graph setGain:_gain forMixerInput:_unitIndex];
    
//    if (_gain == 0.0) {
//        NSLog(@"DOING THIS");
//        _playing = false;
//        AudioUnitReset(_unit, kAudioUnitScope_Global, 0);
//    }
    
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
