//
//  VLFRecordButton.h
//  Ira
//
//  Created by Robert Stenson on 8/30/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AudioToolbox/AudioToolbox.h>
#import <Accelerate/Accelerate.h>
#import "VLFAudioUtilities.h"

@interface VLFRecordButton : UIButton

- (id)initWithFrame:(CGRect)frame andAudioUnit:(AudioUnit)unit;

@end
