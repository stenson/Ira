//
//  VLFLoopButton.m
//  Ira
//
//  Created by Robert Stenson on 8/16/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "VLFLoopControl.h"

static UInt32 const kLoopNotFading = 0;
static UInt32 const kLoopFadingIn = 1;
static UInt32 const kLoopFadingOut = 2;
static UInt32 const kLoopFullVolume = 3;

static Float32 const kProgressAnimationMS = 0.016;

static Float32 const kDragGainLowerBound = 0.1;
static double const kTapTolerance = 0.1;

@interface VLFLoopControl () {
    VLFAudioGraph *_graph;
    NSSet *_lastTouches;
    NSString *_loopTitle;
    
    int _unitIndex;
    AudioUnit _unit;
    CFURLRef _loopURLRef;
    
    BOOL _playing;
    Float32 _percentagePlayed;
    Float32 _gain;
    Float32 _fadingState;
    UInt32 _framesToPlay;
    
    BOOL _dragging;
    BOOL _touching;
}

- (void)setGainWithValue:(Float32)gain;
@end

@implementation VLFLoopControl

#pragma mark callbacks

static OSStatus UnitRenderCallback (void *inRefCon,
                                    AudioUnitRenderActionFlags *ioActionFlags,
                                    const AudioTimeStamp *inTimeStamp,
                                    UInt32 inBusNumber,
                                    UInt32 inNumberFrames,
                                    AudioBufferList *ioData)
{
    if (*ioActionFlags & kAudioUnitRenderAction_PostRender) {
        VLFLoopControl *button = (__bridge VLFLoopControl *)inRefCon;
        
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

#pragma mark public

- (id)initWithFrame:(CGRect)frame audioUnitIndex:(int)index audioGraph:(VLFAudioGraph *)graph andLoopTitle:(NSString *)loopTitle
{
    self = [super initWithFrame:frame];
    if (self) {
        
        _dragging = NO;
        _touching = NO;
        
        self.opaque = NO;
        
        _unitIndex = index;
        _graph = graph;
        _playing = NO;
        _gain = 0.0;
        _unit = [_graph getFilePlayerForIndex:_unitIndex];
        _percentagePlayed = 0.0;
        
        _loopTitle = loopTitle;
        
        NSString *filePath = [[NSBundle mainBundle] pathForResource:loopTitle ofType:@"m4a"];
        _loopURLRef = CFURLCreateWithFileSystemPath(kCFAllocatorDefault, (__bridge CFStringRef)filePath, kCFURLPOSIXPathStyle, false);
        
        CADisplayLink *link = [CADisplayLink displayLinkWithTarget:self selector:@selector(updateGraphics:)];
        [link addToRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
        
        CheckError(AudioUnitAddRenderNotify(_unit, &UnitRenderCallback, (__bridge void*)self), "unit render notifier");
    }
    return self;
}

- (void)updateGraphics:(CADisplayLink *)link
{
    if (_playing) {
        [self setNeedsDisplay];
    }
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    _touching = YES;
    _dragging = NO;
    _lastTouches = touches;
    
    if (!_playing) {
        [self performSelector:@selector(playLoop) withObject:self afterDelay:0.01];
    } else {
        [NSTimer scheduledTimerWithTimeInterval:0.025 target:self selector:@selector(fadeOutWithTimer:) userInfo:nil repeats:YES];
    }
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{    
    if (!_playing) {
        [NSObject cancelPreviousPerformRequestsWithTarget:self];
        [self playLoop];
    }
    _dragging = YES;
    _fadingState = kLoopFullVolume;
    [self setGainWithTouches:touches];
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    if (_gain < kDragGainLowerBound) {
        [self stopLoop];
        [self setGainWithValue:0.0];
    }
    
    _touching = NO;
    _dragging = NO;
}

- (void)drawRect:(CGRect)rect
{
    CGRect allRect = CGRectMake(0, 0, 100, 100);
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    CGFloat inset = 15.f;
    CGRect circle = CGRectInset(allRect, inset, inset);
    CGContextSetRGBFillColor(context, .3f, .3f, .9f, 1.f);
    CGContextFillEllipseInRect(context, circle);
    
    CGContextSetRGBStrokeColor(context, 1.f, 1.f, 1.f, 1.f);
    CGContextStrokeEllipseInRect(context, CGRectInset(circle, 3.f, 3.f));
    
    if (YES || _playing) {
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
    }
    
    CGContextSetRGBFillColor(context, 1.f, 1.f, 1.f, 1.f);
    CGRect textRect = CGRectInset(allRect, 0.f, 37.f);
    [[_loopTitle substringToIndex:1] drawInRect:textRect
                                       withFont:[UIFont boldSystemFontOfSize:18]
                                  lineBreakMode:UILineBreakModeClip
                                      alignment:UITextAlignmentCenter];
}

- (void)dontDrawRect:(CGRect)rect
{
    CGRect allRect = self.bounds;
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    CGContextSetShadow(context, CGSizeMake(0, 1), 3.0);
    
    CGFloat gainHeight = (1 - _gain) * allRect.size.height;
    CGRect ungainHalf = CGRectMake(0, 0, allRect.size.width, gainHeight);
    CGRect gainHalf = CGRectMake(0, gainHeight, allRect.size.width, allRect.size.height);
    CGContextSetRGBFillColor(context, 0.95, 0.95, 0.95, 1.0);
    CGContextFillRect(context, ungainHalf);
    CGContextSetRGBFillColor(context, 0.8, 0.3, 0.3, 1.0);
    CGContextFillRect(context, gainHalf);
    
    CGRect circleRect = CGRectInset(allRect, 7.0, 7.0);
    CGContextSetRGBFillColor(context, 1.0, 1.0, 1.0, 1.0);
    CGContextFillEllipseInRect(context, circleRect);
    
    CGContextSetShadow(context, CGSizeMake(0, 0), 0.0);
    
    CGContextSetRGBStrokeColor(context, 1.0, 1.0, 1.0, 1.0);
    CGContextSetLineWidth(context, 7.0);
    CGContextStrokeRect(context, allRect);
    
    CGContextSetShadow(context, CGSizeMake(0, 0), 0);
    CGContextSetRGBStrokeColor(context, 0.7, 0.7, 0.7, 1.0);
    CGContextSetLineWidth(context, 1.0);
    CGContextStrokeRect(context, allRect);
    
    CGContextSetShadow(context, CGSizeMake(0, 1), 2.0);
    
    CGContextSetRGBFillColor(context, 0.15, 0.15, 0.15, 0.9);
    CGContextFillEllipseInRect(context, CGRectInset(allRect, 19.f/2, 19.f/2));
    // animated progress circle
//    CGPoint center = CGPointMake(allRect.size.width / 2, allRect.size.height / 2);
//    CGFloat radius = (allRect.size.width - 19) / 2;
//    //CGFloat startAngle = - ((float)M_PI / 2); // 90 degrees
//    //CGFloat endAngle = (_percentagePlayed * 2 * (float)M_PI) + startAngle;
//    CGContextMoveToPoint(context, center.x, center.y);
//    CGContextAddArc(context, center.x, center.y, radius, 0, 2*M_PI, 0);
//    CGContextClosePath(context);
//    
//    CGContextSetRGBFillColor(context, 0.15, 0.15, 0.15, 0.9);
//    CGContextFillPath(context);
    
    // knock out the center
    CGRect insetCircleRect = CGRectInset(allRect, 23.0f, 23.0f);
    CGContextSetRGBStrokeColor(context, 0.95f, 0.95f, 0.95f, 1.0f);
    CGContextSetRGBFillColor(context, 1.0, 1.0, 1.0, 1.0);
    CGContextSetLineWidth(context, 2.0f);
    CGContextFillEllipseInRect(context, insetCircleRect);
    CGContextStrokeEllipseInRect(context, insetCircleRect);
    
    CGRect centralRect = CGRectInset(insetCircleRect, 2.0f, 2.0f);
    CGFloat insetRadius = centralRect.size.width/2;
    CGContextAddArc(context, centralRect.origin.x + insetRadius, centralRect.origin.y + insetRadius, insetRadius, 0.0, 2*M_PI, 0);
    
//    CGContextSetShadow(context, CGSizeMake(0, 0), 0);
//    
//    CGContextTranslateCTM(context, allRect.size.width / 2, allRect.size.height / 2);
//    CGContextRotateCTM(context, (_percentagePlayed*2) * M_PI);
//    CGContextTranslateCTM(context, -allRect.size.width/2, -allRect.size.height/2);
//    CGContextSetRGBFillColor(context, 0.0, 0.0, 0.0, 1.0);
//    CGContextDrawImage(context, centralRect, [_image CGImage]);
}

#pragma mark private

- (void)playLoopWithTouches:(NSSet *)touches
{
    [self setGainWithTouches:touches];
    [self playLoop];
}

- (void)playLoop
{
    _playing = YES;
    [self setGainWithValue:1.0];
    _framesToPlay = [_graph playbackURL:_loopURLRef withLoopCount:100 andUnitIndex:_unitIndex];
}

- (void)stopLoop
{
    _playing = NO;
    _percentagePlayed = 0.0;
    _gain = 0.0;
    AudioUnitReset(_unit, kAudioUnitScope_Global, 0);
    [self setNeedsDisplay];
}

- (void)fadeOutWithTimer:(NSTimer *)timer
{
    if (_gain > 0.0) {
        [self setGainWithValue:_gain - 0.005];
    } else {
        [self stopLoop];
        [timer invalidate];
    }
}

- (void)setGainWithTouches:(NSSet *)touches
{
    UITouch *dragTouch = [touches.allObjects objectAtIndex:0];
    CGFloat height = self.frame.size.height;
    CGFloat y = height - [dragTouch locationInView:self].y;
    y = MAX(MIN(y, height), 0);
    [self setGainWithValue:(y/height)];
}

- (void)setGainWithValue:(Float32)gain
{
    _gain = gain;
    [_graph setGain:_gain forMixerInput:_unitIndex];
}

- (void)simpleButtonPressedWithFade:(BOOL)shouldFade
{
    if (_playing) {
        if (_fadingState == kLoopFullVolume) {
            _fadingState = kLoopFadingOut;
        } else if (_fadingState == kLoopFadingIn) {
            _fadingState = kLoopFadingOut;
        } else {
            _fadingState = kLoopFadingIn;
        }
    } else {
        if (shouldFade) {
            _fadingState = kLoopFadingIn;
        }
        
        _playing = true;
        _gain = 0.01;
        [self setGainWithValue:_gain];
        [_graph playbackURL:_loopURLRef withLoopCount:100 andUnitIndex:_unitIndex];
    }
}

@end
