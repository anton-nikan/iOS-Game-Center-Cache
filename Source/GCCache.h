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
+ (void)registerAchievements:(NSDictionary*)achievements;

+ (GCCache*)activeCache;
+ (void)setActiveCache:(GCCache*)cache;
+ (void)disposeActiveCache;

+ (BOOL)launchGameCenter;

- (NSArray*)allAchievements;
- (NSArray*)allScores;

- (void)synchronize;

@property (readonly) NSString *profileName;
@property (readonly) BOOL isLocal;

@end
