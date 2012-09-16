//
//  VLFLoopButton.h
//  Ira
//
//  Created by Robert Stenson on 9/13/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AudioToolbox/AudioToolbox.h>
#import "VLFAudioUtilities.h"

@interface VLFLoopButton : UIButton

- (void)addUnit:(AudioUnit)unit andURL:(CFURLRef)url;
- (void)reset;

@end
