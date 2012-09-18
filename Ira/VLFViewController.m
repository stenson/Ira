//
//  VLFViewController.m
//  Ira
//
//  Created by Rob Stenson on 7/4/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "VLFViewController.h"
#import <QuartzCore/QuartzCore.h>

#define OUTER_RECORD_RECT CGRectMake(0, 28, 222, 222)
#define LOOP_BUTTONS_RECT CGRectMake(0, 250, 222, 204)
static const CGFloat kMainWidth = 234;

@interface VLFViewController () {
    VLFAudioGraph *_audioGraph;
    VLFRecordButton *_record;
    VLFBackgroundView *_background;
    
    UIScrollView *_loops;
    UITableView *_recordings;
    VLFTableViewController *_recordingsController;
}
@end

@implementation VLFViewController

- (void)restartAudioGraph
{
    [_audioGraph enableGraph];
}

- (void)turnOffAudioGraph
{
    [_audioGraph disableGraph];
}

- (void)addLoopButtons
{
    _loops = [[UIScrollView alloc] initWithFrame:LOOP_BUTTONS_RECT];
    _loops.showsHorizontalScrollIndicator = NO;
    
    NSArray *titles = [[NSArray alloc] initWithObjects:@"doowop", @"newmark", @"ukulele", @"fiddle2", nil];
    CGRect frame = LOOP_BUTTONS_RECT;
    
    CGFloat xDim = floorf(frame.size.width / 3);
    CGFloat yDim = frame.size.height;
    
    int i = 0;
    
    for (NSString *title in titles) {
        CGRect rect = CGRectMake(0 + xDim * i, 0, xDim, yDim);
        
        VLFLoopControl *button = [[VLFLoopControl alloc] initWithFrame:rect audioUnitIndex:[_audioGraph fetchFilePlayer] audioGraph:_audioGraph andLoopTitle:title];
        
        [_loops addSubview:button];
        i++;
    }
    
    _loops.contentSize = CGSizeMake(xDim * titles.count, yDim);
    [self.view addSubview:_loops];
}

- (void)addRecordButton
{
    _record = [[VLFRecordButton alloc] initWithFrame:CGRectInset(OUTER_RECORD_RECT, 10, 10)];
    _record.graph = _audioGraph;
    [[self view] addSubview:_record];
}

- (void)addTableView
{
    _recordingsController = [[VLFTableViewController alloc] initWithStyle:UITableViewStylePlain];
    
    CGFloat width = self.view.bounds.size.width - kMainWidth;
    
    _recordingsController.tableView.frame = CGRectMake(kMainWidth, 0, width, self.view.bounds.size.height);
    _recordingsController.tableView.backgroundColor = [UIColor colorWithWhite:0.97 alpha:1.0];
    
    [[self view] addSubview:_recordingsController.view];
}

- (void)addBackgroundView
{
    _background = [[VLFBackgroundView alloc] initWithFrame:self.view.frame];
    _background.recordRect = OUTER_RECORD_RECT;
    _background.loopsRect = LOOP_BUTTONS_RECT;
    
    [self.view addSubview:_background];
}

- (void)viewDidLoad
{
    self.view.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"canvassimple"]];
    
    _audioGraph = [[VLFAudioGraph alloc] init];
    [_audioGraph setupAudioSession];
    
    [self addBackgroundView];
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
