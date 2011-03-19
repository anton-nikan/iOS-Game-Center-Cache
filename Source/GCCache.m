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

- (void)submitArchiveFirstItem;

@end


@implementation GCCache

static GCCache *activeCache_ = nil;
static GCCache *authenticatedCache_ = nil;
static NSArray *leaderboards_ = nil;
static NSArray *achievements_ = nil;

#pragma mark - Public static routines

+ (NSArray*)cachedProfiles
{
    return [[NSUserDefaults standardUserDefaults] arrayForKey:kGCProfilesProperty];
}

+ (GCCache*)cacheForProfile:(NSDictionary*)profileDict
{
    // Returning instances if available
    if (authenticatedCache_ && [authenticatedCache_ isEqualToProfile:profileDict]) {
        return authenticatedCache_;
    }
    
    if (activeCache_ && [activeCache_ isEqualToProfile:profileDict]) {
        return activeCache_;
    }
    
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
                [activeCache_ save];
                GCLOG(@"New Default profile created.");
            }
        }
    }
    return activeCache_;
}

+ (void)activateCache:(GCCache*)cache
{
    @synchronized(self) {
        if (activeCache_) {
            [activeCache_ save];
            [activeCache_ release], activeCache_ = nil;
        }
        activeCache_ = [cache retain];
        
        if (activeCache_) {
            GCLOG(@"Cache activated for profile: %@.", activeCache_.profileName);
            // Forcing sync for archived data
            [activeCache_ synchronize];
        }
    }
}

+ (GCCache*)authenticatedCache
{
    return authenticatedCache_;
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
            GCLOG(@"Player authenticated (%@).", [localPlayer alias]);

            // Looking for player profile in cached
            BOOL profileFound = NO;
            NSArray *profiles = [GCCache cachedProfiles];
            for (NSDictionary *profile in profiles) {
                NSString *playerID = [profile valueForKey:@"PlayerID"];
                NSNumber *local = [profile valueForKey:@"IsLocal"];
                if (playerID && [playerID isEqualToString:[localPlayer playerID]] && ![local boolValue]) {
                    GCLOG(@"Player profile found in cache (%@). Switching to it.", [localPlayer playerID]);
                    
                    GCCache *profileCache = [GCCache cacheForProfile:profile];
                    [GCCache activateCache:profileCache];
                    [authenticatedCache_ release];
                    authenticatedCache_ = [profileCache retain];
                    
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
                [GCCache activateCache:newCache];
                [authenticatedCache_ release];
                authenticatedCache_ = [newCache retain];
                [newCache release];
                
                GCLOG(@"New profile created for Player (%@).", [localPlayer playerID]);
            }
        }

        completionHandler(e);
    }];
}

+ (void)launchGameCenterWithCompletionTarget:(id)target action:(SEL)action
{
    if (![GCCache isGameCenterAPIAvailable]) {
        GCLOG(@"Game Center API not available on the device. Working locally.");
        [target performSelectorOnMainThread:action
                                 withObject:[NSError errorWithDomain:@"GameCenterCache"
                                                                code:0
                                                            userInfo:[NSDictionary dictionaryWithObjectsAndKeys:
                                                                      @"Game Center API not available on the device. Working locally.", NSLocalizedDescriptionKey,
                                                                      nil]]
                              waitUntilDone:NO];
    } else {
        [GCCache authenticateLocalPlayerWithCompletionHandler:^(NSError *e) {
            if (e) {
                GCLOG(@"Player authentication had errors. Working locally.");
            } else {
                GCLOG(@"Game Center launched.");
                [GCCache activeCache].connected = YES;
            }

            [target performSelectorOnMainThread:action withObject:e waitUntilDone:NO];
        }];
    }
}

+ (void)shutdown
{
    @synchronized(self) {
        [authenticatedCache_ release], authenticatedCache_ = nil;

        [activeCache_ save];
        [activeCache_ release], activeCache_ = nil;
        
        [leaderboards_ release], leaderboards_ = nil;
        [achievements_ release], achievements_ = nil;
    }

    GCLOG(@"GCCache shut down.");
}


#pragma mark - Internal Helper routines

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


#pragma mark - Properties

- (NSString*)profileName
{
    return [self.data valueForKey:@"Name"];
}

- (BOOL)isLocal
{
    return [[self.data valueForKey:@"IsLocal"] boolValue];
}

- (NSString*)playerID
{
    return [self.data valueForKey:@"PlayerID"];
}

