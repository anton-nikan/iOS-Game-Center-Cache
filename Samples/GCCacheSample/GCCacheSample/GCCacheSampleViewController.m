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
@synthesize changePlayerButton;
@synthesize playerLabel;
@synthesize bestScoreLabel;

- (void)dealloc
{
    [playerLabel release];
    [bestScoreLabel release];
    [changePlayerButton release];
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
    if (alertView.tag == 0) {
        self.bestScoreLabel.text = [NSString stringWithFormat:@"Best Score: %@",
                                    [[GCCache activeCache] scoreForLeaderboard:@"SimpleScore"]];

        if ([[GCCache activeCache] isDefault]) {
            // Suggest to name the profile
            UIAlertView *profileAlert = [[UIAlertView alloc] initWithTitle:@"Enter your name:"
                                                                   message:@"Placeholder text"
                                                                  delegate:self
                                                         cancelButtonTitle:@"Cancel"
                                                         otherButtonTitles:@"Save", nil];
            UITextField *theTextField = [[UITextField alloc] initWithFrame:CGRectMake(12.0, 47.0, 260.0, 25.0)]; 
            [theTextField setBackgroundColor:[UIColor whiteColor]]; 
            [profileAlert addSubview:theTextField];
            profileAlert.tag = 1;
            
            [profileAlert show];
        }
    } else if (alertView.tag == 1) {
        UITextField *textField = nil;
        for (UIView *view in alertView.subviews) {
            if ([view isKindOfClass:[UITextField class]]) {
                textField = (UITextField*)view;
                break;
            }
        }

        if (textField && textField.text.length && alertView.cancelButtonIndex != buttonIndex) {
            NSString *newProfileName = textField.text;
            if (![[GCCache activeCache] renameProfile:newProfileName]) {
                UIAlertView *profileAlert = [[UIAlertView alloc] initWithTitle:@"Name is not available. Please enter different name:"
                                                                       message:@"Placeholder text"
                                                                      delegate:self
                                                             cancelButtonTitle:@"Cancel"
                                                             otherButtonTitles:@"Save", nil];
                UITextField *theTextField = [[UITextField alloc] initWithFrame:CGRectMake(12.0, 67.0, 260.0, 25.0)]; 
                [theTextField setBackgroundColor:[UIColor whiteColor]]; 
                [profileAlert addSubview:theTextField];
                profileAlert.tag = 1;

                [profileAlert show];
            } else {
                [self updateProfileInfo];
            }
        }
    }

    [alertView release];
}

- (void)playerListViewControllerDidCancel:(PlayerListViewController *)controller
{
    [self updateProfileInfo];
    [self dismissModalViewControllerAnimated:YES];
}

- (void)playerListViewController:(PlayerListViewController *)controller didSelectProfile:(NSDictionary *)profile
{
    if (![[GCCache activeCache] isEqualToProfile:profile]) {
        GCCache *profileCache = [GCCache cacheForProfile:profile];
        [GCCache activateCache:profileCache];
    }

    [self updateProfileInfo];
    [self dismissModalViewControllerAnimated:YES];
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
    [self setChangePlayerButton:nil];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (void)leaderboardViewControllerDidFinish:(GKLeaderboardViewController *)viewController
{
    [self dismissModalViewControllerAnimated:YES];
}

- (void)achievementViewControllerDidFinish:(GKAchievementViewController *)viewController
{
    [self dismissModalViewControllerAnimated:YES];
}

- (IBAction)playAction
{
    int score = 32542 + rand() % 364534;
    int achievementIdx = rand() % 5;
    double achievementProgress = 30.0 + 0.3 * 0.1 * (rand() % 1000);
    NSString *achievement = [NSString stringWithFormat:@"Ach-%02d", achievementIdx + 1];
    
    NSString *msg = nil;
    if ([[GCCache activeCache] isUnlockedAchievement:achievement]) {
        msg = [NSString stringWithFormat:@"You've played the game and gained %d score",
               score];
    } else {
        double currProgress = [[GCCache activeCache] progressOfAchievement:achievement];
        if (currProgress + achievementProgress < 100.0) {
            msg = [NSString stringWithFormat:@"You've played the game, gained %d score and progressed to %.0f%% in '%@' achievement",
                   score, achievementProgress + currProgress, achievement];
        } else {
            msg = [NSString stringWithFormat:@"You've played the game, gained %d score and unlocked '%@' achievement",
                   score, achievement];
        }
        
        [[GCCache activeCache] submitProgress:currProgress + achievementProgress
                                toAchievement:achievement];
    }
    
    UIAlertView *resultAlert = [[UIAlertView alloc] initWithTitle:@"Game Finished"
                                                          message:msg
                                                         delegate:self
                                                cancelButtonTitle:@"Ok"
                                                otherButtonTitles:nil];
    [resultAlert show];

    [[GCCache activeCache] submitScore:[NSNumber numberWithInt:score] toLeaderboard:@"SimpleScore"];
}

- (IBAction)changePlayerAction
{
    PlayerListViewController *playerViewController = [[PlayerListViewController alloc] init];
    playerViewController.delegate = self;
    [self presentModalViewController:playerViewController animated:YES];
    [playerViewController release];
}

- (IBAction)resetAction
{
    [[GCCache activeCache] reset];
    [self updateProfileInfo];
}

- (IBAction)scoresAction {
    if (![[GCCache activeCache] isLocal]) {
        GKLeaderboardViewController *leaderboardController = [[GKLeaderboardViewController alloc] init];
        if (leaderboardController != nil)
        {
            leaderboardController.leaderboardDelegate = self;
            [self presentModalViewController: leaderboardController animated: YES];
            [leaderboardController release];
        }
    }
}

- (IBAction)achievementsAction {
    if (![[GCCache activeCache] isLocal]) {
        GKAchievementViewController *achievements = [[GKAchievementViewController alloc] init];
        if (achievements != nil)
        {
            achievements.achievementDelegate = self;
            [self presentModalViewController: achievements animated: YES];
            [achievements release];
        }
    }
}

- (void)updateProfileInfo
{
    self.playerLabel.text = [NSString stringWithFormat:@"Player: %@", [GCCache activeCache].profileName];
    self.bestScoreLabel.text = [NSString stringWithFormat:@"Best Score: %@", [[GCCache activeCache] scoreForLeaderboard:@"SimpleScore"]];
}

@end
