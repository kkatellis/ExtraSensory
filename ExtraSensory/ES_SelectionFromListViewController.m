//
//  ES_SelectionFromListViewController.m
//  ExtraSensory
//
//  Created by yonatan vaizman on 9/8/14.
//  Copyright (c) 2014 Bryan Grounds. All rights reserved.
//

#import "ES_SelectionFromListViewController.h"

@interface ES_SelectionFromListViewController ()

@property NSMutableArray *sections;
@property NSMutableArray *sectionNames;
@property NSMutableArray *sectionHeaders;
@property NSArray *searchResults;
@property NSMutableArray *checkedArray;
@property (strong, nonatomic)NSArray *array;
@property (strong, nonatomic) IBOutlet UISearchBar *searchBar;
@end

@implementation ES_SelectionFromListViewController


- (void) setParametersCategory:(NSString *)category multiSelection:(BOOL)multiSelection useIndex:(BOOL)useIndex useAlphabeticIndex:(BOOL)useAlphabeticIndex choices:(NSArray *)choices appliedLabels:(NSMutableSet *)appliedLabels frequentChoices:(NSArray *)frequentChoices labelsPerSubject:(NSDictionary *)labelsPerSubject
{
    [self setCategory:category];
    [self setMultiSelection:multiSelection];
    [self setUseIndex:useIndex];
    [self setUseAlphabeticIndex:useAlphabeticIndex];
    [self setChoices:choices];
    [self setAppliedLabels:appliedLabels];
    [self setFrequentChoices:frequentChoices];
    [self setLabelsPerSubject:labelsPerSubject];
}

- (id) initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.searchResults = [[NSArray alloc] init];

   /* self.searchBar.hidden = YES;
    self.tableView.frame = CGRectMake(self.tableView.frame.origin.x, self.tableView.frame.origin.y - self.searchBar.frame.size.height, self.tableView.frame.size.width, self.tableView.frame.size.height + self.searchBar.frame.size.height);*/
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

- (void) addSectionWithArrayOfItemStrings:(NSArray *)sectionItems name:(NSString *)name andHeader:(NSString *)header
{
    [self.sections addObject:sectionItems];
    [self.sectionNames addObject:name];
    [self.sectionHeaders addObject:header];
}

- (void) addDummySection
{
    [self addSectionWithArrayOfItemStrings:[NSArray arrayWithObjects:nil] name:@" " andHeader:@""];
}

- (void) recalculateTable
{
    
    // Start dividing to sections:
    if (self.useIndex)
    {
        // Sort the choice lables alphabetically:
        self.choices = [self.choices sortedArrayUsingSelector:@selector(compare:)];

        self.sections = [NSMutableArray arrayWithCapacity:10];
        self.sectionNames = [NSMutableArray arrayWithCapacity:10];
        self.sectionHeaders = [NSMutableArray arrayWithCapacity:10];
        
        if (self.appliedLabels && [self.appliedLabels count] > 0)
        {
            NSArray *selectedLabels = [[self.appliedLabels allObjects] sortedArrayUsingSelector:@selector(compare:)];
            [self addSectionWithArrayOfItemStrings:selectedLabels name:@"Selected" andHeader:@"Selected"];
            [self addDummySection];
        }
        
        if (self.labelsPerSubject)
        {
            // Then add a section for each subject:
            for (NSString *subject in [[self.labelsPerSubject allKeys] sortedArrayUsingSelector:@selector(compare:)])
            {
                NSArray *labelsOfThisSubject = [self.labelsPerSubject valueForKey:subject];
                [self addSectionWithArrayOfItemStrings:labelsOfThisSubject name:subject andHeader:subject];
                
                // Add another dummy section to create a space between two index items:
                [self addDummySection];
            }
        }
        
        if (self.frequentChoices)
        {
            // Make the first section be dedicated to the frequently used labels:
            [self addSectionWithArrayOfItemStrings:self.frequentChoices name:@"frequent" andHeader:@"Frequently used"];
            
            // Add another dummy section to create a space between two index items:
            [self addDummySection];
        }
        
        if (self.useAlphabeticIndex)
        {
            // Then add index for each letter:
            [self addAlphabeticIndexing];
        }
        else
        {
            // Then add a single section (with single index) for all labels:
            NSArray *allLabels = [self.choices sortedArrayUsingSelector:@selector(compare:)];
            [self addSectionWithArrayOfItemStrings:allLabels name:@"All labels" andHeader:@"All labels"];
        }
        
    }
    else
    {
        self.sectionNames = nil;
        self.sections = [NSMutableArray arrayWithObject:self.choices];
    }
    
    [self.tableView reloadData];
    if (self.useIndex)
    {
        [self setIndexAppearance];
    }
}

