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
@end


@implementation GCCache

static GCCache *activeCache_ = nil;

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

+ (void)disposeActiveCache
{
    @synchronized(self) {
        [activeCache_ release], activeCache_ = nil;
    }
}

+ (void)registerAchievements:(NSDictionary*)achievements
{
    
}

+ (BOOL)launchGameCenter
{
    return NO;
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

- (NSArray*)allAchievements
{
    return nil;
}

- (NSArray*)allScores
{
    return nil;
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


@end
