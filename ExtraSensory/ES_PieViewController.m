//
//  ES_PieViewController.m
//  ExtraSensory
//
//  Created by Rafael Aguayo on 3/8/14.
//  Copyright (c) 2014 Bryan Grounds. All rights reserved.
//

#import "ES_PieViewController.h"

@interface ES_PieViewController ()

@property (weak, nonatomic) IBOutlet UILabel *border;
@property (weak, nonatomic) IBOutlet UILabel *purple;
@property (weak, nonatomic) IBOutlet UILabel *blue;
@property (weak, nonatomic) IBOutlet UILabel *green;
@property (weak, nonatomic) IBOutlet UILabel *yellow;
@property (weak, nonatomic) IBOutlet UILabel *orange;
@property (weak, nonatomic) IBOutlet UILabel *red;
@property (weak, nonatomic) IBOutlet UILabel *white;

@end



@implementation ES_PieViewController

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
    self.border.layer.borderColor = [UIColor blackColor].CGColor;
    self.border.layer.borderWidth = 3.0;
    self.border.layer.cornerRadius = 5;
    self.purple.layer.cornerRadius = 10;
    self.blue.layer.cornerRadius = 10;
    self.green.layer.cornerRadius = 10;
    self.yellow.layer.cornerRadius = 10;
    self.orange.layer.cornerRadius = 10;
    self.red.layer.cornerRadius = 10;
    self.white.layer.cornerRadius = 10;
    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
