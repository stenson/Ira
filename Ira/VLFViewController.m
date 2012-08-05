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

- (void)addRecordButton
{
    record = [UIButton buttonWithType:UIButtonTypeCustom];
    [record setTitle:@"R" forState:UIControlStateNormal];
    [record setTitle:@"W" forState:UIControlStateSelected];
    [record setTitleColor:[UIColor whiteColor] forState:UIControlStateHighlighted];
    record.backgroundColor = [UIColor colorWithRed:0.86f green:0.08f blue:0.24f alpha:0.8f];
    record.layer.cornerRadius = 75.0f;
    
    record.frame = CGRectMake(40, 175, 150, 150);
    [[self view] addSubview:record];
    [record addTarget:self action:@selector(recordPressed) forControlEvents:UIControlEventTouchUpInside];
}

- (void)recordPressed
{
    [audioGraph toggleRecording];
}

- (void)viewDidLoad
{
    self.view.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"ira"]];
    
    [self addRecordButton];
    [self addStandbyButton];
    
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