- (void) setIndexAppearance
{
    for (UIView *sview in [self.tableView subviews])
    {
        if ([sview respondsToSelector:@selector(setIndexColor:)])
        {
            NSLog(@"[selectionFromList] === found sub view of type: %@.",[sview class]);
            if ([sview respondsToSelector:@selector(setFont:)])
            {
                //[sview performSelector:@selector(setFont:) withObject:[UIFont systemFontOfSize:17.5]];
            }
            if ([sview respondsToSelector:@selector(setTextAlignment:)])
            {
                NSLog(@"[selectionFromList] Setting index alignment");
                [sview performSelector:@selector(setTextAlignment:) withObject:NSTextAlignmentLeft];
            }
            else
            {
                NSLog(@"[selectionFromList] Sub view (index) doesnt respond to function setTextAlignment");
            }
            
        }
    }
}

- (void) addAlphabeticIndexing
{
    NSString *latestLetter = @"";
    NSMutableArray *latestSection = nil;
    BOOL startOfAlphabet = YES;
    for (NSString *label in self.choices)
    {
        NSString *firstLetter = [label substringToIndex:1];
        if (![firstLetter isEqualToString:latestLetter])
        {
            // Then we have a new letter.
            // Should we close the previous section:
            if (latestSection)
            {
                [self.sections addObject:latestSection];
                [self.sectionNames addObject:latestLetter];
                if (startOfAlphabet)
                {
                    [self.sectionHeaders addObject:@"All labels"];
                    startOfAlphabet = NO;
                }
                else
                {
                    [self.sectionHeaders addObject:@""];
                }
            }
            // Start the new letter section:
            latestLetter = firstLetter;
            latestSection = [NSMutableArray array];
        }
        // Add this new label to the latest section:
        [latestSection addObject:label];
    }
    
    // Add the last section:
    [self.sections addObject:latestSection];
    [self.sectionNames addObject:latestLetter];
    [self.sectionHeaders addObject:@""];
}

