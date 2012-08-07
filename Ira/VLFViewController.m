//
//  VLFViewController.m
//  Ira
//
//  Created by Rob Stenson on 7/4/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "VLFViewController.h"
#import <QuartzCore/QuartzCore.h>

@interface VLFViewController () {
    VLFAudioGraph *audioGraph;
    UIButton *standby;
    UIButton *record;
    UIButton *loop;
}
@end

@implementation VLFViewController

- (void)restartAudioGraph
{
    [audioGraph enableGraph];
}

- (void)turnOffAudioGraph
{
    [audioGraph disableGraph];
}

- (void)addStandbyButton
{
    standby = [UIButton buttonWithType:UIButtonTypeCustom];
    [standby setTitle:@"S" forState:UIControlStateNormal];
    [standby setTitleColor:[UIColor clearColor] forState:UIControlStateNormal];
    standby.backgroundColor = [UIColor colorWithRed:0.24f green:0.70f blue:0.44f alpha:0.8f];
    standby.layer.cornerRadius = 25.0f;
    
    standby.frame = CGRectMake(15, 315, 50, 50);
    [[self view] addSubview:standby];
    [standby addTarget:self action:@selector(standbyPressed) forControlEvents:UIControlEventTouchUpInside];
}

- (void)standbyPressed
{
    NSLog(@"STANDBY STANDBY");
}

- (void)addLoopButton
{
    loop = [UIButton buttonWithType:UIButtonTypeCustom];
    [loop setTitle:@"" forState:UIControlStateNormal];
    [loop setTitle:@"" forState:UIControlStateSelected];
    [loop setTitleColor:[UIColor whiteColor] forState:UIControlStateHighlighted];
    loop.backgroundColor = [UIColor colorWithRed:0.16f green:0.08f blue:0.84f alpha:0.8f];
    loop.layer.cornerRadius = 50.0f;
    
    loop.frame = CGRectMake(40, 15, 100, 100);
    [[self view] addSubview:loop];
    [loop addTarget:self action:@selector(loopButtonPressed) forControlEvents:UIControlEventTouchUpInside];
}

- (void)loopButtonPressed
{
    [audioGraph playMusicLoop];
}

- (void)addRecordButton
{
    record = [UIButton buttonWithType:UIButtonTypeCustom];
    [record setTitle:@"" forState:UIControlStateNormal];
    [record setTitle:@"" forState:UIControlStateSelected];
    [record setTitleColor:[UIColor whiteColor] forState:UIControlStateHighlighted];
    record.backgroundColor = [UIColor colorWithRed:0.86f green:0.08f blue:0.24f alpha:0.5f];
    record.layer.cornerRadius = 75.0f;
    
    record.frame = CGRectMake(40, 175, 150, 150);
    [[self view] addSubview:record];
    [record addTarget:self action:@selector(recordPressed) forControlEvents:UIControlEventTouchUpInside];
}

- (void)animateButton:(UIButton *)button toColor:(UIColor *)color
{
    [UIView beginAnimations:nil context:nil];
    [UIView setAnimationDuration:0.5];
    button.backgroundColor = color;
    [UIView commitAnimations];
}

- (void)recordPressed
{
    BOOL state = [audioGraph toggleRecording];
    NSLog(@"state %d", state);
    
    if (state) {
        [self animateButton:record toColor:[UIColor colorWithRed:0.96f green:0.18f blue:0.34f alpha:1.0f]];
    } else {
        [self animateButton:record toColor:[UIColor colorWithRed:0.86f green:0.08f blue:0.24f alpha:0.5f]];
    }
}

- (void)viewDidLoad
{
    self.view.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"ira"]];
    
    [self addRecordButton];
    [self addStandbyButton];
    [self addLoopButton];
    
    audioGraph = [[VLFAudioGraph alloc] init];
    [audioGraph setupAudioSession];
    
    [super viewDidLoad];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
}



@end
