//
//  VLFLoopButton.m
//  Ira
//
//  Created by Robert Stenson on 8/16/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "VLFLoopButton.h"

static UInt32 const kLoopNotFading = 0;
static UInt32 const kLoopFadingIn = 1;
static UInt32 const kLoopFadingOut = 2;
static UInt32 const kLoopFullVolume = 3;

static Float32 const kProgressAnimationMS = 0.016;

static Float32 const kDragGainLowerBound = 0.1;
static double const kTapTolerance = 0.1;

@interface VLFLoopButton () {
    VLFAudioGraph *_graph;
    CGImageRef _image;
    
    int _unitIndex;
    AudioUnit _unit;
    CFURLRef _loopURLRef;
    
    BOOL _playing;
    Float32 _percentagePlayed;
    Float32 _gain;
    Float32 _fadingState;
    UInt32 _framesToPlay;
    
    NSTimer *_timer;
    
    BOOL _dragging;
}

- (void)setGainWithValue:(Float32)gain;
@end

@implementation VLFLoopButton

#pragma mark callbacks

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

#pragma mark public

- (id)initWithFrame:(CGRect)frame audioUnitIndex:(int)index audioGraph:(VLFAudioGraph *)graph andLoopTitle:(NSString *)loopTitle
{
    self = [super initWithFrame:frame];
    if (self) {
        
        _unitIndex = index;
        _graph = graph;
        _playing = NO;
        _gain = 0.0;
        _unit = [_graph getFilePlayerForIndex:_unitIndex];
        _percentagePlayed = 0.0;
        
        _image = [[UIImage imageNamed:@"image"] CGImage];
        
        NSString *filePath = [[NSBundle mainBundle] pathForResource:loopTitle ofType:@"m4a"];
        _loopURLRef = CFURLCreateWithFileSystemPath(kCFAllocatorDefault, (__bridge CFStringRef)filePath, kCFURLPOSIXPathStyle, false);
        
        [self addCallbacks];
    }
    return self;
}

- (void)updateGraphics:(NSTimer *)timer
{
    if (_playing) {
        [self setNeedsDisplay];
    }
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    _dragging = NO;
    [self setGainWithTouches:touches];
    
    if (!_playing) {
        [self performSelector:@selector(playLoop) withObject:self afterDelay:0.1];
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
    [self setNeedsDisplay];
    //[_progressCircle updatePercentProgress:_percentagePlayed];
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    if (_gain < kDragGainLowerBound) {
        [self stopLoop];
        [self setGainWithValue:0.0];
    }
    
//    if (_dragging && !_playing) {
//        _fadingState = kLoopFullVolume;
//        //[self simpleButtonPressedWithFade:NO];
//    } else if (!_dragging) {
//        //[self simpleButtonPressedWithFade:YES];
//    }
}

- (void)drawRect:(CGRect)rect
{
    CGRect allRect = self.bounds;
    CGRect circleRect = CGRectInset(allRect, 0.0f, 0.0f);
    
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    // Draw background
    CGContextSetRGBFillColor(context, 0.9f, 0.9f, 0.9f, 1.0f);
    CGContextFillEllipseInRect(context, circleRect);
    
    CGContextSaveGState(context);
    
    // animated progress circle
    CGPoint center = CGPointMake(allRect.size.width / 2, allRect.size.height / 2);
    CGFloat radius = (allRect.size.width - 4) / 2;
    CGFloat startAngle = - ((float)M_PI / 2); // 90 degrees
    CGFloat endAngle = (_percentagePlayed * 2 * (float)M_PI) + startAngle;
    CGFloat trailingAngle = endAngle - startAngle/15;
    //CGContextSetRGBFillColor(context, 0.8, 0.8, 0.8, 0.8f);
    CGContextMoveToPoint(context, center.x, center.y);
    CGContextAddArc(context, center.x, center.y, radius, trailingAngle, endAngle, 0);
    CGContextClosePath(context);
    //CGContextFillPath(context);
    
    CGContextClip(context);
    
    CGFloat gainHeight = (1 - _gain) * self.bounds.size.height;
    CGRect ungainHalf = CGRectMake(0, 0, self.bounds.size.width, gainHeight);
    CGRect gainHandle = CGRectMake(0, gainHeight, self.bounds.size.width, 10);
    CGRect gainHalf = CGRectMake(0, gainHeight + 10, self.bounds.size.width, self.bounds.size.height);
    CGContextSetRGBFillColor(context, 0.0, 0.0, 0.0, 0.4);
    CGContextFillRect(context, ungainHalf);
    CGContextSetRGBFillColor(context, 0.0, 0.0, 0.0, 1.0);
    CGContextFillRect(context, gainHandle);
    CGContextSetRGBFillColor(context, 0.0, 0.0, 0.0, 0.7);
    CGContextFillRect(context, gainHalf);
    
    CGContextRestoreGState(context);
    
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
    //CGContextSetRGBFillColor(context, 0.5, 0.5, 0.9, 1.0);
    //CGContextFillPath(context);
    
    CGContextClip(context);
    CGContextRotateCTM(context, arc4random());
    CGContextDrawImage(context, centralRect, _image);
    //CGContextClearRect(context, centralRect);
//    CGContextSetRGBFillColor(context, 0.4, 0.5, 0.9, 1.0);
//    CGContextFillRect(context, gainHandle);
}

#pragma mark private

- (UIColor *)borderColor
{
    return [UIColor colorWithWhite:0.4 alpha:1.0];
}

- (void)playLoop
{
    _playing = YES;
    _framesToPlay = [_graph playbackURL:_loopURLRef withLoopCount:100 andUnitIndex:_unitIndex];
    _timer = [NSTimer scheduledTimerWithTimeInterval:kProgressAnimationMS target:self selector:@selector(updateGraphics:) userInfo:nil repeats:YES];
}

- (void)stopLoop
{
    _playing = NO;
    _percentagePlayed = 0.0;
    _gain = 0.0;
    AudioUnitReset(_unit, kAudioUnitScope_Global, 0);
    [_timer invalidate];
    [self setNeedsDisplay];
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

- (void)addCallbacks
{
    CheckError(AudioUnitAddRenderNotify(_unit, &UnitRenderCallback, (__bridge void*)self), "unit render notifier");
}

@end
