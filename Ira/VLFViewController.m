//
//  VLFViewController.m
//  Ira
//
//  Created by Rob Stenson on 7/4/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "VLFViewController.h"
#import <QuartzCore/QuartzCore.h>

#define RECORD_BUTTON_RECT CGRectMake(30, 40, 200, 200)
#define LOOP_BUTTONS_RECT CGRectMake(0, 230, 256, 222)

@interface VLFViewController () {
    VLFAudioGraph *audioGraph;
    UIButton *standby;
    VLFRecordButton *record;
    
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
    NSArray *titles = [[NSArray alloc] initWithObjects:@"doowop", @"newmark", @"ukulele", @"fiddle2", nil];
    CGRect frame = LOOP_BUTTONS_RECT;
    
    CGFloat xDim = frame.size.width / 2;
    CGFloat yDim = frame.size.height / 2;
    
    int i = 0;
    
    for (NSString *title in titles) {
        CGFloat x = frame.origin.x + ((i % 2) * xDim);
        CGFloat y = frame.origin.y + (floorf((i / 2)) * yDim);
        NSLog(@"%f %f", x, y);
        CGRect rect = CGRectMake(x, y, xDim, yDim);
        
        VLFLoopButton *button = [[VLFLoopButton alloc] initWithFrame:rect audioUnitIndex:[audioGraph fetchFilePlayer] audioGraph:audioGraph andLoopTitle:title];
        
        [self.view addSubview:button];
        i++;
    }
}

- (void)addRecordButton
{
    record = [[VLFRecordButton alloc] initWithFrame:RECORD_BUTTON_RECT];
    record.graph = audioGraph;
    [[self view] addSubview:record];
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
    self.view.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"ira_backdrop"]];
    
    audioGraph = [[VLFAudioGraph alloc] init];
    [audioGraph setupAudioSession];
    
    [self addRecordButton];
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
    return interfaceOrientation == UIInterfaceOrientationPortrait;
}



@end