- (void) viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    //hide search bar if main activity page
    if(_useIndex == FALSE){
        self.tableView.contentOffset = CGPointMake(0, 44);
    }
    
    [self recalculateTable];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void) setMultiSelection:(BOOL)multiSelection
{
    _multiSelection = multiSelection;
    [self.tableView setAllowsMultipleSelection:multiSelection];
    [self.searchDisplayController.searchResultsTableView setAllowsMultipleSelection:multiSelection];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    //return only one section if search matches
    if(tableView == self.searchDisplayController.searchResultsTableView)
    {
        return 1;
    }
    else
    {
        return self.sections.count;
    }
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    if (tableView == self.searchDisplayController.searchResultsTableView)
    {
        return [self.searchResults count];
    }
    else
    {
        return [self.sections[section] count];
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Configure the cell...
    UITableViewCell *cell = [[UITableViewCell alloc] init];
    //cell.textLabel.text = [self.sections[indexPath.section] objectAtIndex:indexPath.row];
    [cell setSelectionStyle:UITableViewCellSelectionStyleNone];
    
    cell.textLabel.lineBreakMode = NSLineBreakByWordWrapping;
    cell.textLabel.numberOfLines = 0;
    
    if (tableView == self.searchDisplayController.searchResultsTableView)
    {
        cell.textLabel.text = [self.searchResults objectAtIndex:indexPath.row];
    }
    else
    {
        cell.textLabel.text = [self.sections[indexPath.section] objectAtIndex:indexPath.row];
    }
    
    if ([self doesAppliedLabelsContainLabel:cell.textLabel.text])
    {
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
        [_checkedArray addObject:indexPath];
        [tableView selectRowAtIndexPath:indexPath animated:NO scrollPosition: UITableViewScrollPositionNone];
    }

    return cell;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    NSString *title = self.sectionHeaders[section];
    if ([title length] <= 0)
    {
        return nil;
    }
    return title;
}

- (NSArray *)sectionIndexTitlesForTableView:(UITableView *)tableView
{
    return self.sectionNames;
}

- (NSInteger) tableView:(UITableView *)tableView sectionForSectionIndexTitle:(NSString *)title atIndex:(NSInteger)index
{
    return index;
}

- (BOOL) doesAppliedLabelsContainLabel:(NSString *)label
{
    for (NSString *applied in [self.appliedLabels allObjects])
    {
        if ([applied isEqualToString:label])
        {
            return YES;
        }
    }
    return NO;
}

- (void) removeFromAppliedLabelsLabel:(NSString *)label
{
    NSMutableArray *applied = [NSMutableArray arrayWithArray:[self.appliedLabels allObjects]];
    for (int ii = 0; ii < [self.appliedLabels count]; ii ++)
    {
        if ([label isEqualToString:applied[ii]])
        {
            [applied removeObjectAtIndex:ii];
            self.appliedLabels = [NSMutableSet setWithArray:applied];
            return;
        }
    }
}

- (void)removeFromAppliedLabelsCellToRemove:(UITableViewCell *)cell
{
    if (cell.textLabel.text)
    {
        [self removeFromAppliedLabelsLabel:cell.textLabel.text];
    }
    cell.accessoryType = UITableViewCellAccessoryNone;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath   *)indexPath
{
    
    UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];

    if ([self doesAppliedLabelsContainLabel:cell.textLabel.text])
    {
        NSLog(@"Removing");
        //[tableView deselectRowAtIndexPath:indexPath animated:YES];
        [self removeFromAppliedLabelsCellToRemove:cell];
        //remove from checked array
        [_checkedArray removeObject:indexPath];
    }
    else
    {
        if(!self.appliedLabels)
        {//this is for labling samples which is not labled by server (probably because the app is stoped)
            self.appliedLabels=[NSMutableSet setWithObject:(cell.textLabel.text)];
            [_checkedArray addObject:indexPath];
        }
        else
        {
            if (self.multiSelection)
            {
                [self.appliedLabels addObject:cell.textLabel.text];
            }
            else
            {
                // Make sure there is only a single label applied:
                self.appliedLabels = [NSMutableSet setWithObject:cell.textLabel.text];
            }
        }
    }
    
    if (tableView == self.searchDisplayController.searchResultsTableView)
    {
        [self.searchDisplayController setActive:NO animated:YES];
    }
    
    [self.tableView reloadData];
}

-(void)tableView:(UITableView *)tableView didDeselectRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    [self removeFromAppliedLabelsCellToRemove:cell];
    
    if (tableView == self.searchDisplayController.searchResultsTableView)
    {
        [self.searchDisplayController setActive:NO animated:YES];
    }
    [self.tableView reloadData];
}

#pragma Search Methods
-(void)filterContentForSearchText:(NSString *)searchText scope:(NSString*) scope
{
    NSPredicate *resultPredicate = [NSPredicate predicateWithFormat:@"SELF contains[c] %@", searchText];
    self.searchResults = [self.choices filteredArrayUsingPredicate:resultPredicate];
    //self.searchResults = [self.array filteredArrayUsingPredicate:resultPredicate];
}

-(BOOL)searchDisplayController:(UISearchDisplayController *)controller shouldReloadTableForSearchString:(NSString *)searchString
{
    [self filterContentForSearchText:searchString
            scope:[[self.searchDisplayController.searchBar scopeButtonTitles]
                objectAtIndex:[self.searchDisplayController.searchBar
                selectedScopeButtonIndex]]];
    
    return YES;
}

@end
