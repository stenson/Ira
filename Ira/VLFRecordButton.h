//
//  VLFRecordButton.h
//  Ira
//
//  Created by Robert Stenson on 8/30/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "VLFAudioGraph.h"

@interface VLFRecordButton : UIButton

@property (nonatomic) VLFAudioGraph *graph;
- (id)initWithFrame:(CGRect)frame;

@end
