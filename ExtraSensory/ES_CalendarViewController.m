//
//  ES_CalendarViewController.m
//  ExtraSensory
//
//  Created by Arya Iranmehr on 7/18/14.
//  Copyright (c) 2014 Bryan Grounds. All rights reserved.
//

#import "ES_CalendarViewController.h"
#import "MSCollectionViewCalendarLayout.h"
#import "ES_Activity.h"
#import "ES_Activity+Day.h"

// Collection View Reusable Views
#import "MSGridline.h"
#import "MSTimeRowHeaderBackground.h"
#import "MSDayColumnHeaderBackground.h"
#import "ES_ActivityCell.h"
#import "MSDayColumnHeader.h"
#import "MSTimeRowHeader.h"
#import "MSCurrentTimeIndicator.h"
#import "MSCurrentTimeGridline.h"
#import "ES_ActiveFeedbackViewController.h"
#import "ES_ActivityEventFeedbackViewController.h"
#import "ES_ActivityEvent.h"
#import "ES_UserActivityLabels.h"
#import "ES_HistoryTableViewController.h"
#import "ES_DataBaseAccessor.h"
#import "ES_AppDelegate.h"
NSString * const ESActivityCellReuseIdentifier = @"ESActivityCellReuseIdentifier";
NSString * const MSDayColumnHeaderReuseIdentifier = @"MSDayColumnHeaderReuseIdentifier";
NSString * const MSTimeRowHeaderReuseIdentifier = @"MSTimeRowHeaderReuseIdentifier";

@interface ES_CalendarViewController () <MSCollectionViewDelegateCalendarLayout, NSFetchedResultsControllerDelegate>

@property (nonatomic, strong) MSCollectionViewCalendarLayout *collectionViewCalendarLayout;
@property (nonatomic, strong) NSFetchedResultsController *fetchedResultsController;
@property (nonatomic, strong) UIButton *backButton;
@property (nonatomic, strong) UIButton *feedbackButton;
@property (nonatomic, strong) UIButton *zoomButton;
@property (nonatomic, strong) UIButton *mergeActivitiesButton;
@property (nonatomic, strong) UIButton *helpButton;
@property (nonatomic, strong) UIButton *addButton;
@property (nonatomic, strong) UIButton *removeButton;
@property (nonatomic, strong) UIButton *refreshButton;
@property (nonatomic, assign) bool displayActivityEvents;
@property (nonatomic, retain) NSMutableArray * activityEvents;
@end

@implementation ES_CalendarViewController
- (NSMutableArray *)activityEvents
{
    if (!_activityEvents)
    {
        _activityEvents = [[NSMutableArray alloc] initWithCapacity:1];
    }
    return _activityEvents;
}

