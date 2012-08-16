//
//  VLFFadeableLoop.m
//  Ira
//
//  Created by Robert Stenson on 8/15/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "VLFFadeableLoop.h"

@interface VLFFadeableLoop () {
    AudioUnit _unit;
    
    BOOL _playing;
    int _fading;
}
@end

@implementation VLFFadeableLoop

static OSStatus UnitRenderCallback (void *inRefCon,
                                    AudioUnitRenderActionFlags *ioActionFlags,
                                    const AudioTimeStamp *inTimeStamp,
                                    UInt32 inBusNumber,
                                    UInt32 inNumberFrames,
                                    AudioBufferList *ioData)
{
    if (*ioActionFlags & kAudioUnitRenderAction_PostRender) {
        //VLFAudioGraph *ag = (__bridge VLFAudioGraph *)inRefCon;
        printf("unit render callbacking");
    }
    
    return noErr;
}

#pragma mark public

- (id)initWithUnit:(AudioUnit)unit title:(NSString *)title andDelegate:(id)delegate
{
    self = [super init];
    if (self) {
        self->_unit = unit;
    }
    return self;
}

- (int)shiftLoopState
{
    
    return 0;
}

#pragma mark private

- (void)setupStateAndListeners
{
    _playing = false;
    _fading = 0;
    
    CheckError(AudioUnitAddRenderNotify(_unit, &UnitRenderCallback, (__bridge void*)self), "unit render notifier");
}

@end
