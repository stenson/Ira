//
//  VLFRecordButton.m
//  Ira
//
//  Created by Robert Stenson on 8/30/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "VLFRecordButton.h"
#import <QuartzCore/QuartzCore.h>

@interface VLFRecordButton () {
    AudioUnit _au;
    Float32 _inputGain;
    float *_scratchBuffer;
}

@end

@implementation VLFRecordButton

float getMeanVolumeSint16( SInt16 * vector , int length ) {
    
    
    // get average input volume level for meter display
    // by calculating log of mean volume of the buffer
    // and displaying it to the screen
    // (note: there's a vdsp function to do this but it works on float samples
    
    int sum;
    int i;
    int averageVolume;
    float logVolume;
    
    
    sum = 0;    
    for ( i = 0; i < length ; i++ ) {
        sum += abs((int) vector[i]);
    }
    
    averageVolume = sum / length;
    
    //    printf("\naverageVolume before scale = %lu", averageVolume );
    
    // now convert to logarithm and scale log10(0->32768) into 0->1 for display
    
    
    logVolume = log10f( (float) averageVolume ); 
    logVolume = logVolume / log10(32768);
    
    return (logVolume);
    
}

- (id)initWithFrame:(CGRect)frame andAudioUnit:(AudioUnit)unit
{
    self = [super initWithFrame:frame];
    if (self) {
        _au = unit;
        _scratchBuffer = (void *) malloc(2048 * sizeof(float));
        
        //CheckError(AudioUnitAddRenderNotify(_au, &MicrophoneCallback, (__bridge void*)self), "microphone notify");
        
        CADisplayLink *link = [CADisplayLink displayLinkWithTarget:self selector:@selector(updateGraphics:)];
        [link addToRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    }
    return self;
}

- (void)updateGraphics:(CADisplayLink *)link
{
    [self setNeedsDisplay];
}

- (void)drawRect:(CGRect)rect
{
    CGRect allRect = self.bounds;
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    CGContextSetRGBFillColor(context, 0.8, 0.4, 0.4, 1.0);
    CGContextFillRect(context, allRect);
    
    float inputLevel = 1 - ((_inputGain - 0.86) * 10);
    CGRect inputRect = CGRectMake(0, allRect.size.height * inputLevel, allRect.size.width, allRect.size.width);
    
    CGContextSetRGBFillColor(context, 0.5, 0.2, 0.2, 1.0);
    CGContextFillRect(context, inputRect);
}

@end
