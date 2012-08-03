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
}
@property (weak, nonatomic) IBOutlet UIButton *recordButton;
@end

@implementation VLFViewController
@synthesize recordButton;

- (IBAction)recordButtonPressed:(id)sender
{
    NSLog(@"toggle");
    [audioGraph toggleRecording];
}

- (void)resetAudioGraph
{
    //if ([masterSwitch isOn]) {
    [audioGraph enableGraph];
    //} else {
    //[audioGraph disableGraph];
    //}
}

- (void)turnOffAudioGraph
{
    //if ([masterSwitch isOn]) {
    [audioGraph disableGraph];
    //}
}

- (void)addStandbyButton
{
//    standby = [UIButton buttonWithType:UIButtonTypeRoundedRect];
//    [standby setTitle:@"S" forState:UIControlStateNormal];
//    [standby setFrame:CGRectMake(0, 0, 50, 50)];
    
    standby = [UIButton buttonWithType:UIButtonTypeCustom];
    [standby setTitle:@"S" forState:UIControlStateNormal];
    [standby setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    standby.backgroundColor = [UIColor greenColor];
    standby.layer.cornerRadius = 25.0f;
    
    standby.frame = CGRectMake(100, 200, 50, 50);
    [[self view] addSubview:standby];
    [standby addTarget:self action:@selector(standbyPressed) forControlEvents:UIControlEventTouchUpInside];
}

- (void)standbyPressed
{
    NSLog(@"STANDBY STANDBY");
}

- (void)addAudioButton:(UIButton *)button withBackgroundColor:(UIColor *)color diameter:(float) andSelector:(SEL)s
{
    
}

- (void)viewDidLoad
{
    self.view.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"ira"]];
    
    [self addStandbyButton];
    
    audioGraph = [[VLFAudioGraph alloc] init];
    [audioGraph setupAudioSession];
    
    [super viewDidLoad];
}

- (void)viewDidUnload
{
    [self setRecordButton:nil];
    [super viewDidUnload];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
}



@end