- (id)init
{
    int buttonWidth=20;
    self.isDailyView=YES;
    self.collectionViewCalendarLayout = [[MSCollectionViewCalendarLayout alloc] init];
    self.collectionViewCalendarLayout.delegate = self;
    self = [super initWithCollectionViewLayout:self.collectionViewCalendarLayout];
    
    self.backButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    [self.backButton addTarget:self action:@selector(back:) forControlEvents:UIControlEventTouchUpInside];
    [self.backButton setBackgroundImage:[UIImage imageNamed:@"Back.png"] forState:UIControlStateNormal];
    self.backButton.frame = CGRectMake(5, 5, buttonWidth, buttonWidth);
    self.	backButton.titleLabel.font = [UIFont boldSystemFontOfSize:12.0];
    [self.view addSubview:self.backButton];
    
    self.mergeActivitiesButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    [self.mergeActivitiesButton addTarget:self action:@selector(mergeActivities:) forControlEvents:UIControlEventTouchUpInside];
    [self.mergeActivitiesButton setBackgroundImage:[UIImage imageNamed:@"Merge.png"] forState:UIControlStateNormal];
    self.mergeActivitiesButton.frame = CGRectMake(buttonWidth +10, 5,  buttonWidth, buttonWidth);
    self.mergeActivitiesButton.titleLabel.font = [UIFont boldSystemFontOfSize:12.0];
    [self.view addSubview:self.mergeActivitiesButton];
    
    self.feedbackButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    [self.feedbackButton addTarget:self action:@selector(activeFeedback:) forControlEvents:UIControlEventTouchUpInside];
    [self.feedbackButton setBackgroundImage:[UIImage imageNamed:@"Edit.png"] forState:UIControlStateNormal];
    self.feedbackButton.frame = CGRectMake(275.0+buttonWidth, 5.0,  buttonWidth, buttonWidth);
    self.feedbackButton.titleLabel.font = [UIFont boldSystemFontOfSize:12.0];
    [self.view addSubview:self.feedbackButton];
    
    self.zoomButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    [self.zoomButton addTarget:self action:@selector(zoom:) forControlEvents:UIControlEventTouchUpInside];
    [self.zoomButton setBackgroundImage:[UIImage imageNamed:@"Zoom_in.png"] forState:UIControlStateNormal];
    self.zoomButton.frame = CGRectMake(270.0, 5.0,  buttonWidth, buttonWidth);
    self.zoomButton.titleLabel.font = [UIFont boldSystemFontOfSize:12.0];
    [self.view addSubview:self.zoomButton];
    
    self.refreshButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    [self.refreshButton addTarget:self action:@selector(refresh:) forControlEvents:UIControlEventTouchUpInside];
    [self.refreshButton setBackgroundImage:[UIImage imageNamed:@"refresh.png"] forState:UIControlStateNormal];
    self.refreshButton.frame = CGRectMake(5, buttonWidth+5.0,  buttonWidth, buttonWidth);
    self.refreshButton.titleLabel.font = [UIFont boldSystemFontOfSize:12.0];
    [self.view addSubview:self.refreshButton];
    
    self.helpButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    [self.helpButton addTarget:self action:@selector(help:) forControlEvents:UIControlEventTouchUpInside];
    [self.helpButton setBackgroundImage:[UIImage imageNamed:@"Help.png"] forState:UIControlStateNormal];
    self.helpButton.frame = CGRectMake(buttonWidth+10, buttonWidth+5.0,  buttonWidth, buttonWidth);
    self.helpButton.titleLabel.font = [UIFont boldSystemFontOfSize:12.0];
    [self.view addSubview:self.helpButton];
    
    self.addButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    [self.addButton addTarget:self action:@selector(add:) forControlEvents:UIControlEventTouchUpInside];
    [self.addButton setBackgroundImage:[UIImage imageNamed:@"AddAct.png"] forState:UIControlStateNormal];
    self.addButton.frame = CGRectMake(275.0 + buttonWidth, 5.0 +buttonWidth,  buttonWidth, buttonWidth);
    self.addButton.titleLabel.font = [UIFont boldSystemFontOfSize:12.0];
    [self.view addSubview:self.addButton];
    
    self.removeButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    [self.removeButton addTarget:self action:@selector(remove:) forControlEvents:UIControlEventTouchUpInside];
    [self.removeButton setBackgroundImage:[UIImage imageNamed:@"Remove.png"] forState:UIControlStateNormal];
    self.removeButton.frame = CGRectMake(270.0, 5.0 +buttonWidth,  buttonWidth, buttonWidth);
    self.removeButton.titleLabel.font = [UIFont boldSystemFontOfSize:12.0];
    [self.view addSubview:self.removeButton];
    
    
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
}

-(void)fetch{
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"ES_Activity"];
    fetchRequest.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"startTime" ascending:YES]];
    
    // Divide into sections by the "day" key path
    self.fetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest managedObjectContext:[(ES_AppDelegate *)UIApplication.sharedApplication.delegate managedObjectContext] sectionNameKeyPath:@"day" cacheName:nil];
    self.fetchedResultsController.delegate = self;
    [self.fetchedResultsController performFetch:nil];
}

-(void)back:(UIButton *)sender
{
    [self.navigationController popViewControllerAnimated:YES];
}

