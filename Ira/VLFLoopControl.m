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

static const BOOL kTransform = YES;

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
    
    UInt32 _framesToPlay;
    Float32 _percentagePlayed;
}
@end

@implementation VLFLoopControl

#pragma mark audio callbacks

static OSStatus UnitRenderCallback (void *inRefCon,
                                    AudioUnitRenderActionFlags *ioActionFlags,
                                    const AudioTimeStamp *inTimeStamp,
                                    UInt32 inBusNumber,
                                    UInt32 inNumberFrames,
                                    AudioBufferList *ioData)
{
    if (*ioActionFlags & kAudioUnitRenderAction_PostRender) {
        VLFLoopControl *control = (__bridge VLFLoopControl *)inRefCon;
        
        if (!(*ioActionFlags & kAudioUnitRenderAction_OutputIsSilence)) {
            AudioTimeStamp playTime;
            UInt32 pSize = sizeof(playTime);
            CheckError(AudioUnitGetProperty(control->_unit, kAudioUnitProperty_CurrentPlayTime, kAudioUnitScope_Global, 0, &playTime, &pSize), "current play time");
            
            UInt32 playedFrames = playTime.mSampleTime;
            control->_percentagePlayed = (Float32)(playedFrames % control->_framesToPlay) / control->_framesToPlay;
        }
    }
    
    return noErr;
}

#pragma mark public

- (id)initWithFrame:(CGRect)frame audioUnitIndex:(int)index audioGraph:(VLFAudioGraph *)graph andLoopTitle:(NSString *)loopTitle
{
    self = [super initWithFrame:frame];
    if (self) {
        
        self.opaque = NO;
        
        _unitIndex = index;
        _graph = graph;
        _playing = NO;
        _unit = [_graph getFilePlayerForIndex:_unitIndex];
        
        _loopTitle = loopTitle;
        
        NSString *filePath = [[NSBundle mainBundle] pathForResource:loopTitle ofType:@"m4a"];
        _loopURLRef = CFURLCreateWithFileSystemPath(kCFAllocatorDefault, (__bridge CFStringRef)filePath, kCFURLPOSIXPathStyle, false);
        _framesToPlay = playableFramesInURL(_loopURLRef);
        _percentagePlayed = 0.0;
        CheckError(AudioUnitAddRenderNotify(_unit, &UnitRenderCallback, (__bridge void*)self), "unit render notifier");
        
        CADisplayLink *link = [CADisplayLink displayLinkWithTarget:self selector:@selector(updateGraphics:)];
        [link addToRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
        
        CGRect loopMeterRect = CGRectMake(0, 4, self.frame.size.width - 1, self.bounds.size.height - 110);
        _meter = [[VLFLoopMeter alloc] initWithFrame:loopMeterRect];
        _meter.gain = 0.0;
        [self addSubview:_meter];
        
        [_meter addObserver:self forKeyPath:@"gain" options:NSKeyValueObservingOptionNew context:NULL];
        
        CGRect buttonRect = CGRectMake(5, self.frame.size.height - 86, 62, 62);
        _button = [[VLFLoopButton alloc] initWithFrame:buttonRect];
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
        [self playLoop];
    } else {
        [_meter fade];
    }
}


- (void)updateGraphics:(CADisplayLink *)link
{
    if (_playing) {
        if (kTransform) {
            _button.transform = CGAffineTransformMakeRotation(_percentagePlayed * 2 * M_PI);
        } else {
            _button.percentagePlayed = _percentagePlayed;
            [_button setNeedsDisplay];
        }
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
    _percentagePlayed = 0.0;
    if (kTransform) {
        _button.transform = CGAffineTransformMakeRotation(_percentagePlayed * 2 * M_PI);
    } else {
        [_button reset];
    }
}

@end
