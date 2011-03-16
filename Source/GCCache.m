//
//  GCCache.m
//  GameCenterCache
//
//  Created by nikan on 3/12/11.
//  Copyright 2011 Anton Nikolaienko. All rights reserved.
//

#import "GCCache.h"


#if GCCACHE_ENABLE_LOGGING
#define GCLOG(...)
#else
#define GCLOG(...) NSLog(__VA_ARGS__)
#endif


static NSString *kGCProfilesProperty = @"GCProfiles";
static NSString *kGCDefaultProfileName = @"Default";


@interface GCCache (Internal)
- (id)initWithDictionary:(NSDictionary*)profileDict;
- (BOOL)isEqualToProfile:(NSDictionary*)profileDict;

+ (BOOL)isBetterScore:(NSNumber*)lscore thanScore:(NSNumber*)rscore inOrder:(NSString*)order;
+ (NSDictionary*)leaderboardWithName:(NSString*)leaderboardName;
+ (NSDictionary*)achievementWithName:(NSString*)achievementName;

+ (BOOL)isGameCenterAPIAvailable;
+ (void)authenticateLocalPlayerWithCompletionHandler:(void(^)(NSError *error))completionHandler;

- (void)archiveScore:(GKScore*)score;
- (void)archiveAchievement:(GKAchievement*)achievement;
- (void)archiveReset;

@end


@implementation GCCache

static GCCache *activeCache_ = nil;
static NSArray *leaderboards_ = nil;
static NSArray *achievements_ = nil;

+ (NSArray*)cachedProfiles
{
    return [[NSUserDefaults standardUserDefaults] arrayForKey:kGCProfilesProperty];
}

+ (GCCache*)cacheForProfile:(NSDictionary*)profileDict
{
    return [[[GCCache alloc] initWithDictionary:profileDict] autorelease];
}

+ (GCCache*)activeCache
{
    @synchronized(self) {
        if (!activeCache_) {
            // Looking for default profile in cached
            NSArray *profiles = [GCCache cachedProfiles];
            for (NSDictionary *profile in profiles) {
                NSString *name = [profile valueForKey:@"Name"];
                NSNumber *local = [profile valueForKey:@"IsLocal"];
                if ([name isEqualToString:kGCDefaultProfileName] && [local boolValue]) {
                    activeCache_ = [[GCCache cacheForProfile:profile] retain];
                    GCLOG(@"Default profile found in cache.");
                    break;
                }
            }

            // Create new default profile
            if (!activeCache_) {
                activeCache_ = [[GCCache alloc] initWithDictionary:[NSDictionary dictionaryWithObjectsAndKeys:
                                                                    kGCDefaultProfileName, @"Name",
                                                                    [NSNumber numberWithBool:YES], @"IsLocal",
                                                                    nil]];
                [activeCache_ synchronize];
                GCLOG(@"New Default profile created.");
            }
        }
    }
    return activeCache_;
}

+ (void)setActiveCache:(GCCache*)cache
{
    @synchronized(self) {
        if (activeCache_) {
            [activeCache_ release], activeCache_ = nil;
        }
        activeCache_ = [cache retain];
    }
}

+ (void)registerAchievements:(NSArray*)achievements
{
    @synchronized(self) {
        if (achievements_) {
            [achievements_ release], achievements_ = nil;
        }
        achievements_ = [achievements retain];
    }
}

+ (void)registerLeaderboards:(NSArray*)leaderboards
{
    @synchronized(self) {
        if (leaderboards_) {
            [leaderboards_ release], leaderboards_ = nil;
        }
        leaderboards_ = [leaderboards retain];
    }
}

+ (void)authenticateLocalPlayerWithCompletionHandler:(void(^)(NSError *error))completionHandler
{
    GKLocalPlayer *localPlayer = [GKLocalPlayer localPlayer];
    [localPlayer authenticateWithCompletionHandler:^(NSError *e) {
        if (localPlayer.isAuthenticated)
        {
            GCLOG(@"Local Player authenticated.");

            // Looking for player profile in cached
            BOOL profileFound = NO;
            NSArray *profiles = [GCCache cachedProfiles];
            for (NSDictionary *profile in profiles) {
                NSString *playerID = [profile valueForKey:@"PlayerID"];
                NSNumber *local = [profile valueForKey:@"IsLocal"];
                if (playerID && [playerID isEqualToString:[localPlayer playerID]] && ![local boolValue]) {
                    GCLOG(@"Player profile found in cache. Switching to it.");
                    [GCCache setActiveCache:[GCCache cacheForProfile:profile]];
                    profileFound = YES;
                    break;
                }
            }
            
            if (!profileFound) {
                GCCache *newCache = [[GCCache alloc] initWithDictionary:[NSDictionary dictionaryWithObjectsAndKeys:
                                                                         [localPlayer alias], @"Name",
                                                                         [localPlayer playerID], @"PlayerID",
                                                                         [NSNumber numberWithBool:NO], @"IsLocal",
                                                                         nil]];
                [GCCache setActiveCache:newCache];
                [newCache release];
                
                GCLOG(@"New profile created for Player.");
            }
        }

        completionHandler(e);
    }];
}

