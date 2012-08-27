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
static double const kTapTolerance = 0.1;

@interface VLFLoopButton () {
    VLFAudioGraph *_graph;
    CALayer *_gainLayer;
    
    int _unitIndex;
    AudioUnit _unit;
    CFURLRef _loopURLRef;
    
    BOOL _playing;
    Float32 _percentagePlayed;
    Float32 _gain;
    Float32 _fadingState;
    UInt32 _framesToPlay;
    UInt32 _framesPlayed;
    
    BOOL _dragging;
}

- (void)setGainWithValue:(Float32)gain;
@end

@implementation VLFLoopButton

@synthesize progressCircle = _progressCircle;

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
        
        if (!(*ioActionFlags & kAudioUnitRenderAction_OutputIsSilence)) {
            
            AudioTimeStamp playTime;
            UInt32 pSize = sizeof(playTime);
            CheckError(AudioUnitGetProperty(button->_unit, kAudioUnitProperty_CurrentPlayTime, kAudioUnitScope_Global, 0, &playTime, &pSize), "current play time");
            
            UInt32 playedFrames = playTime.mSampleTime;
            button->_percentagePlayed = (Float32)(playedFrames % button->_framesToPlay) / button->_framesToPlay;
        }
        
//        if (button->_fadingState != kLoopNotFading && button->_fadingState != kLoopFullVolume) {
//            if (button->_fadingState == kLoopFadingIn) {
//                if (button->_gain < 1.0) {
//                    button->_gain = button->_gain + 0.009;
//                } else {
//                    button->_fadingState = kLoopFullVolume;
//                    button->_gain = 1.0;
//                }
//            } else if (button->_fadingState == kLoopFadingOut) {
//                if (button->_gain > 0.0) {
//                    button->_gain = button->_gain - 0.005;
//                } else {
//                    button->_fadingState = kLoopNotFading;
//                    button->_gain = 0.0;
//                }
//            }
//            
//            [button setGainWithValue:button->_gain];
//        }
    }
    
    return noErr;
}

#pragma mark public

- (id)initWithFrame:(CGRect)frame audioUnitIndex:(int)index audioGraph:(VLFAudioGraph *)graph andLoopTitle:(NSString *)loopTitle
{
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor colorWithRed:0.54 green:0.74 blue:0.64 alpha:0.2];
        
        self.layer.shadowOffset = CGSizeMake(0, 0);
        self.layer.shadowColor = [[UIColor darkGrayColor] CGColor];
        self.layer.shadowRadius = 1.0;
        self.layer.shadowOpacity = 0.4;
        
        self.layer.cornerRadius = 1.0;
        
        self.layer.borderWidth = 1.0f;
        self.layer.borderColor = [[UIColor colorWithWhite:0.4 alpha:0.6] CGColor];
        
        [self addGainLayerGivenFrame:frame];
        
        _unitIndex = index;
        _graph = graph;
        _playing = NO;
        _gain = 0.0;
        _unit = [_graph getFilePlayerForIndex:_unitIndex];
        
        _framesPlayed = 0;
        
        NSString *filePath = [[NSBundle mainBundle] pathForResource:loopTitle ofType:@"m4a"];
        _loopURLRef = CFURLCreateWithFileSystemPath(kCFAllocatorDefault, (__bridge CFStringRef)filePath, kCFURLPOSIXPathStyle, false);
        
        [self addCallbacks];
    }
    return self;
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    _dragging = NO;
    [self setGainWithTouches:touches];
    
    if (!_playing) {
        [self performSelector:@selector(playLoop) withObject:self afterDelay:0.1];
    }
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{    
    if (!_playing) {
        [NSObject cancelPreviousPerformRequestsWithTarget:self];
        [self playLoop];
    }
    _dragging = YES;
    _fadingState = kLoopFullVolume;
    [self setGainWithTouches:touches];
    [_progressCircle updatePercentProgress:_percentagePlayed];
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
}

#pragma mark private

- (UIColor *)borderColor
{
    return [UIColor colorWithWhite:0.4 alpha:1.0];
}

- (void)playLoop
{
    _playing = YES;
    _framesToPlay = [_graph playbackURL:_loopURLRef withLoopCount:100 andUnitIndex:_unitIndex];
}

- (void)stopLoop
{
    _playing = NO;
    _framesPlayed = 0;
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
    CGFloat red = 0.57;
    CGFloat green = 0.67;
    CGFloat blue = 0.79;
    
    _gainLayer = [CALayer layer];
    _gainLayer.frame = CGRectMake(0, frame.size.height - 4, frame.size.width, frame.size.height);
    _gainLayer.backgroundColor = [[UIColor colorWithRed:red green:green blue:blue alpha:0.2] CGColor];
    
//    _gainLayer.shadowOffset = CGSizeMake(0, 1);
//    _gainLayer.shadowColor = [[UIColor darkGrayColor] CGColor];
//    _gainLayer.shadowRadius = 1.0;
//    _gainLayer.shadowOpacity = 0.2;
    
    CALayer *handle = [CALayer layer];
    handle.frame = CGRectMake(0, 0, _gainLayer.frame.size.width, 1);
    handle.borderWidth = 1.0;
    handle.borderColor = [[UIColor colorWithWhite:0.5 alpha:0.9] CGColor];
    //handle.backgroundColor = [[UIColor whiteColor] CGColor];
    handle.backgroundColor = [[UIColor colorWithPatternImage:[UIImage imageNamed:@"canvassimple"]] CGColor];
    
    [_gainLayer addSublayer:handle];
    [self.layer addSublayer:_gainLayer];
    
    self.layer.masksToBounds = YES;
}

- (void)setGainWithValue:(Float32)gain
{
    _gain = gain;
    [_graph setGain:_gain forMixerInput:_unitIndex];
    
    [self repositionGainLayerWithGain:_gain];
}

- (void)repositionGainLayerWithGain:(Float32)gain
{
    CGFloat yPosition = (_gainLayer.frame.size.height - 4) * (1.0 - gain);
    
    if (_dragging) {
        [CATransaction begin];
        [CATransaction setValue: (id) kCFBooleanTrue forKey: kCATransactionDisableActions];
    }
    
    _gainLayer.frame = CGRectMake(0, MAX(yPosition, 3), _gainLayer.frame.size.width, _gainLayer.frame.size.height);
    
    if (_dragging) {
        [CATransaction commit];
    }
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
