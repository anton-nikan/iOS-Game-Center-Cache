//
//  GCCacheSampleAppDelegate.m
//  GCCacheSample
//
//  Created by nikan on 3/15/11.
//  Copyright 2011 Anton Nikolaienko. All rights reserved.
//

#import "GCCacheSampleAppDelegate.h"
#import "GCCacheSampleViewController.h"
#import "GCCache.h"


@implementation GCCacheSampleAppDelegate

@synthesize window=_window;
@synthesize viewController=_viewController;
@synthesize progressIndicator = _progressIndicator;


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    // Initializing GameCenterCache local data
    NSDictionary *cacheDefaults = [NSDictionary dictionaryWithContentsOfFile:
                                   [[NSBundle mainBundle] pathForResource:@"CacheDefaults" ofType:@"plist"]];
    [GCCache registerLeaderboards:[cacheDefaults objectForKey:@"Leaderboards"]];
    [GCCache registerAchievements:[cacheDefaults objectForKey:@"Achievements"]];
    
    [self.window insertSubview:self.viewController.view belowSubview:self.progressIndicator];
    [self.window makeKeyAndVisible];
    
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Block online"
                                                    message:@"Do you want to test the app offline-only?"
                                                   delegate:self
                                          cancelButtonTitle:@"Yes"
                                          otherButtonTitles:@"No", nil];
    [alert show];
     
    return YES;
}

- (void)gameCenterLaunchCompleted:(NSError*)e
{
    if (e) {
        NSLog(@"Error launching GameCenter: %@", e.localizedDescription);
    }
    
    [self.progressIndicator stopAnimating];
    [self.viewController updateProfileInfo];
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex != alertView.cancelButtonIndex) {
        [self.progressIndicator startAnimating];
        [GCCache launchGameCenterWithCompletionTarget:self action:@selector(gameCenterLaunchCompleted:)];
    } else {
        [self gameCenterLaunchCompleted:nil];
    }
    
    [alertView release];
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    /*
     Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
     Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
     */
    
    [[GCCache activeCache] save];
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    /*
     Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
     If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
     */
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    /*
     Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
     */
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    /*
     Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
     */

    [[GCCache activeCache] synchronize];
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    /*
     Called when the application is about to terminate.
     Save data if appropriate.
     See also applicationDidEnterBackground:.
     */
    
    [GCCache shutdown];
}

- (void)dealloc
{
    [_window release];
    [_viewController release];
    [_progressIndicator release];
    [super dealloc];
}

@end
