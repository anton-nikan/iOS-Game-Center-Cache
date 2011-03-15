//
//  GCCacheSampleViewController.m
//  GCCacheSample
//
//  Created by nikan on 3/15/11.
//  Copyright 2011 Anton Nikolaienko. All rights reserved.
//

#import "GCCacheSampleViewController.h"
#import "GCCache.h"


@implementation GCCacheSampleViewController
@synthesize playerLabel;
@synthesize bestScoreLabel;

- (void)dealloc
{
    [playerLabel release];
    [bestScoreLabel release];
    [super dealloc];
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}


#pragma mark -

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    [[GCCache activeCache] submitScore:[NSNumber numberWithInt:alertView.tag] toLeaderboard:@"SimpleScore"];
    self.bestScoreLabel.text = [NSString stringWithFormat:@"Best Score: %@",
                                [[GCCache activeCache] scoreForLeaderboard:@"SimpleScore"]];

    [alertView release];
}


#pragma mark - View lifecycle

// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.playerLabel.text = [NSString stringWithFormat:@"Player: %@", [GCCache activeCache].profileName];
    self.bestScoreLabel.text = [NSString stringWithFormat:@"Best Score: %@", [[GCCache activeCache] scoreForLeaderboard:@"SimpleScore"]];
}

- (void)viewDidUnload
{
    [self setPlayerLabel:nil];
    [self setBestScoreLabel:nil];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (IBAction)playAction
{
    int score = 32542 + rand() % 364534;    
    UIAlertView *resultAlert = [[UIAlertView alloc] initWithTitle:@"Game Finished"
                                                          message:[NSString stringWithFormat:@"You've played the game and gained %d score", score]
                                                         delegate:self
                                                cancelButtonTitle:@"OK"
                                                otherButtonTitles:nil];
    resultAlert.tag = score;
    [resultAlert show];
}

- (IBAction)changePlayerAction {
}

@end