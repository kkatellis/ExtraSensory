//
//  ES_SelectionFromListViewController.h
//  ExtraSensory
//
//  Created by yonatan vaizman on 9/8/14.
//  Copyright (c) 2014 Bryan Grounds. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ES_SelectionFromListViewController : UITableViewController <UISearchDisplayDelegate>

@property NSString *category; // Name of the category for which the selection list is presented
@property (nonatomic) BOOL multiSelection; // allow multiple selections
@property (nonatomic) BOOL useIndex; // Use a helping alphabet index
@property NSArray *choices; // the possible label choices
@property NSMutableSet *appliedLabels; // the labels that the user has chosen
@property NSArray *frequentChoices; // a supbset of the choices that will appear in a separate section as "frequently used labels". only relevant when using index

- (void) setParametersCategory:(NSString *)category multiSelection:(BOOL)multiSelection useIndex:(BOOL)useIndex choices:(NSArray *)choices appliedLabels:(NSMutableSet *)appliedLabels frequentChoices:(NSArray *)frequentChoices;

@end
