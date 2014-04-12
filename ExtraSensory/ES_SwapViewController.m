//
//  ES_SwapViewController.m
//  ExtraSensory
//
//  Created by Kat Ellis on 3/15/14.
//  Copyright (c) 2014 Bryan Grounds. All rights reserved.
//

#import "ES_SwapViewController.h"
#import "ES_ContainerViewController.h"

@interface ES_SwapViewController ()
@property (nonatomic, weak) ES_ContainerViewController *containerViewController;
@property (strong, nonatomic) IBOutlet UISegmentedControl *segmentedControl;
@end

@implementation ES_SwapViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"embedContainer"]) {
        self.containerViewController = segue.destinationViewController;
    }
}
- (IBAction)swap:(UISegmentedControl *)sender {
    [self.containerViewController swapViewControllers];
}

@end
