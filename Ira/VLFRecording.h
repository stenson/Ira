//
//  VLFRecording.h
//  Ira
//
//  Created by Robert Stenson on 9/18/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface VLFRecording : NSObject

@property (nonatomic, strong) NSString *name;
@property (nonatomic, strong) NSString *path;

- (id)initWithName:(NSString *)name andPath:(NSString *)path;

@end