- (BOOL)isDefault
{
    return (self.isLocal && [self.profileName isEqualToString:kGCDefaultProfileName]);
}

@synthesize connected;
@synthesize data;


#pragma mark - Initialization/Dealloc

- (id)initWithDictionary:(NSDictionary*)profileDict
{
    if ((self = [super init])) {
        self.data = [NSMutableDictionary dictionaryWithDictionary:profileDict];
        self.connected = NO;
    }
    return self;
}

- (void)dealloc
{
    self.data = nil;
    [super dealloc];
}


#pragma mark - Public routines

- (BOOL)isEqualToProfile:(NSDictionary*)profileDict
{
    NSString *theName = [profileDict valueForKey:@"Name"];
    BOOL theIsLocal = [[profileDict valueForKey:@"IsLocal"] boolValue];
    NSString *thePlayerID = [profileDict valueForKey:@"PlayerID"];
    
    return ([theName isEqualToString:self.profileName] &&
            theIsLocal == self.isLocal &&
            (!thePlayerID || [thePlayerID isEqualToString:self.playerID])) ? YES : NO;
}

- (BOOL)renameProfile:(NSString*)newName
{
    // Checking profile name validity
    if (!self.isLocal) return NO;
    if (newName.length == 0) return NO;

    NSRange charRange = [newName rangeOfCharacterFromSet:[NSCharacterSet lowercaseLetterCharacterSet]
                                                 options:NSCaseInsensitiveSearch];
    if (charRange.location == NSNotFound) {
        return NO;
    }
    
    NSMutableArray *allProfiles = [NSMutableArray arrayWithArray:[GCCache cachedProfiles]];
    for (NSDictionary *profile in allProfiles) {
        BOOL isLocal = [[profile valueForKey:@"IsLocal"] boolValue];
        if (isLocal) {
            NSString *name = [profile valueForKey:@"Name"];
            if ([name isEqualToString:newName]) {
                return NO;
            }
        }
    }
    
    // Rewriting profile
    for (int i = 0; i < allProfiles.count; ++i) {
        NSDictionary *profile = [allProfiles objectAtIndex:i];
        if ([self isEqualToProfile:profile]) {
            [allProfiles removeObjectAtIndex:i];
            break;
        }
    }
    
    [self.data setValue:newName forKey:@"Name"];
    [allProfiles addObject:self.data];

    [[NSUserDefaults standardUserDefaults] setObject:allProfiles forKey:kGCProfilesProperty];
    [[NSUserDefaults standardUserDefaults] synchronize];

    GCLOG(@"GCCache profile renamed to: %@.", self.profileName);
    return YES;
}

- (void)save
{
    NSMutableArray *allProfiles = [NSMutableArray arrayWithArray:
                                   [[NSUserDefaults standardUserDefaults] arrayForKey:kGCProfilesProperty]];
    // Looking for this profile
    BOOL replaced = NO;
    for (int i = 0; i < allProfiles.count; ++i) {
        NSDictionary *profile = [allProfiles objectAtIndex:i];
        if ([self isEqualToProfile:profile]) {
            [allProfiles replaceObjectAtIndex:i withObject:self.data];
            replaced = YES;
            break;
        }
    }
    
    if (!replaced) {
        [allProfiles addObject:self.data];
    }
    
    [[NSUserDefaults standardUserDefaults] setObject:allProfiles forKey:kGCProfilesProperty];
    [[NSUserDefaults standardUserDefaults] synchronize];

    GCLOG(@"GCCache saved for profile: %@.", self.profileName);
}

- (void)synchronize
{
    // Sending out archived data
    if (!self.isLocal) {
        NSArray *archive = [self.data objectForKey:@"Archive"];
        if (archive && archive.count > 0) {
            GCLOG(@"Sending archieved data to Game Center (%d)...", archive.count);
            [self submitArchiveFirstItem];
        }
    }
}

- (void)reset
{
    self.data = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                 [self.data valueForKey:@"Name"], @"Name",
                 [self.data valueForKey:@"IsLocal"], @"IsLocal",
                 [self.data valueForKey:@"PlayerID"], @"PlayerID",  // can be nil
                 nil];
    
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

#pragma mark - Public routines: Scores

