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
    int _unitIndex;
    AudioUnit _unit;
    CFURLRef _loopURLRef;
    
    BOOL _playing;
    Float32 _fading;
    Float32 _fadingState;
}
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
                if (button->_fading < 1.0) {
                    button->_fading = button->_fading + 0.001;
                } else {
                    button->_fadingState = kLoopFullVolume;
                    button->_fading = 1.0;
                }
            } else if (button->_fadingState == kLoopFadingOut) {
                if (button->_fading > 0.0) {
                    button->_fading = button->_fading - 0.001;
                } else {
                    button->_fadingState = kLoopNotFading;
                    button->_playing = false;
                    button->_fading = 0.0;
                    AudioUnitReset(button->_unit, kAudioUnitScope_Global, 0);
                }
            }

            [button->_graph setGain:button->_fading forMixerInput:button->_unitIndex];
        }
    }
    
    return noErr;
}

#pragma mark public

- (id)initWithFrame:(CGRect)frame audioUnitIndex:(int)index audioGraph:(VLFAudioGraph *)graph andLoopTitle:(NSString *)loopTitle
{
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor colorWithRed:0.16f green:0.08f blue:0.54f alpha:0.3f];
        self.layer.cornerRadius = 8.0f;
        
        _unitIndex = index;
        _graph = graph;
        _playing = false;
        _fading = kLoopNotFading;
        _unit = [_graph getFilePlayerForIndex:_unitIndex];
        
        NSString *filePath = [[NSBundle mainBundle] pathForResource:loopTitle ofType:@"m4a"];
        _loopURLRef = CFURLCreateWithFileSystemPath(kCFAllocatorDefault, (__bridge CFStringRef)filePath, kCFURLPOSIXPathStyle, false);
        
        [self addCallbacks];
        [self addTarget:self action:@selector(buttonPressed) forControlEvents:UIControlEventTouchUpInside];
    }
    return self;
}

- (void)buttonPressed
{
    if (_playing) {
        if (_fadingState == kLoopFullVolume) {
            _fadingState = kLoopFadingOut;
        } else {
            _fadingState = kLoopFadingOut;
        }
    } else {
        _fadingState = kLoopFadingIn;
        _playing = true;
        _fading = 0.3;
        
        [_graph setGain:_fading forMixerInput:_unitIndex];
        [_graph playbackURL:_loopURLRef withLoopCount:100 andUnitIndex:_unitIndex];
    }
}

#pragma mark private

- (void)addCallbacks
{
    CheckError(AudioUnitAddRenderNotify(_unit, &UnitRenderCallback, (__bridge void*)self), "unit render notifier");
}

@end
