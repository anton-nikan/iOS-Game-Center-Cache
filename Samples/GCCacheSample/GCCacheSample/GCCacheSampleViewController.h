//
//  GCCacheSampleViewController.h
//  GCCacheSample
//
//  Created by nikan on 3/15/11.
//  Copyright 2011 Anton Nikolaienko. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <GameKit/GameKit.h>
#import "PlayerListViewController.h"


@interface GCCacheSampleViewController : UIViewController
    <UIAlertViewDelegate, GKLeaderboardViewControllerDelegate, GKAchievementViewControllerDelegate,
    PlayerListViewControllerDelegate>
{
    UILabel *playerLabel;
    UILabel *bestScoreLabel;
    UIButton *changePlayerButton;
}

@property (nonatomic, retain) IBOutlet UIButton *changePlayerButton;
@property (nonatomic, retain) IBOutlet UILabel *playerLabel;
@property (nonatomic, retain) IBOutlet UILabel *bestScoreLabel;

- (IBAction)playAction;
- (IBAction)changePlayerAction;
- (IBAction)resetAction;
- (IBAction)scoresAction;
- (IBAction)achievementsAction;

- (void)updateProfileInfo;

@end