-(void)add:(UIButton *)sender
{
}
-(void)remove:(UIButton *)sender
{
    
}
-(void)help:(UIButton *)sender
{
}
-(void)refresh:(UIButton *)sender
{
    [self fetch];
    [self.collectionViewCalendarLayout invalidateLayoutCache];
    [self.collectionView reloadData];
    [self viewDidLoad];
    [self viewWillAppear:YES];

}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    self.collectionView.backgroundColor = [UIColor whiteColor];
    
    [self.collectionView registerClass:ES_ActivityCell.class forCellWithReuseIdentifier:ESActivityCellReuseIdentifier];
    [self.collectionView registerClass:MSDayColumnHeader.class forSupplementaryViewOfKind:MSCollectionElementKindDayColumnHeader withReuseIdentifier:MSDayColumnHeaderReuseIdentifier];
    [self.collectionView registerClass:MSTimeRowHeader.class forSupplementaryViewOfKind:MSCollectionElementKindTimeRowHeader withReuseIdentifier:MSTimeRowHeaderReuseIdentifier];
    
    // These are optional. If you don't want any of the decoration views, just don't register a class for them.
    [self.collectionViewCalendarLayout registerClass:MSCurrentTimeIndicator.class forDecorationViewOfKind:MSCollectionElementKindCurrentTimeIndicator];
    [self.collectionViewCalendarLayout registerClass:MSCurrentTimeGridline.class forDecorationViewOfKind:MSCollectionElementKindCurrentTimeHorizontalGridline];
    [self.collectionViewCalendarLayout registerClass:MSGridline.class forDecorationViewOfKind:MSCollectionElementKindVerticalGridline];
    [self.collectionViewCalendarLayout registerClass:MSGridline.class forDecorationViewOfKind:MSCollectionElementKindHorizontalGridline];
    [self.collectionViewCalendarLayout registerClass:MSTimeRowHeaderBackground.class forDecorationViewOfKind:MSCollectionElementKindTimeRowHeaderBackground];
    [self.collectionViewCalendarLayout registerClass:MSDayColumnHeaderBackground.class forDecorationViewOfKind:MSCollectionElementKindDayColumnHeaderBackground];
    [self fetch];
    [self.collectionView.collectionViewLayout prepareLayout];

    [self.collectionViewCalendarLayout invalidateLayoutCache];
    [self.collectionView reloadData];
    
    [self.navigationController setNavigationBarHidden:YES animated:animated];
    [self.tabBarController.tabBar setHidden:YES	];
    for(UIView* subview in [self.tabBarController.view subviews])
        if (subview.tag==111) {
            [subview setHidden:YES];
        }
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self.navigationController setNavigationBarHidden:NO animated:animated];
    [self.tabBarController.tabBar setHidden:NO	];
    for(UIView* subview in [self.tabBarController.view subviews])
        if (subview.tag==111) {
            [subview setHidden:NO];
        }
}


-(void) activeFeedback:(UIButton*)button
{
    NSArray *indexPaths = [self.collectionView indexPathsForSelectedItems];
    if(![indexPaths count])
        return;
    NSIndexPath *indexPath = [indexPaths objectAtIndex:0];
    ES_Activity *startOfActivity=((ES_ActivityCell *)[self collectionView:self.collectionView cellForItemAtIndexPath:indexPath]).activity;
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"ActivityEventFeedback" bundle:nil];
    UIViewController *newView = [storyboard instantiateViewControllerWithIdentifier:@"ActivityEventFeedbackView"];
    ES_ActivityEventFeedbackViewController *activityFeedback = (ES_ActivityEventFeedbackViewController *)newView;
    NSMutableArray *minuteActivities = [[NSMutableArray alloc] initWithCapacity:1];
    [minuteActivities addObject:startOfActivity];
    NSMutableSet *userActivitiesStrings = [NSMutableSet setWithArray:[ES_UserActivityLabels createStringArrayFromUserActivityLabelsAraay:[startOfActivity.userActivityLabels allObjects]]];
    ES_ActivityEvent *activityEvent = [[ES_ActivityEvent alloc] initWithIsVerified:startOfActivity.isPredictionVerified serverPrediction:startOfActivity.serverPrediction userCorrection:startOfActivity.userCorrection userActivityLabels:userActivitiesStrings mood:startOfActivity.mood startTimestamp:startOfActivity.timestamp endTimestamp:startOfActivity.timestamp minuteActivities:minuteActivities];
    activityFeedback.activityEvent = activityEvent;
    activityFeedback.startTime = [NSDate dateWithTimeIntervalSince1970:[activityEvent.startTimestamp doubleValue]];
    activityFeedback.endTime = [NSDate dateWithTimeIntervalSince1970:[activityEvent.endTimestamp doubleValue]];
    newView.modalPresentationStyle = UIModalPresentationFormSheet;
    [self.navigationController pushViewController:activityFeedback animated:YES];
}

