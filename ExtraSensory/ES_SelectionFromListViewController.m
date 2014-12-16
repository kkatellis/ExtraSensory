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


- (void) setParametersCategory:(NSString *)category multiSelection:(BOOL)multiSelection useIndex:(BOOL)useIndex choices:(NSArray *)choices appliedLabels:(NSMutableSet *)appliedLabels frequentChoices:(NSArray *)frequentChoices labelsPerSubject:(NSDictionary *)labelsPerSubject
{
    [self setCategory:category];
    [self setMultiSelection:multiSelection];
    [self setUseIndex:useIndex];
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
            [self.sections addObject:selectedLabels];
            [self.sectionNames addObject:@"Selected"];
            [self.sectionHeaders addObject:@"Selected"];
        }
        
        if (self.labelsPerSubject)
        {
            // Then add a section for each subject:
            for (NSString *subject in [[self.labelsPerSubject allKeys] sortedArrayUsingSelector:@selector(compare:)])
            {
                NSArray *labelsOfThisSubject = [self.labelsPerSubject valueForKey:subject];
                [self.sections addObject:labelsOfThisSubject];
                [self.sectionNames addObject:subject];
                [self.sectionHeaders addObject:subject];
            }
        }
        
        if (self.frequentChoices)
        {
            // Make the first section be dedicated to the frequently used labels:
            [self.sections addObject:self.frequentChoices];
            [self.sectionNames addObject:@"frequent"];
            [self.sectionHeaders addObject:@"Frequently used"];
        }
        
        NSString *latestLetter = @"";
        NSMutableArray *latestSection = nil;
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
                    if ([firstLetter isEqualToString:@"A"])
                    {
                        [self.sectionHeaders addObject:@"All labels"];
                    }
                    else
                    {
                        [self.sectionHeaders addObject:@""];
                    }
//                    if ((!self.frequentChoices) || ([self.sections count] > 2))
//                    {
//                        // Then we don't want this added section to have a header:
//                        [self.sectionHeaders addObject:@""];
//                    }
//                    else
//                    {
//                        // Then there was a frequent section and now we added the first alphabetic section. Lets give it a headline:
//                        [self.sectionHeaders addObject:@"All labels"];
//                    }
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
    else
    {
        self.sectionNames = nil;
        self.sections = [NSMutableArray arrayWithObject:self.choices];
    }
    
    [self.tableView reloadData];
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
    
    if (tableView == self.searchDisplayController.searchResultsTableView)
    {
        cell.textLabel.text = [self.searchResults objectAtIndex:indexPath.row];
        //checkedArray =
        NSLog(@"search result match: %@", cell.textLabel.text);
    }
    else
    {
        cell.textLabel.text = [self.sections[indexPath.section] objectAtIndex:indexPath.row];
    }
    
    if ([self doesAppliedLabelsContainLabel:cell.textLabel.text])
    {
        NSLog(@"applied label contains label");
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
        [_checkedArray addObject:indexPath];
        [tableView selectRowAtIndexPath:indexPath animated:NO scrollPosition: UITableViewScrollPositionNone];
    }
    NSLog(@"cell returned is %@", cell.textLabel.text);
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
        NSLog(@"Selection made");
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
        NSLog(@"==== selected row from search results. closign search results...");
        [self.searchDisplayController setActive:NO animated:YES];
    }
    
    NSLog(@"reload data");
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
