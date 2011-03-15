//
//  GCCache.h
//  GameCenterCache
//
//  Created by nikan on 3/12/11.
//  Copyright 2011 Anton Nikolaienko. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface GCCache : NSObject {
    NSMutableDictionary *data;
}

+ (NSArray*)cachedProfiles;
+ (GCCache*)cacheForProfile:(NSDictionary*)profileDict;
+ (void)registerAchievements:(NSArray*)achievements;
+ (void)registerLeaderboards:(NSArray*)leaderboards;

+ (GCCache*)activeCache;
+ (void)setActiveCache:(GCCache*)cache;

+ (BOOL)launchGameCenter;
+ (void)shutdown;

- (BOOL)submitScore:(NSNumber*)score toLeaderboard:(NSString*)board;
- (NSNumber*)scoreForLeaderboard:(NSString*)board;
- (NSDictionary*)allScores;

- (BOOL)unlockAchievement:(NSString*)achievement;
- (BOOL)isUnlockedAchievement:(NSString*)achievement;
- (NSDictionary*)allAchievements;

- (void)synchronize;
- (void)reset;

@property (readonly) NSString *profileName;
@property (readonly) BOOL isLocal;

@end
