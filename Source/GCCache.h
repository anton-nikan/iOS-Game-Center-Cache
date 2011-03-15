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

+ (void)shutdown;
+ (BOOL)launchGameCenter;

- (void)submitScore:(NSNumber*)score toLeaderboard:(NSString*)board;
- (NSNumber*)scoreForLeaderboard:(NSString*)board;

- (void)synchronize;

@property (readonly) NSString *profileName;
@property (readonly) BOOL isLocal;

@end