+ (void)launchGameCenterWithCompletionTarget:(id)target action:(SEL)action
{
    if (![GCCache isGameCenterAPIAvailable]) {
        GCLOG(@"Game Center API not available on device. Working locally.");
        [target performSelectorOnMainThread:action
                                 withObject:[NSError errorWithDomain:@"GameCenterCache"
                                                                code:0
                                                            userInfo:[NSDictionary dictionaryWithObjectsAndKeys:
                                                                      @"Game Center API not available on device. Working locally.", NSLocalizedDescriptionKey,
                                                                      nil]]
                              waitUntilDone:NO];
    } else {
        [GCCache authenticateLocalPlayerWithCompletionHandler:^(NSError *e) {
            if (e) {
                GCLOG(@"Failed to authenticate Local Player. Working locally.");
            } else {
                GCLOG(@"Game Center launched.");
            }

            [target performSelectorOnMainThread:action withObject:e waitUntilDone:NO];
        }];
    }
}

+ (void)shutdown
{
    @synchronized(self) {
        [activeCache_ release], activeCache_ = nil;
        [leaderboards_ release], leaderboards_ = nil;
        [achievements_ release], achievements_ = nil;
    }

    GCLOG(@"GCCache shut down.");
}


#pragma mark -

+ (BOOL)isGameCenterAPIAvailable
{
    // Check for presence of GKLocalPlayer class.
    BOOL localPlayerClassAvailable = (NSClassFromString(@"GKLocalPlayer")) != nil;
    
    // The device must be running iOS 4.1 or later.
    NSString *reqSysVer = @"4.1";
    NSString *currSysVer = [[UIDevice currentDevice] systemVersion];
    BOOL osVersionSupported = ([currSysVer compare:reqSysVer options:NSNumericSearch] != NSOrderedAscending);
    
    return (localPlayerClassAvailable && osVersionSupported);
}

+ (BOOL)isBetterScore:(NSNumber*)lscore thanScore:(NSNumber*)rscore inOrder:(NSString*)order
{
    if ([order isEqualToString:@"Ascending"]) {
        return [lscore compare:rscore] == NSOrderedAscending;
    } else if ([order isEqualToString:@"Descending"]) {
        return [lscore compare:rscore] == NSOrderedDescending;
    }
    
    return NO;
}

+ (NSDictionary*)leaderboardWithName:(NSString *)leaderboardName
{
    @synchronized(self) {
        if (leaderboards_) {
            for (NSDictionary *board in leaderboards_) {
                NSString *name = [board valueForKey:@"Name"];
                if ([name isEqualToString:leaderboardName]) {
                    return board;
                }
            }
        }
    }
    
    return nil;
}

+ (NSDictionary*)achievementWithName:(NSString*)achievementName
{
    @synchronized(self) {
        if (achievements_) {
            for (NSDictionary *achieve in achievements_) {
                NSString *name = [achieve valueForKey:@"Name"];
                if ([name isEqualToString:achievementName]) {
                    return achieve;
                }
            }
        }
    }
    
    return nil;
}


#pragma mark -

- (NSString*)profileName
{
    return [data valueForKey:@"Name"];
}

- (BOOL)isLocal
{
    return [[data valueForKey:@"IsLocal"] boolValue];
}


#pragma mark -

- (id)initWithDictionary:(NSDictionary*)profileDict
{
    if ((self = [super init])) {
        data = [[NSMutableDictionary alloc] initWithDictionary:profileDict];
    }
    return self;
}

- (void)dealloc
{
    [self synchronize];

    [data release];
    [super dealloc];
}


#pragma mark -

- (BOOL)isEqualToProfile:(NSDictionary*)profileDict
{
    NSString *theName = [profileDict valueForKey:@"Name"];
    BOOL theIsLocal = [[profileDict valueForKey:@"IsLocal"] boolValue];
    
    return ([theName isEqualToString:self.profileName] && theIsLocal == self.isLocal) ? YES : NO;
}

- (void)synchronize
{
    NSMutableArray *allProfiles = [NSMutableArray arrayWithArray:
                                   [[NSUserDefaults standardUserDefaults] arrayForKey:kGCProfilesProperty]];
    // Looking for this profile
    BOOL replaced = NO;
    for (int i = 0; i < allProfiles.count; ++i) {
        NSDictionary *profile = [allProfiles objectAtIndex:i];
        if ([self isEqualToProfile:profile]) {
            [allProfiles replaceObjectAtIndex:i withObject:data];
            replaced = YES;
            break;
        }
    }
    
    if (!replaced) {
        [allProfiles addObject:data];
    }
    
    [[NSUserDefaults standardUserDefaults] setObject:allProfiles forKey:kGCProfilesProperty];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    GCLOG(@"GCCache synchronized.");
}

