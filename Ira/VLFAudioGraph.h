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

- (BOOL)setupAudioSession;
- (BOOL)enableGraph;
- (BOOL)disableGraph;
- (BOOL)toggleRecording;
- (int)playMusicLoopWithTitle:(NSString *)title;

@end