-(void) zoom:(UIButton*)button
{
    self.isDailyView=!self.isDailyView;
    [self.collectionViewCalendarLayout initialize:self.isDailyView];
    if (self.isDailyView) {
        [self.zoomButton setBackgroundImage:[UIImage imageNamed:@"Zoom_in.png"] forState:UIControlStateNormal];
    } else {
        [self.zoomButton setBackgroundImage:[UIImage imageNamed:@"Zoom_out.png"] forState:UIControlStateNormal];
    }
    [self viewDidLoad];
    [self viewWillAppear:YES];
    [self viewDidAppear:YES];
}

-(void) mergeActivities:(UIButton*)button
{
    self.displayActivityEvents=!self.displayActivityEvents;
    [self.collectionViewCalendarLayout initialize:self.isDailyView];
    [self viewWillAppear:YES];
    [self viewDidAppear:YES];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self recalculateEventsFromPredictionList];
    [self.collectionViewCalendarLayout scrollCollectionViewToClosetSectionToCurrentTimeAnimated:YES];
}

- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    // On iPhone, adjust width of sections on interface rotation. No necessary in horizontal layout (iPad)
    if (self.collectionViewCalendarLayout.sectionLayoutType == MSSectionLayoutTypeVerticalTile) {
        [self.collectionViewCalendarLayout invalidateLayoutCache];
        // These are the only widths that are defined by default. There are more that factor into the overall width.
        self.collectionViewCalendarLayout.sectionWidth = (CGRectGetWidth(self.collectionView.frame) - self.collectionViewCalendarLayout.timeRowHeaderWidth - self.collectionViewCalendarLayout.contentMargin.right);
        [self.collectionView reloadData];
    }
}

- (BOOL)prefersStatusBarHidden
{
    return YES;
}

#pragma mark - MSCalendarViewController

#pragma mark - NSFetchedResultsControllerDelegate

- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller
{
    [self.collectionViewCalendarLayout invalidateLayoutCache];
    [self.collectionView reloadData];
}

#pragma mark - UICollectionViewDataSource

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
    return self.fetchedResultsController.sections.count;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return [(id <NSFetchedResultsSectionInfo>)self.fetchedResultsController.sections[section] numberOfObjects];
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    ES_ActivityCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:ESActivityCellReuseIdentifier forIndexPath:indexPath];
    cell.isDailyView=self.isDailyView;
    cell.activity = [self.fetchedResultsController objectAtIndexPath:indexPath];
    return cell;
    
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout referenceSizeForHeaderInSection:(NSInteger)section {
    return CGSizeMake(0, 100);
}

- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath
{
    UICollectionReusableView *view;
    if (kind == MSCollectionElementKindDayColumnHeader) {
        MSDayColumnHeader *dayColumnHeader = [collectionView dequeueReusableSupplementaryViewOfKind:kind withReuseIdentifier:MSDayColumnHeaderReuseIdentifier forIndexPath:indexPath];
        NSDate *day = [self.collectionViewCalendarLayout dateForDayColumnHeaderAtIndexPath:indexPath];
        NSDate *currentDay = [self currentTimeComponentsForCollectionView:self.collectionView layout:self.collectionViewCalendarLayout];
        dayColumnHeader.day = day;
        dayColumnHeader.currentDay = [[day beginningOfDay] isEqualToDate:[currentDay beginningOfDay]];
        view = dayColumnHeader;
    } else if (kind == MSCollectionElementKindTimeRowHeader) {
        MSTimeRowHeader *timeRowHeader = [collectionView dequeueReusableSupplementaryViewOfKind:kind withReuseIdentifier:MSTimeRowHeaderReuseIdentifier forIndexPath:indexPath];
        timeRowHeader.time = [self.collectionViewCalendarLayout dateForTimeRowHeaderAtIndexPath:indexPath];
        view = timeRowHeader;
    }
    return view;
}

#pragma mark - MSCollectionViewCalendarLayout

- (NSDate *)collectionView:(UICollectionView *)collectionView layout:(MSCollectionViewCalendarLayout *)collectionViewCalendarLayout dayForSection:(NSInteger)section
{
    id <NSFetchedResultsSectionInfo> sectionInfo = [self.fetchedResultsController.sections objectAtIndex:section];
    ES_Activity *activity = [sectionInfo.objects firstObject];
    return activity.day;
}

