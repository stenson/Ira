//
//  VLFViewController.m
//  Ira
//
//  Created by Rob Stenson on 7/4/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "VLFViewController.h"
#import <QuartzCore/QuartzCore.h>

static const CGFloat kMainWidth = 226;

@interface VLFViewController () {
    VLFAudioGraph *_audioGraph;
    VLFRecordButton *_record;
    VLFBackgroundView *_background;
    
    CGRect _loopButtonsRect;
    CGRect _outerRecordRect;
    
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
    _loops = [[UIScrollView alloc] initWithFrame:_loopButtonsRect];
    _loops.showsHorizontalScrollIndicator = NO;
    
    NSArray *titles = [[NSArray alloc] initWithObjects:@"newmark", @"fiddle2", @"ukulele", @"newmark", nil];
    CGRect frame = _loopButtonsRect;
    
    CGFloat xDim = floorf(frame.size.width / 3);
    CGFloat yDim = frame.size.height;
    
    int i = 0;
    
    for (NSString *title in titles) {
        CGRect rect = CGRectMake(xDim * i, 0, xDim, yDim);
        
        VLFLoopControl *button = [[VLFLoopControl alloc] initWithFrame:rect audioUnitIndex:[_audioGraph fetchFilePlayer] audioGraph:_audioGraph andLoopTitle:title];
        
        [_loops addSubview:button];
        i++;
    }
    
    _loops.contentSize = CGSizeMake(xDim * titles.count, yDim);
    [self.view addSubview:_loops];
}

- (void)addRecordButton
{
    CGFloat squareDimension = _outerRecordRect.size.height - 20;
    CGFloat offset = (_outerRecordRect.size.width - squareDimension) / 2;
    _record = [[VLFRecordButton alloc] initWithFrame:CGRectMake(_outerRecordRect.origin.x + offset,
                                                                _outerRecordRect.origin.y + 00,
                                                                squareDimension, squareDimension)];
    _record.graph = _audioGraph;
    [[self view] addSubview:_record];
}

- (void)addTableView
{
    _recordingsController = [[VLFTableViewController alloc] initWithStyle:UITableViewStylePlain];
    
    CGFloat width = self.view.bounds.size.width - kMainWidth;
    
    _recordingsController.tableView.frame = CGRectMake(kMainWidth, 0, width, self.view.bounds.size.height);
    
    [[self view] addSubview:_recordingsController.view];
}

- (void)addBackgroundView
{
    _background = [[VLFBackgroundView alloc] initWithFrame:self.view.frame];
    _background.recordRect = _outerRecordRect;
    _background.loopsRect = _loopButtonsRect;
    
    [self.view addSubview:_background];
}

- (void)viewDidLoad
{
    CGFloat width = [[UIScreen mainScreen] bounds].size.width;
    CGFloat margin = 12.f;
    _outerRecordRect = CGRectMake(0, 40, width, 222);
    _loopButtonsRect = CGRectMake(margin, 262, width - margin*2, 184);
    
    self.view.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"canvassimple"]];
    
    _audioGraph = [[VLFAudioGraph alloc] init];
    [_audioGraph setupAudioSession];
    
    [self addBackgroundView];
    [self addRecordButton];
    [self addLoopButtons];
    //[self addTableView];
    
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
