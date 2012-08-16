//
//  VLFViewController.h
//  Ira
//
//  Created by Rob Stenson on 7/4/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "VLFAudioGraph.h"
#import "VLFLoopButton.h"

@interface VLFViewController : UIViewController
- (void)restartAudioGraph;
- (void)turnOffAudioGraph;
@end
