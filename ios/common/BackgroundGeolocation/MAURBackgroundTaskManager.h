//
//  MAURBackgroundTaskManager.h
//  BackgroundGeolocation
//
//  Created by Joel and Vomako (http://stackoverflow.com/a/27664620)
//

#ifndef MAURBackgroundTaskManager_h
#define MAURBackgroundTaskManager_h


#endif /* MAURBackgroundTaskManager_h */

typedef void (^CompletionBlock)(void);


@interface MAURBackgroundTaskManager : NSObject

+ (id) sharedTasks;

- (NSUInteger)beginTask;
- (NSUInteger)beginTaskWithCompletionHandler:(CompletionBlock)_completion;
- (void)endTaskWithKey:(NSUInteger)_key;

@end
