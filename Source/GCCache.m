//
//  GCCache.m
//  GameCenterCache
//
//  Created by nikan on 3/12/11.
//  Copyright 2011 Anton Nikolaienko. All rights reserved.
//

#import "GCCache.h"


#if ENABLE_LOGGING
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

@end


@implementation GCCache

static GCCache *activeCache_ = nil;
static NSArray *leaderboards_ = nil;

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

+ (BOOL)launchGameCenter
{
    GCLOG(@"Implement: Launching Game Center...");
    return NO;
}

+ (void)shutdown
{
    @synchronized(self) {
        [activeCache_ release], activeCache_ = nil;
        [leaderboards_ release], leaderboards_ = nil;
    }

    GCLOG(@"GameCenterCache shut down.");
}


#pragma mark -

+ (BOOL)isBetterScore:(NSNumber*)lscore thanScore:(NSNumber*)rscore inOrder:(NSString*)order
{
    if ([order isEqualToString:@"Ascending"]) {
        return [rscore compare:lscore] == NSOrderedAscending;
    } else if ([order isEqualToString:@"Descending"]) {
        return [rscore compare:lscore] == NSOrderedDescending;
    }
    
    return NO;
}

+ (NSDictionary*)leaderboardWithName:(NSString *)leaderboardName
{
    @synchronized(self) {
        if (leaderboards_) {
            NSUInteger idx = [leaderboards_ indexOfObjectPassingTest:^BOOL(id obj, NSUInteger idx, BOOL *stop) {
                if ([leaderboardName isEqualToString:[obj valueForKey:@"Name"]]) {
                    *stop = YES;
                    return YES;
                }
                
                return NO;
            }];
            
            if (idx != NSNotFound) {
                return [leaderboards_ objectAtIndex:idx];
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
}

- (void)submitScore:(NSNumber*)score toLeaderboard:(NSString*)board
{
    NSMutableDictionary *scoreDict = [NSMutableDictionary dictionaryWithDictionary:[data objectForKey:@"Scores"]];
    NSNumber *currScore = [scoreDict valueForKey:board];    
    if (currScore) {
        NSDictionary *leaderboard = [GCCache leaderboardWithName:board];
        if (!leaderboard || ![GCCache isBetterScore:score
                                          thanScore:currScore
                                            inOrder:[leaderboard valueForKey:@"Order"]])
        {
            return;
        }
    }

    // Rewriting current score
    [scoreDict setValue:score forKey:board];
    [data setObject:scoreDict forKey:@"Scores"];
}

- (NSNumber*)scoreForLeaderboard:(NSString*)board
{
    NSDictionary *scoreDict = [data objectForKey:@"Scores"];
    return [scoreDict valueForKey:board];
}


@end
