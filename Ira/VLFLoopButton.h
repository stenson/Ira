//
//  VLFLoopButton.h
//  Ira
//
//  Created by Robert Stenson on 8/16/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AudioToolbox/AudioToolbox.h>
#import <QuartzCore/QuartzCore.h>
#import "VLFAudioGraph.h"
#import "VLFAudioUtilities.h"

@interface VLFLoopButton : UIButton

- (id)initWithFrame:(CGRect)frame audioUnitIndex:(int)index audioGraph:(VLFAudioGraph *)graph andLoopTitle:(NSString *)loopTitle;

@end