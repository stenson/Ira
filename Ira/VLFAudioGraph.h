//
//  VLFAudioGraph.h
//  Ira
//
//  Created by Rob Stenson on 7/4/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AudioToolbox/AudioToolbox.h>
#import "VLFAudioUtilities.h"

@interface VLFAudioGraph : NSObject

+ (UInt32)playbackURL:(CFURLRef)url withLoopCount:(UInt32)loopCount andUnit:(AudioUnit)unit;

@property (nonatomic) AudioUnit mixerUnit;
@property (nonatomic) AudioUnit rioUnit;

- (BOOL)setupAudioSession;
- (BOOL)enableGraph;
- (BOOL)disableGraph;
- (BOOL)toggleRecording;

- (AudioUnit)getFilePlayerForIndex:(int)index;
- (void)setGain:(Float32)gain forMixerInput:(int)index;
- (UInt32)playbackURL:(CFURLRef)url withLoopCount:(UInt32)loopCount andUnitIndex:(int)index;
- (int)fetchFilePlayer;

@end
