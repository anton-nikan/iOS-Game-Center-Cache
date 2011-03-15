//
//  GCCacheSampleViewController.h
//  GCCacheSample
//
//  Created by nikan on 3/15/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface GCCacheSampleViewController : UIViewController {
    
    UILabel *playerLabel;
    UILabel *bestScoreLabel;
}

@property (nonatomic, retain) IBOutlet UILabel *playerLabel;
@property (nonatomic, retain) IBOutlet UILabel *bestScoreLabel;

- (IBAction)playAction;
- (IBAction)changePlayerAction;

@end
