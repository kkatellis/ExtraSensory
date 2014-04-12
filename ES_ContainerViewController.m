//
//  ES_ContainerViewController.m
//  ExtraSensory
//
//  Created by Kat Ellis on 3/15/14.
//  Copyright (c) 2014 Bryan Grounds. All rights reserved.
//

#import "ES_ContainerViewController.h"

#define LIST_SEGUE_ID @"list"
#define PIE_SEGUE_ID @"pie"

@interface ES_ContainerViewController ()

@property (strong, nonatomic) NSString *currentSegueIdentifier;

@end

@implementation ES_ContainerViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    return self;
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:LIST_SEGUE_ID])
    {
        if (self.childViewControllers.count > 0) {
            [self swapFromViewController:[self.childViewControllers objectAtIndex:0] toViewController:segue.destinationViewController];
        }
        else {
            [self addChildViewController:segue.destinationViewController];
            ((UIViewController *)segue.destinationViewController).view.frame = CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height);
            [self.view addSubview:((UIViewController *)segue.destinationViewController).view];
            [segue.destinationViewController didMoveToParentViewController:self];
        }
    }
    else if ([segue.identifier isEqualToString:PIE_SEGUE_ID])
    {
        [self swapFromViewController:[self.childViewControllers objectAtIndex:0] toViewController:segue.destinationViewController];
    }
}

- (void)swapFromViewController:(UIViewController *)fromViewController toViewController:(UIViewController *)toViewController
{
    toViewController.view.frame = CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height);
    
    [fromViewController willMoveToParentViewController:nil];
    [self addChildViewController:toViewController];
    [self transitionFromViewController:fromViewController toViewController:toViewController duration:0.0 options:UIViewAnimationOptionTransitionCrossDissolve animations:nil completion:^(BOOL finished) {
        [fromViewController removeFromParentViewController];
        [toViewController didMoveToParentViewController:self];
    }];
}

- (void)swapViewControllers
{
    if ([self.currentSegueIdentifier  isEqual: LIST_SEGUE_ID])
    {
        self.currentSegueIdentifier = PIE_SEGUE_ID;
    }
    else
    {
        self.currentSegueIdentifier = LIST_SEGUE_ID;
    }
    [self performSegueWithIdentifier:self.currentSegueIdentifier sender:nil];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Custom initialization
    self.currentSegueIdentifier = LIST_SEGUE_ID;
    [self performSegueWithIdentifier:self.currentSegueIdentifier sender:nil];
	// Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end

