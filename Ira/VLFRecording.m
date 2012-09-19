//
//  VLFRecording.m
//  Ira
//
//  Created by Robert Stenson on 9/18/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "VLFRecording.h"

@implementation VLFRecording

@synthesize name = _name;
@synthesize path = _path;

- (id)initWithName:(NSString *)name andPath:(NSString *)path
{
    self = [super init];
    if (self) {
        _name = name;
        _path = path;
    }
    return self;
}

@end
