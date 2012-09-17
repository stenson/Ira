//
//  VLFLoopButton.m
//  Ira
//
//  Created by Robert Stenson on 9/13/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "VLFLoopButton.h"

@interface VLFLoopButton () {
    AudioUnit _unit;
    UInt32 _framesToPlay;
    Float32 _percentagePlayed;
}

@end

@implementation VLFLoopButton

static OSStatus UnitRenderCallback (void *inRefCon,
                                    AudioUnitRenderActionFlags *ioActionFlags,
                                    const AudioTimeStamp *inTimeStamp,
                                    UInt32 inBusNumber,
                                    UInt32 inNumberFrames,
                                    AudioBufferList *ioData)
{
    if (*ioActionFlags & kAudioUnitRenderAction_PostRender) {
        VLFLoopButton *button = (__bridge VLFLoopButton *)inRefCon;
        
        if (!(*ioActionFlags & kAudioUnitRenderAction_OutputIsSilence)) {
            AudioTimeStamp playTime;
            UInt32 pSize = sizeof(playTime);
            CheckError(AudioUnitGetProperty(button->_unit, kAudioUnitProperty_CurrentPlayTime, kAudioUnitScope_Global, 0, &playTime, &pSize), "current play time");
            
            UInt32 playedFrames = playTime.mSampleTime;
            button->_percentagePlayed = (Float32)(playedFrames % button->_framesToPlay) / button->_framesToPlay;
        }
    }
    
    return noErr;
}

- (void)addUnit:(AudioUnit)unit andURL:(CFURLRef)url
{
    _percentagePlayed = 0.0;
    _unit = unit;
    _framesToPlay = playableFramesInURL(url);
    
    CheckError(AudioUnitAddRenderNotify(_unit, &UnitRenderCallback, (__bridge void*)self), "unit render notifier");
}

- (void)reset
{
    _percentagePlayed = 0.0;
    [self setNeedsDisplay];
}

- (void)drawRect:(CGRect)rect
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
    
    CGContextSetRGBFillColor(context, .3f, .3f, .6f, 1.f);
    CGContextFillRect(context, CGRectMake(0, allRect.size.height/2, allRect.size.width, allRect.size.height/2));
    
    CGContextRestoreGState(context);
    
    CGContextSetRGBFillColor(context, 1.f, 1.f, 1.f, 1.f);
//    CGRect textRect = CGRectInset(allRect, 0.f, 37.f);
//    [[@"A" substringToIndex:1] drawInRect:textRect
//                                       withFont:[UIFont boldSystemFontOfSize:18]
//                                  lineBreakMode:UILineBreakModeClip
//                                      alignment:UITextAlignmentCenter];
}

@end