- (NSDate *)collectionView:(UICollectionView *)collectionView layout:(MSCollectionViewCalendarLayout *)collectionViewCalendarLayout startTimeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    ES_Activity *activity= [self.fetchedResultsController objectAtIndexPath:indexPath];;
    if (self.displayActivityEvents) {
        ES_ActivityEvent *event;
        for (id activityObject in [self.activityEvents reverseObjectEnumerator])
        {
            if([activity.startTime isEqualToDate: ((ES_ActivityEvent *) activityObject).startTime]){
                event= (ES_ActivityEvent *) activityObject;
                return event.startTime;
                break;
            }
        }
        return nil;
    } else {
        return activity.startTime;
    }
}

- (NSDate *)collectionView:(UICollectionView *)collectionView layout:(MSCollectionViewCalendarLayout *)collectionViewCalendarLayout endTimeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    ES_Activity *activity= [self.fetchedResultsController objectAtIndexPath:indexPath];;
    if (self.displayActivityEvents) {
        for (id activityObject in [self.activityEvents reverseObjectEnumerator])
        {
            if([activity.startTime isEqualToDate: ((ES_ActivityEvent *) activityObject).startTime]){
                return [NSDate dateWithTimeIntervalSince1970:[((ES_ActivityEvent *) activityObject).endTimestamp doubleValue] +60];
            }
        }
    }
    return [activity.startTime dateByAddingTimeInterval:60];// every activity is 60 sec
}

- (NSDate *)currentTimeComponentsForCollectionView:(UICollectionView *)collectionView layout:(MSCollectionViewCalendarLayout *)collectionViewCalendarLayout
{
    return [NSDate date];
}

- (void)recalculateEventsFromPredictionList
{
    [self.activityEvents removeAllObjects];
    NSArray *activities = [self.fetchedResultsController fetchedObjects];
    // Read the prediction list of the user and group together consecutive timepoints with similar activities to unified activity events:
    ES_Activity *startOfActivity = nil;
    ES_Activity *endOfActivity = nil;
    ES_ActivityEvent *currentEvent = nil;
    NSMutableArray *minuteActivities = nil;
    for (id activityObject in [activities objectEnumerator])
    {
        ES_Activity *currentActivity = (ES_Activity *)activityObject;
        if (![[ES_HistoryTableViewController class] isActivity:currentActivity similarToActivity:startOfActivity])
        {
            // Then we've reached a new activity.
            if (startOfActivity)
            {
                NSMutableSet *userActivitiesStrings = [NSMutableSet setWithArray:[ES_UserActivityLabels createStringArrayFromUserActivityLabelsAraay:[startOfActivity.userActivityLabels allObjects]]];
                // Create an event from the start and end of the previous activity:
                currentEvent = [[ES_ActivityEvent alloc] initWithIsVerified:startOfActivity.isPredictionVerified serverPrediction:startOfActivity.serverPrediction userCorrection:startOfActivity.userCorrection userActivityLabels:userActivitiesStrings mood:startOfActivity.mood startTimestamp:startOfActivity.timestamp endTimestamp:endOfActivity.timestamp minuteActivities:minuteActivities];
                currentEvent.startTime=startOfActivity.startTime;
                [self.activityEvents addObject:currentEvent];
            }
            
            //update the new "start" for the current activity:
            minuteActivities = [[NSMutableArray alloc] initWithCapacity:1];
            startOfActivity = currentActivity;
        }
        // Add teh minute activity object to the list of minutes of the current event:
        [minuteActivities addObject:currentActivity];
        endOfActivity = currentActivity;
    }
    if (endOfActivity)
    {
        // Create the last event from the start and end of activity:
        NSMutableSet *userActivitiesStrings = [NSMutableSet setWithArray:[ES_UserActivityLabels createStringArrayFromUserActivityLabelsAraay:[startOfActivity.userActivityLabels allObjects]]];
        ES_ActivityEvent *event = [[ES_ActivityEvent alloc] initWithIsVerified:startOfActivity.isPredictionVerified serverPrediction:startOfActivity.serverPrediction userCorrection:startOfActivity.userCorrection userActivityLabels:userActivitiesStrings mood:startOfActivity.mood startTimestamp:startOfActivity.timestamp endTimestamp:endOfActivity.timestamp minuteActivities:minuteActivities];
        event.startTime=startOfActivity.startTime;
        [self.activityEvents addObject:event];
    }
    
}

@end
