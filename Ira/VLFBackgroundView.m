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
    
    CGContextSetLineWidth(context, 0.3f);
    CGContextSetRGBStrokeColor(context, .5f, .5f, .5f, 1.f);
    
    [self drawLines:context];
    
    CGContextSetRGBFillColor(context, .4f, .4f, .4f, 1.f);
    UIFont *logotype = [UIFont fontWithName:@"Courier-Bold" size:12];
    [@"Ira" drawInRect:CGRectInset(self.bounds, 8.f, 6.f) withFont:logotype];
}

- (void)drawLines:(CGContextRef)context
{
    CGPoint origin = _loopsRect.origin;
    CGSize size = _loopsRect.size;
    CGContextBeginPath(context);
    
    // record top
    CGContextMoveToPoint(context, _recordRect.origin.x, _recordRect.origin.y);
    CGContextAddLineToPoint(context, _recordRect.size.width, _recordRect.origin.y);
    
    CGContextMoveToPoint(context, size.width + 6, 0);
    CGContextAddLineToPoint(context, size.width + 6, self.bounds.size.height);
    
    // top
    CGContextMoveToPoint(context, origin.x, origin.y);
    CGContextAddLineToPoint(context, size.width, origin.y);
    
    // bottom
    CGContextMoveToPoint(context, origin.x, origin.y + size.height);
    CGContextAddLineToPoint(context, size.width, origin.y + size.height);
    
    // stroke em
    CGContextStrokePath(context);
    
    CGContextSetRGBFillColor(context, 1.f, 1.f, 1.f, 1.f);
    CGContextFillRect(context, _loopsRect);
    
    int i = 0;
    for (i = 0; i < 5000; i++) {
        CGFloat dim = .5f;
        
        if (arc4random_uniform(2) > 1) {
            dim = 1.5f;
            CGContextSetRGBFillColor(context, .8f, .8f, .8f, 1.f);
        } else {
            CGContextSetRGBFillColor(context, .7f, .7f, .7f, 1.f);
        }
        CGContextFillRect(context, CGRectMake(_loopsRect.origin.x + arc4random_uniform(_loopsRect.size.width),
                                              _loopsRect.origin.y + arc4random_uniform(_loopsRect.size.height),
                                              dim, dim));
    }
}

@end
