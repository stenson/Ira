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
    UIFont *logotype = [UIFont fontWithName:@"Times New Roman" size:20];
    [@"Ira" drawInRect:CGRectInset(self.bounds, 8.f, 8.f) withFont:logotype];
}

- (void)drawLines:(CGContextRef)context
{
    CGPoint origin = _loopsRect.origin;
    CGSize size = _loopsRect.size;
    CGContextBeginPath(context);
    
    // record top
    CGContextMoveToPoint(context, _recordRect.origin.x, _recordRect.origin.y);
    CGContextAddLineToPoint(context, _recordRect.size.width, _recordRect.origin.y);
    
    // top
    CGContextMoveToPoint(context, origin.x, origin.y);
    CGContextAddLineToPoint(context, size.width, origin.y);
    
//    // vertical
//    CGContextMoveToPoint(context, size.width/2, origin.y);
//    CGContextAddLineToPoint(context, size.width/2, origin.y + size.height);
//    
//    // middle
//    CGContextMoveToPoint(context, origin.x, origin.y + size.height/2);
//    CGContextAddLineToPoint(context, size.width, origin.y + size.height/2);
    
    // bottom
    CGContextMoveToPoint(context, origin.x, origin.y + size.height);
    CGContextAddLineToPoint(context, size.width, origin.y + size.height);
    
    // stroke em
    CGContextStrokePath(context);
}

@end
