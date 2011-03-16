//
//  GCCacheSampleViewController.h
//  GCCacheSample
//
//  Created by nikan on 3/15/11.
//  Copyright 2011 Anton Nikolaienko. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <GameKit/GameKit.h>

@interface GCCacheSampleViewController : UIViewController <UIAlertViewDelegate, GKLeaderboardViewControllerDelegate> {
    
    UILabel *playerLabel;
    UILabel *bestScoreLabel;
}

@property (nonatomic, retain) IBOutlet UILabel *playerLabel;
@property (nonatomic, retain) IBOutlet UILabel *bestScoreLabel;

- (IBAction)playAction;
- (IBAction)changePlayerAction;
- (IBAction)resetAction;
- (IBAction)scoresAction;

- (void)updateProfileInfo;

@end