- (BOOL)submitScore:(NSNumber*)score toLeaderboard:(NSString*)board
{
    NSDictionary *leaderboard = [GCCache leaderboardWithName:board];
    if (!leaderboard) {
        GCLOG(@"Error: failed to find leaderboard with name '%@'.", board);
        return NO;
    }

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

    NSMutableDictionary *scoreDict = [NSMutableDictionary dictionaryWithDictionary:[self.data objectForKey:@"Scores"]];
    NSNumber *currScore = [scoreDict valueForKey:board];    
    if (currScore && ![GCCache isBetterScore:score
                                   thanScore:currScore
                                     inOrder:[leaderboard valueForKey:@"Order"]])
    {
        return NO;
    }

    // Rewriting current score
    [scoreDict setValue:score forKey:board];
    [self.data setObject:scoreDict forKey:@"Scores"];
    
    GCLOG(@"Score %@ for '%@' leaderboard updated.", score, board);
    
    return YES;
}

- (NSNumber*)scoreForLeaderboard:(NSString*)board
{
    NSDictionary *scoreDict = [self.data objectForKey:@"Scores"];
    return [scoreDict valueForKey:board];
}

- (NSDictionary*)allScores
{
    return [self.data objectForKey:@"Scores"];
}


#pragma mark - Public routines: Achievements

- (BOOL)unlockAchievement:(NSString*)achievement
{
    NSDictionary *achievementDesc = [GCCache achievementWithName:achievement];
    if (!achievementDesc) {
        GCLOG(@"Error: failed to find achievement with name '%@'.", achievement);
        return NO;
    }

    NSMutableDictionary *achievementDict = [NSMutableDictionary dictionaryWithDictionary:
                                            [self.data objectForKey:@"Achievements"]];
    NSNumber *currValue = [achievementDict valueForKey:achievement];
    if (currValue && [currValue doubleValue] > 0.0) {
        return NO;
    }
    
    [achievementDict setValue:[NSNumber numberWithDouble:100.0] forKey:achievement];
    [self.data setObject:achievementDict forKey:@"Achievements"];
    
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
    NSDictionary *achievementDict = [self.data objectForKey:@"Achievements"];
    NSNumber *currValue = [achievementDict valueForKey:achievement];
    if (currValue && [currValue doubleValue] >= 100.0) {
        return YES;
    }
    
    return NO;
}

- (BOOL)submitProgress:(double)progress toAchievement:(NSString*)achievement
{
    NSDictionary *achievementDesc = [GCCache achievementWithName:achievement];
    if (!achievementDesc) {
        GCLOG(@"Error: failed to find achievement with name '%@'.", achievement);
        return NO;
    }
    
    NSMutableDictionary *achievementDict = [NSMutableDictionary dictionaryWithDictionary:
                                            [self.data objectForKey:@"Achievements"]];
    NSNumber *currValue = [achievementDict valueForKey:achievement];
    if (currValue && [currValue doubleValue] >= 100.0) {
        return NO;
    }

    if (progress > 100.0) {
        progress = 100.0;
    } else if (progress < 0.0) {
        progress = 0.0;
    }
    
    [achievementDict setValue:[NSNumber numberWithDouble:progress] forKey:achievement];
    [self.data setObject:achievementDict forKey:@"Achievements"];
    
    if (!self.isLocal) {
        GKAchievement *achievementObj = [[GKAchievement alloc] initWithIdentifier:[achievementDesc valueForKey:@"ID"]];
        achievementObj.percentComplete = progress;
        [achievementObj reportAchievementWithCompletionHandler:^(NSError *error)
         {
             if (!error) {
                 GCLOG(@"Progress %f of achievement '%@' submitted to GameCenter.", progress, achievement);
             } else {
                 GCLOG(@"Failed to submit achievement progress to GameCenter: %@", error.localizedDescription);
                 [self archiveAchievement:achievementObj];
             }
         }];
        
        [achievementObj autorelease];
    }
    
    if (progress == 100.0) {
        GCLOG(@"Achievement '%@' unlocked.", achievement);
    } else {
        GCLOG(@"Achievement '%@' updated to progress %f.", achievement, progress);
    }
    
    return YES;
}

- (double)progressOfAchievement:(NSString*)achievement
{
    NSDictionary *achievementDict = [self.data objectForKey:@"Achievements"];
    NSNumber *currValue = [achievementDict valueForKey:achievement];
    if (currValue) {
        return [currValue doubleValue];
    }
    
    return 0.0;
}

- (NSDictionary*)allAchievements
{
    return [self.data objectForKey:@"Achievements"];
}


#pragma mark - Archiving

