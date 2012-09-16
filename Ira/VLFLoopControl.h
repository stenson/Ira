//
//  VLFLoopButton.h
//  Ira
//
//  Created by Robert Stenson on 8/16/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>
#import "VLFAudioGraph.h"
#import "VLFAudioUtilities.h"
#import "VLFLoopMeter.h"
#import "VLFLoopButton.h"

@interface VLFLoopControl : UIButton

- (id)initWithFrame:(CGRect)frame audioUnitIndex:(int)index audioGraph:(VLFAudioGraph *)graph andLoopTitle:(NSString *)loopTitle;

@end
