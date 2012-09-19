//
//  VLFLoopButton.m
//  Ira
//
//  Created by Robert Stenson on 9/13/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "VLFLoopButton.h"

@interface VLFLoopButton () {
    UIImage *_image;
}
@end

@implementation VLFLoopButton

@synthesize percentagePlayed = _percentagePlayed;

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        _image = [UIImage imageNamed:@"nemark_pic"];
    }
    return  self;
}

- (void)reset
{
    _percentagePlayed = 0.0;
    [self setNeedsDisplay];
}

- (void)drawRect:(CGRect)rect
{
    if (YES) {
        [self drawRect:rect withImage:_image];
    } else {
        [self drawColorfulRect:rect];
    }
}

- (void)drawRect:(CGRect)rect withImage:(UIImage *)image
{
    CGRect allRect = self.bounds;
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    CGFloat inset = 0.f;
    CGRect circle = CGRectInset(allRect, inset, inset);
    
    CGContextSetRGBStrokeColor(context, 1.f, 1.f, 1.f, 1.f);
    CGContextStrokeEllipseInRect(context, CGRectInset(circle, 3.f, 3.f));
    
    CGContextSaveGState(context);
    
    CGPoint center = CGPointMake(allRect.size.width/2, allRect.size.height/2);
    CGFloat radius = (allRect.size.width/2) - inset - 0.f;
    CGContextMoveToPoint(context, center.x, center.y);
    CGContextAddArc(context, center.x, center.y, radius, 0, M_PI*2, 0);
    CGContextClosePath(context);
    CGContextClip(context);
    
    CGContextTranslateCTM(context, allRect.size.width / 2, allRect.size.height / 2);
    CGContextRotateCTM(context, M_PI);
    CGContextTranslateCTM(context, -allRect.size.width/2, -allRect.size.height/2);
    
    CGContextDrawImage(context, allRect, [_image CGImage]);
    CGContextSetRGBStrokeColor(context, 1.f, 1.f, 1.f, 1.f);
    CGContextStrokeEllipseInRect(context, CGRectInset(circle, 4.f, 4.f));
    
    CGContextRestoreGState(context);
    CGContextSaveGState(context);
    
    CGFloat radius2 = (allRect.size.width/2) - inset - 8.f;
    CGContextMoveToPoint(context, center.x, center.y);
    CGContextAddArc(context, center.x, center.y, radius2, 0, M_PI*2, 0);
    CGContextClosePath(context);
    CGContextClip(context);
    
    CGContextTranslateCTM(context, allRect.size.width / 2, allRect.size.height / 2);
    CGContextRotateCTM(context, ((_percentagePlayed + .125)*2) * M_PI);
    CGContextTranslateCTM(context, -allRect.size.width/2, -allRect.size.height/2);
    
    CGContextSetRGBFillColor(context, 1.f, 1.f, 1.f, .4f);
    CGContextSetRGBFillColor(context, .3f, .3f, .7f, 1.f);
    CGContextFillRect(context, CGRectMake(0, allRect.size.height*.66, allRect.size.width, allRect.size.height/3));
    
    CGContextRestoreGState(context);
    
    [[UIColor clearColor] setFill];
    CGContextSetLineWidth(context, 1.f);
    CGContextStrokeEllipseInRect(context, allRect);
}

- (void)drawColorfulRect:(CGRect)rect
{
    CGRect allRect = self.bounds;
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    CGFloat inset = 0.f;
    CGRect circle = CGRectInset(allRect, inset, inset);
    CGContextSetRGBFillColor(context, .3f, .3f, .9f, 1.f);
    CGContextFillEllipseInRect(context, circle);
    
    CGContextSetRGBStrokeColor(context, 1.f, 1.f, 1.f, 1.f);
    CGContextStrokeEllipseInRect(context, CGRectInset(circle, 3.f, 3.f));
    
    CGContextSaveGState(context);
    
    CGPoint center = CGPointMake(allRect.size.width/2, allRect.size.height/2);
    CGFloat radius = (allRect.size.width/2) - inset - 6.f;
    CGContextMoveToPoint(context, center.x, center.y);
    CGContextAddArc(context, center.x, center.y, radius, 0, M_PI*2, 0);
    CGContextClosePath(context);
    CGContextClip(context);
    
    CGContextTranslateCTM(context, allRect.size.width / 2, allRect.size.height / 2);
    CGContextRotateCTM(context, ((_percentagePlayed + .125)*2) * M_PI);
    CGContextTranslateCTM(context, -allRect.size.width/2, -allRect.size.height/2);
    
    CGContextSetRGBFillColor(context, .3f, .3f, .7f, 1.f);
    CGContextFillRect(context, CGRectMake(0, allRect.size.height/2, allRect.size.width, allRect.size.height/2));
    
    CGContextRestoreGState(context);
    
    [[UIColor clearColor] setFill];
    CGContextSetLineWidth(context, 1.f);
    CGContextStrokeEllipseInRect(context, allRect);
}

@end
