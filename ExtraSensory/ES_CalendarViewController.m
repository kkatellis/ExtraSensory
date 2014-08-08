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

NSString * const ESActivityCellReuseIdentifier = @"ESActivityCellReuseIdentifier";
NSString * const MSDayColumnHeaderReuseIdentifier = @"MSDayColumnHeaderReuseIdentifier";
NSString * const MSTimeRowHeaderReuseIdentifier = @"MSTimeRowHeaderReuseIdentifier";

@interface ES_CalendarViewController () <MSCollectionViewDelegateCalendarLayout, NSFetchedResultsControllerDelegate>

@property (nonatomic, strong) MSCollectionViewCalendarLayout *collectionViewCalendarLayout;
@property (nonatomic, strong) NSFetchedResultsController *fetchedResultsController;
@property (nonatomic, strong) UIButton *backButton;
@property (nonatomic, strong) UIButton *feedbackButton;
@property (nonatomic, strong) UIButton *zoomButton;
@end

@implementation ES_CalendarViewController
//@synthesize selectedCell=_selectedCell;
- (id)init
{
    self.isDailyView=YES;
    self.collectionViewCalendarLayout = [[MSCollectionViewCalendarLayout alloc] init];
    self.collectionViewCalendarLayout.delegate = self;
    self = [super initWithCollectionViewLayout:self.collectionViewCalendarLayout];
    
    self.backButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    [self.backButton addTarget:self action:@selector(back:) forControlEvents:UIControlEventTouchUpInside];
    [self.backButton setBackgroundImage:[UIImage imageNamed:@"back.png"] forState:UIControlStateNormal];
    self.backButton.frame = CGRectMake(0.0, 10.0, 25.0, 25.0);
    self.	backButton.titleLabel.font = [UIFont boldSystemFontOfSize:12.0];
    [self.view addSubview:self.backButton];
    
    self.feedbackButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    [self.feedbackButton addTarget:self action:@selector(activeFeedback:) forControlEvents:UIControlEventTouchUpInside];
    [self.feedbackButton setBackgroundImage:[UIImage imageNamed:@"edit.png"] forState:UIControlStateNormal];
    self.feedbackButton.frame = CGRectMake(290.0, 10.0, 25.0, 25.0);
    self.feedbackButton.titleLabel.font = [UIFont boldSystemFontOfSize:12.0];
    [self.view addSubview:self.feedbackButton];
    
    self.zoomButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    [self.zoomButton addTarget:self action:@selector(zoom:) forControlEvents:UIControlEventTouchUpInside];
    [self.zoomButton setBackgroundImage:[UIImage imageNamed:@"zoom_in.png"] forState:UIControlStateNormal];
    self.zoomButton.frame = CGRectMake(265.0, 10.0, 25.0, 25.0);
    self.zoomButton.titleLabel.font = [UIFont boldSystemFontOfSize:12.0];
    [self.view addSubview:self.zoomButton];

    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
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
    
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"ES_Activity"];
    fetchRequest.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"startTime" ascending:YES]];

    NSString *storePath = [[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject] stringByAppendingPathComponent:@"ExtraSensory.sqlite"];
    NSManagedObjectModel *managedObjectModel = [NSManagedObjectModel mergedModelFromBundles:nil];
    RKManagedObjectStore *managedObjectStore = [[RKManagedObjectStore alloc] initWithManagedObjectModel:managedObjectModel];
    [managedObjectStore createPersistentStoreCoordinator];
    NSLog(@"Store Path: %@\n",storePath);
    [managedObjectStore addSQLitePersistentStoreAtPath:storePath fromSeedDatabaseAtPath:nil withConfiguration:nil options:nil error:nil];
    [managedObjectStore createManagedObjectContexts];
    managedObjectStore.managedObjectCache = [[RKInMemoryManagedObjectCache alloc] initWithManagedObjectContext:managedObjectStore.persistentStoreManagedObjectContext];
    [RKManagedObjectStore setDefaultStore:managedObjectStore];

    // Divide into sections by the "day" key path
    self.fetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest managedObjectContext:[RKManagedObjectStore defaultStore].mainQueueManagedObjectContext sectionNameKeyPath:@"day" cacheName:nil];
    self.fetchedResultsController.delegate = self;
    [self.fetchedResultsController performFetch:nil];
    
}
-(void)back:(UIButton *)sender
{
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
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
        [self.zoomButton setBackgroundImage:[UIImage imageNamed:@"zoom_in.png"] forState:UIControlStateNormal];
    } else {
        [self.zoomButton setBackgroundImage:[UIImage imageNamed:@"zoom_out.png"] forState:UIControlStateNormal];
    }
    [self viewDidLoad];
    [self viewWillAppear:YES];
    [self.collectionView.collectionViewLayout prepareLayout];
    [self viewDidAppear:YES];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
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
//    if (cell.selected) {
//        self.selectedCell=cell;
//    }

    return cell;
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout referenceSizeForHeaderInSection:(NSInteger)section {
    //    if (section == albumSection) {
    return CGSizeMake(0, 100);
    //    }
    
    return CGSizeZero;
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
    ES_Activity *activity = [self.fetchedResultsController objectAtIndexPath:indexPath];
    return activity.startTime;
}

- (NSDate *)collectionView:(UICollectionView *)collectionView layout:(MSCollectionViewCalendarLayout *)collectionViewCalendarLayout endTimeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    ES_Activity *activity = [self.fetchedResultsController objectAtIndexPath:indexPath];
    return [activity.startTime dateByAddingTimeInterval:(60)];// every activity is 60 sec
}

- (NSDate *)currentTimeComponentsForCollectionView:(UICollectionView *)collectionView layout:(MSCollectionViewCalendarLayout *)collectionViewCalendarLayout
{
    return [NSDate date];
}

@end
