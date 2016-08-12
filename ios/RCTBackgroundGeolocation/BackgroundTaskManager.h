//
//  BackgroundTaskManager.m
//  CDVBackgroundGeolocation
//
//  Created by Joel and Vomako (http://stackoverflow.com/a/27664620)
//

#ifndef BackgroundTaskManager_h
#define BackgroundTaskManager_h


#endif /* BackgroundTaskManager_h */

typedef void (^CompletionBlock)(void);


@interface BackgroundTaskManager : NSObject

+ (id) sharedTasks;

- (NSUInteger)beginTask;
- (NSUInteger)beginTaskWithCompletionHandler:(CompletionBlock)_completion;
- (void)endTaskWithKey:(NSUInteger)_key;

@end