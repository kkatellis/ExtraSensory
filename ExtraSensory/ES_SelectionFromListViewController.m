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

@end

@implementation ES_SelectionFromListViewController


- (void) setParametersCategory:(NSString *)category multiSelection:(BOOL)multiSelection useIndex:(BOOL)useIndex choices:(NSArray *)choices appliedLabels:(NSMutableSet *)appliedLabels frequentChoices:(NSArray *)frequentChoices
{
    [self setCategory:category];
    [self setMultiSelection:multiSelection];
    [self setUseIndex:useIndex];
    [self setChoices:choices];
    [self setAppliedLabels:appliedLabels];
    [self setFrequentChoices:frequentChoices];
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
    
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

- (void) recalculateTable
{
    // Sort the choice lables alphabetically:
    self.choices = [self.choices sortedArrayUsingSelector:@selector(compare:)];
    
    // Start dividing to sections:
    if (self.useIndex)
    {
        self.sections = [NSMutableArray arrayWithCapacity:10];
        self.sectionNames = [NSMutableArray arrayWithCapacity:10];
        self.sectionHeaders = [NSMutableArray arrayWithCapacity:10];
        
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
                    if ((!self.frequentChoices) || ([self.sections count] > 2))
                    {
                        // Then we don't want this added section to have a header:
                        [self.sectionHeaders addObject:@""];
                    }
                    else
                    {
                        // Then there was a frequent section and now we added the first alphabetic section. Lets give it a headline:
                        [self.sectionHeaders addObject:@"All labels"];
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
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return self.sections.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    return [self.sections[section] count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Configure the cell...
    UITableViewCell *cell = [[UITableViewCell alloc] init];
    cell.textLabel.text = [self.sections[indexPath.section] objectAtIndex:indexPath.row];
    [cell setSelectionStyle:UITableViewCellSelectionStyleNone];
    if ([self doesAppliedLabelsContainLabel:cell.textLabel.text])
    {
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
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
        [self removeFromAppliedLabelsCellToRemove:cell];
    }
    else
    {
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
        if(!self.appliedLabels)
        {//this is for labling samples which is not labled by server (probably because the app is stoped)
            self.appliedLabels=[NSMutableSet setWithObject:(cell.textLabel.text)];
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
    
    [self.tableView reloadData];
}

-(void)tableView:(UITableView *)tableView didDeselectRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    [self removeFromAppliedLabelsCellToRemove:cell];
    [self.tableView reloadData];
}


/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    } else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
{
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
