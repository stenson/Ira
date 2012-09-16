//
//  VLFLoopMeter.h
//  Ira
//
//  Created by Robert Stenson on 9/12/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "VLFLoopControl.h"

@interface VLFLoopMeter : UIButton

@property (nonatomic) Float32 gain;

- (void)fade;

@end
