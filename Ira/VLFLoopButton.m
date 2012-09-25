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
    UIColor *_averageColor;
}
@end

@implementation VLFLoopButton

@synthesize percentagePlayed = _percentagePlayed;

- (id)initWithFrame:(CGRect)frame andTitle:(NSString *)title
{
    self = [super initWithFrame:frame];
    if (self) {
        _image = [UIImage imageNamed:[title stringByAppendingString:@"_pic"]];
        _averageColor = [self calculateAverageColorInImage:_image];
    }
    return  self;
}

- (void)reset
{
    _percentagePlayed = 0.0;
    [self setNeedsDisplay];
}

- (UIColor *)calculateAverageColorInImage:(UIImage *)image
{
    CGSize size = {1, 1};
	UIGraphicsBeginImageContext(size);
	CGContextRef ctx = UIGraphicsGetCurrentContext();
	CGContextSetInterpolationQuality(ctx, kCGInterpolationMedium);
	[image drawInRect:(CGRect){.size = size} blendMode:kCGBlendModeCopy alpha:1];
	uint8_t *data = CGBitmapContextGetData(ctx);
	UIColor *color = [UIColor colorWithRed:data[0] / 155.0f
									 green:data[1] / 155.0f
									  blue:data[2] / 155.0f
									 alpha:0.8];
	UIGraphicsEndImageContext();
	return color;
}

- (void)drawRect:(CGRect)rect
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
    
    //CGContextSetRGBFillColor(context, .3f, .3f, .7f, 1.f);
    [_averageColor setFill];
    CGFloat denom = 2.5;
    CGContextFillRect(context, CGRectMake(0, allRect.size.height*(1-(1/denom)), allRect.size.width, allRect.size.height/denom));
    
    CGContextRestoreGState(context);
    
    [[UIColor clearColor] setFill];
    CGContextSetLineWidth(context, 1.f);
    CGContextStrokeEllipseInRect(context, allRect);
}

@end