- (void)archiveScore:(GKScore*)score
{
    NSMutableData *dataStore = [NSMutableData data];
    NSKeyedArchiver *archiver = [[NSKeyedArchiver alloc] initForWritingWithMutableData:dataStore];
    [archiver encodeObject:score forKey:@"Score"];
    [archiver finishEncoding];
    
    NSMutableArray *archive = [NSMutableArray arrayWithArray:[self.data objectForKey:@"Archive"]];
    [archive addObject:dataStore];
    [self.data setObject:archive forKey:@"Archive"];
    
    [archiver release];

    GCLOG(@"Score archieved.");
}

- (void)archiveAchievement:(GKAchievement *)achievement
{
    NSMutableData *dataStore = [NSMutableData data];
    NSKeyedArchiver *archiver = [[NSKeyedArchiver alloc] initForWritingWithMutableData:dataStore];
    [archiver encodeObject:achievement forKey:@"Achievement"];
    [archiver finishEncoding];
    
    NSMutableArray *archive = [NSMutableArray arrayWithArray:[self.data objectForKey:@"Archive"]];
    [archive addObject:dataStore];
    [self.data setObject:archive forKey:@"Archive"];
    
    [archiver release];

    GCLOG(@"Achievement archieved.");
}

- (void)archiveReset
{
    NSMutableArray *archive = [NSMutableArray arrayWithArray:[self.data objectForKey:@"Archive"]];
    [archive addObject:@"Reset"];
    [self.data setObject:archive forKey:@"Archive"];
    
    GCLOG(@"Reset archieved.");
}

- (void)respondToSubmittedItem:(id)item
{
    BOOL continueSubmit = NO;
    NSMutableArray *archiveList = [NSMutableArray arrayWithArray:[self.data objectForKey:@"Archive"]];
    if ([[archiveList objectAtIndex:0] isEqual:item]) {
        [archiveList removeObjectAtIndex:0];
        [self.data setObject:archiveList forKey:@"Archive"];
    }
    
    if (archiveList.count > 0) {
        continueSubmit = YES;
        GCLOG(@"Continuing archive submittion (%d)...", archiveList.count);
    }
    
    if (continueSubmit) {
        [self submitArchiveFirstItem];
    }
}

- (void)submitAchivedItem:(id)item withCompletionHandler:(void(^)(NSError *e))handler
{
    if ([item isKindOfClass:[NSData class]]) {
        NSKeyedUnarchiver *unarchiver = [[NSKeyedUnarchiver alloc] initForReadingWithData:item];
        if ([unarchiver containsValueForKey:@"Score"]) {
            GKScore *newScore = (GKScore*)[unarchiver decodeObjectForKey:@"Score"];
            [newScore reportScoreWithCompletionHandler:^(NSError *error) {
                if (!error) {
                    GCLOG(@"Archived score %qi for leaderboard '%@' synchronized.",
                          newScore.value, newScore.category);
                }
                
                handler(error);
            }];
        } else if ([unarchiver containsValueForKey:@"Achievement"]) {
            GKAchievement *achievementObj = (GKAchievement*)[unarchiver decodeObjectForKey:@"Achievement"];
            [achievementObj reportAchievementWithCompletionHandler:^(NSError *error)
             {
                 if (!error) {
                     GCLOG(@"Archived achievement '%@' with progress %f synchronized.",
                           achievementObj.identifier, achievementObj.percentComplete);
                 }
                 
                 handler(error);
             }];
        }
        [unarchiver release];
    } else if ([item isKindOfClass:[NSString class]]) {
        if ([item isEqualToString:@"Reset"]) {
            [GKAchievement resetAchievementsWithCompletionHandler:^(NSError *error)
             {
                 if (!error) {
                     GCLOG(@"Archived Reset synchronized.");
                 }

                 handler(error);
             }];
        }
    }
}

- (void)submitArchiveFirstItem
{
    id item = nil;
    NSMutableArray *archiveList = [NSMutableArray arrayWithArray:[self.data objectForKey:@"Archive"]];
    if (archiveList && archiveList.count) {
        item = [[[archiveList objectAtIndex:0] copy] autorelease];
    }

    if (item) {
        [self submitAchivedItem:item withCompletionHandler:^(NSError *error) {
            if (!error) {
                [self performSelectorOnMainThread:@selector(respondToSubmittedItem:) withObject:item waitUntilDone:NO];
            } else {
                GCLOG(@"Failed to submit archived data to GameCenter: %@", error.localizedDescription);
            }
        }];
    }
}

@end
