//
//  LeaderboardViewController.h
//  GCCacheSample
//
//  Created by nikan on 3/19/11.
//  Copyright 2011 Anton Nikolaienko. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface LeaderboardViewController : UITableViewController {
    NSMutableArray *localPlayers;
    NSMutableArray *onlinePlayers;
}

@end
