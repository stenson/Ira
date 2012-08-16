//
//  VLFFadeableLoop.h
//  Ira
//
//  Created by Robert Stenson on 8/15/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AudioToolbox/AudioToolbox.h>
#import "VLFAudioUtilities.h"

@interface VLFFadeableLoop : NSObject

- (id)initWithUnit:(AudioUnit)unit title:(NSString *)title andDelegate:(id)delegate;
- (int)shiftLoopState;

@end
