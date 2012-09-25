//
//  VLFBackgroundView.m
//  Ira
//
//  Created by Robert Stenson on 9/13/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "VLFBackgroundView.h"

@implementation VLFBackgroundView

@synthesize recordRect = _recordRect;
@synthesize loopsRect = _loopsRect;

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        self.opaque = NO;
    }
    return self;
}

- (void)drawRect:(CGRect)rect
{
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    CGRect speckRect = CGRectInset(_loopsRect, -4.f, -4.f);
    
    CGContextSetLineWidth(context, 2.f);
    CGContextSetRGBStrokeColor(context, .4f, .4f, .4f, .15f);
    CGContextStrokeRect(context, speckRect);
    
    CGContextSetRGBFillColor(context, 1.f, 1.f, 1.f, 1.f);
    CGContextFillRect(context, speckRect);
    
    int i = 0;
    for (i = 0; i < 7000; i++) {
        CGFloat dim = .5f;
        
        if (arc4random_uniform(2) > 1) {
            dim = 1.5f;
            CGContextSetRGBFillColor(context, .8f, .8f, .8f, 1.f);
        } else {
            CGContextSetRGBFillColor(context, .7f, .7f, .7f, 1.f);
        }
        CGContextFillRect(context, CGRectMake(speckRect.origin.x + arc4random_uniform(speckRect.size.width),
                                              speckRect.origin.y + arc4random_uniform(speckRect.size.height),
                                              dim, dim));
        
        CGContextFillRect(context, CGRectMake(arc4random_uniform(_recordRect.size.width),
                                              arc4random_uniform(_recordRect.origin.y),
                                              dim, dim));
    }
    
    CGContextSetRGBFillColor(context, .4f, .4f, .4f, 1.f);
    UIFont *logotype = [UIFont fontWithName:@"Courier-Bold" size:12];
    [@"Ira" drawInRect:CGRectInset(self.bounds, 8.f, 6.f) withFont:logotype];
}

@end
