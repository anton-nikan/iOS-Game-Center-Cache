//
//  PlayerListViewController.h
//  GCCacheSample
//
//  Created by nikan on 3/19/11.
//  Copyright 2011 Anton Nikolaienko. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol PlayerListViewControllerDelegate;

@interface PlayerListViewController : UITableViewController {
    NSMutableArray *localPlayers;
    NSMutableArray *onlinePlayers;
    BOOL authenticating;
}

@property (nonatomic, assign) id<PlayerListViewControllerDelegate> delegate;

@end


@protocol PlayerListViewControllerDelegate <NSObject>
- (void)playerListViewController:(PlayerListViewController*)controller didSelectProfile:(NSDictionary*)profile;
- (void)playerListViewControllerDidCancel:(PlayerListViewController*)controller;
@end
