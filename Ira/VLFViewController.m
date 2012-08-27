//
//  VLFViewController.m
//  Ira
//
//  Created by Rob Stenson on 7/4/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "VLFViewController.h"
#import <QuartzCore/QuartzCore.h>
#import "VLFLoopProgressView.h"

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
    NSArray *titles = [[NSArray alloc] initWithObjects:@"doowop", @"neworleans", @"ukulele", @"fiddle2", nil];
    int dimension = 80;
    int outerDimension = 90;
    int initialXPosition = 45;
    int xPosition = initialXPosition;
    int yPosition = 240;
    int i = 1;
    
    for (NSString *title in titles) {
        CGRect rect = CGRectMake(xPosition, yPosition, dimension, dimension);
        
        VLFLoopProgressView *progress = [[VLFLoopProgressView alloc] initWithFrame:CGRectInset(rect, 15.0, 15.0)];
        VLFLoopButton *button = [[VLFLoopButton alloc] initWithFrame:rect audioUnitIndex:[audioGraph fetchFilePlayer] audioGraph:audioGraph andLoopTitle:title];
        
        button.progressCircle = progress;
        
        [self.view addSubview:progress];
        [self.view addSubview:button];
        
        [progress updatePercentProgress:0.1];
        
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
    [record setTitleColor:[UIColor whiteColor] forState:UIControlStateHighlighted];
    
    record.backgroundColor = [UIColor colorWithRed:0.96f green:0.28f blue:0.34f alpha:0.3f];
    
    record.layer.cornerRadius = 170/2;
    
    record.layer.borderWidth = 1.0f;
    record.layer.borderColor = [[UIColor colorWithWhite:0.4 alpha:0.8] CGColor];
    
    record.layer.shadowOffset = CGSizeMake(0, 0);
    record.layer.shadowRadius = 0.0;
    record.layer.shadowColor = [[UIColor darkGrayColor] CGColor];
    record.layer.shadowOpacity = 0.5;
    
    record.layer.masksToBounds = YES;
    
    record.frame = CGRectMake(45, 30, 170, 170);
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
    
    if (state) {
        [self animateButton:record toColor:[UIColor colorWithRed:0.96f green:0.18f blue:0.34f alpha:1.0f]];
    } else {
        [self animateButton:record toColor:[UIColor colorWithRed:0.86f green:0.08f blue:0.24f alpha:0.1f]];
    }
}

- (void)addTableView
{
    _recordingsController = [[VLFTableViewController alloc] initWithStyle:UITableViewStylePlain];
    
    CGSize size = [[UIScreen mainScreen] bounds].size;
    CGFloat fifth = size.width/5;
    
    _recordingsController.tableView.frame = CGRectMake(fifth*4, 0, fifth*2, size.height);
    _recordingsController.tableView.backgroundColor = [UIColor colorWithWhite:0.95 alpha:1.0];
    
    _recordingsController.tableView.layer.shadowOffset = CGSizeMake(0, 0);
    _recordingsController.tableView.layer.shadowColor = [[UIColor blackColor] CGColor];
    _recordingsController.tableView.layer.shadowOpacity = 0.5;
    _recordingsController.tableView.layer.shadowRadius = 1.0;
    
    [[self view] addSubview:_recordingsController.view];
}

- (void)viewDidLoad
{
    self.view.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"canvassimple"]];
    
    audioGraph = [[VLFAudioGraph alloc] init];
    [audioGraph setupAudioSession];
    
    [self addRecordButton];
    [self addLoopButtons];
    [self addTableView];
    
    CGRect bounds = [[UIScreen mainScreen] bounds];
    
    UIView *bottomBar = [[UIView alloc] initWithFrame:CGRectMake(0, bounds.size.height - 50, bounds.size.width, 40)];
    bottomBar.backgroundColor = [UIColor colorWithWhite:1.0 alpha:1.0];
    
    bottomBar.layer.shadowOffset = CGSizeMake(0, 0);
    bottomBar.layer.shadowColor = [[UIColor blackColor] CGColor];
    bottomBar.layer.shadowOpacity = 0.4;
    bottomBar.layer.shadowRadius = 1.0;
    
    [self.view addSubview:bottomBar];
    
    [super viewDidLoad];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return interfaceOrientation == UIInterfaceOrientationPortrait;
}



@end