- (void)reset
{
    NSMutableDictionary *minData = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                    [data valueForKey:@"Name"], @"Name",
                                    [data valueForKey:@"IsLocal"], @"IsLocal",
                                    nil];
    [data release];
    data = [minData retain];
    
    if (!self.isLocal) {
        [GKAchievement resetAchievementsWithCompletionHandler:^(NSError *error)
        {
            if (error != nil) {
                GCLOG(@"Failed to reset achievements in GameCenter: %@", error.localizedDescription);
                [self archiveReset];
            } else {
                GCLOG(@"Achievements reset in GameCenter.");
            }
        }];
    }

    GCLOG(@"GCCache reset.");
}

- (BOOL)submitScore:(NSNumber*)score toLeaderboard:(NSString*)board
{
    NSDictionary *leaderboard = [GCCache leaderboardWithName:board];
    if (!leaderboard) {
        GCLOG(@"Error: failed to find leaderboard with name '%@'.", board);
        return NO;
    }

    NSMutableDictionary *scoreDict = [NSMutableDictionary dictionaryWithDictionary:[data objectForKey:@"Scores"]];
    NSNumber *currScore = [scoreDict valueForKey:board];    
    if (currScore && ![GCCache isBetterScore:score
                                   thanScore:currScore
                                     inOrder:[leaderboard valueForKey:@"Order"]])
    {
        return NO;
    }

    // Rewriting current score
    [scoreDict setValue:score forKey:board];
    [data setObject:scoreDict forKey:@"Scores"];
    
    if (!self.isLocal) {
        GKScore *newScore = [[GKScore alloc] initWithCategory:[leaderboard valueForKey:@"ID"]];
        newScore.value = [score integerValue];
        [newScore reportScoreWithCompletionHandler:^(NSError *error) {
            if (!error) {
                GCLOG(@"Score %@ for '%@' leaderboard submitted to GameCenter.", score, board);
            } else {
                GCLOG(@"Failed to submit score to GameCenter: %@", error.localizedDescription);
                [self archiveScore:newScore];
            }
        }];
        
        [newScore autorelease];
    }
    
    GCLOG(@"Score %@ for '%@' leaderboard updated.", score, board);
    
    return YES;
}

- (NSNumber*)scoreForLeaderboard:(NSString*)board
{
    NSDictionary *scoreDict = [data objectForKey:@"Scores"];
    return [scoreDict valueForKey:board];
}

- (NSDictionary*)allScores
{
    return [data objectForKey:@"Scores"];
}

- (BOOL)unlockAchievement:(NSString*)achievement
{
    NSDictionary *achievementDesc = [GCCache achievementWithName:achievement];
    if (!achievementDesc) {
        GCLOG(@"Error: failed to find achievement with name '%@'.", achievement);
        return NO;
    }

    NSMutableDictionary *achievementDict = [NSMutableDictionary dictionaryWithDictionary:
                                            [data objectForKey:@"Achievements"]];
    NSNumber *currValue = [achievementDict valueForKey:achievement];
    if (currValue && [currValue boolValue]) {
        return NO;
    }
    
    [achievementDict setValue:[NSNumber numberWithBool:YES] forKey:achievement];
    [data setObject:achievementDict forKey:@"Achievements"];
    
    if (!self.isLocal) {
        GKAchievement *achievementObj = [[GKAchievement alloc] initWithIdentifier:[achievementDesc valueForKey:@"ID"]];
        achievementObj.percentComplete = 100.0;
        [achievementObj reportAchievementWithCompletionHandler:^(NSError *error)
        {
            if (!error) {
                GCLOG(@"Achievement '%@' submitted to GameCenter.", achievement);
            } else {
                GCLOG(@"Failed to submit achievement to GameCenter: %@", error.localizedDescription);
                [self archiveAchievement:achievementObj];
            }
        }];
        
        [achievementObj autorelease];
    }
    
    GCLOG(@"Achievement '%@' unlocked.", achievement);

    return YES;
}

- (BOOL)isUnlockedAchievement:(NSString*)achievement
{
    NSDictionary *achievementDict = [data objectForKey:@"Achievements"];
    NSNumber *currValue = [achievementDict valueForKey:achievement];
    if (currValue && [currValue boolValue]) {
        return YES;
    }
    
    return NO;
}

- (NSDictionary*)allAchievements
{
    return [data objectForKey:@"Achievements"];
}

- (void)archiveScore:(GKScore*)score
{
    GCLOG(@"Implement: archiving score...");
}

- (void)archiveAchievement:(GKAchievement *)achievement
{
    GCLOG(@"Implement: archiving achievement...");
}

- (void)archiveReset
{
    GCLOG(@"Implement: archiving reset...");
}

@end
