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
    
    UITableView *_recordings;
    VLFTableViewController *_recordingsController;
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

- (void)addLoopButtons
{
    NSArray *titles = [[NSArray alloc] initWithObjects:@"doowop", @"neworleans", @"banjo", @"fiddle2", nil];
    int dimension = 80;
    int outerDimension = 90;
    int initialXPosition = 11;
    int xPosition = initialXPosition;
    int yPosition = 280;
    int i = 1;
    
    for (NSString *title in titles) {
        [self.view addSubview:[[VLFLoopButton alloc] initWithFrame:CGRectMake(xPosition, yPosition, dimension, dimension)
                                                    audioUnitIndex:[audioGraph fetchFilePlayer]
                                                        audioGraph:audioGraph
                                                      andLoopTitle:title]];
        if (i % 2 == 0) {
            yPosition += outerDimension;
            xPosition = initialXPosition;
        } else {
            xPosition += outerDimension;
        }
        i++;
    }
}

- (void)addRecordButton
{
    record = [UIButton buttonWithType:UIButtonTypeCustom];
    [record setTitle:@"" forState:UIControlStateNormal];
    [record setTitle:@"" forState:UIControlStateSelected];
    [record setTitleColor:[UIColor whiteColor] forState:UIControlStateHighlighted];
    record.backgroundColor = [UIColor colorWithRed:0.99f green:0.99f blue:0.99f alpha:1.0f];
    record.layer.borderWidth = 1.0f;
    record.layer.borderColor = [[UIColor colorWithRed:0.86f green:0.08f blue:0.24f alpha:0.45f] CGColor];
    record.layer.cornerRadius = 85.0f;
    
    record.frame = CGRectMake(12, 100, 170, 170);
    [[self view] addSubview:record];

    [record addTarget:self action:@selector(recordPressed) forControlEvents:UIControlEventTouchUpInside];
}

- (void)animateButton:(UIButton *)button toColor:(UIColor *)color
{
    [UIView beginAnimations:nil context:nil];
    [UIView setAnimationDuration:0.15];
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

- (void)addTableView
{
    _recordingsController = [[VLFTableViewController alloc] initWithStyle:UITableViewStylePlain];
    [[self view] addSubview:_recordingsController.view];
}

- (void)viewDidLoad
{
    self.view.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"canvassimple"]];
    //self.view.backgroundColor = [UIColor colorWithRed:0.95 green:0.95 blue:0.95 alpha:1.0];
    
    audioGraph = [[VLFAudioGraph alloc] init];
    [audioGraph setupAudioSession];
    
    [self addRecordButton];
    //[self addStandbyButton];
    [self addLoopButtons];
    [self addTableView];
    
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
